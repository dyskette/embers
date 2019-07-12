defmodule Embers.Posts do
  @max_media_count 4

  import Ecto.Query

  alias Ecto.Multi

  alias Embers.Helpers.IdHasher
  alias Embers.Links.Link
  alias Embers.Media.MediaItem
  alias Embers.Paginator
  alias Embers.Posts.Post
  alias Embers.Repo
  alias Embers.Tags

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Repo.all(Post)
  end

  @doc """
  Gets a single post with preloaded associations.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post(nil), do: {:error, :not_found}

  def get_post(id) do
    query =
      from(
        post in Post,
        where: post.id == ^id and is_nil(post.deleted_at),
        left_join: user in assoc(post, :user),
        left_join: meta in assoc(user, :meta),
        left_join: related in assoc(post, :related_to),
        left_join: related_user in assoc(related, :user),
        left_join: related_user_meta in assoc(related_user, :meta),
        preload: [:media, :links, :tags, :reactions, related_to: [:media, :tags, :reactions]],
        # Acá precargamos todo lo que levantamos más arriba con los joins,
        # de lo contrario Ecto no mapeará los resultados a los esquemas
        # correspondientes.
        preload: [
          user: {user, meta: meta},
          related_to: {
            related,
            user: {
              related_user,
              meta: related_user_meta
            }
          }
        ]
      )

    res = Repo.one(query)

    case res do
      nil -> {:error, :not_found}
      post -> {:ok, post |> Post.fill_nsfw()}
    end
  end

  def get_post!(nil), do: nil

  def get_post!(id) do
    case get_post(id) do
      {:error, _reason} -> nil
      {:ok, post} -> post
    end
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs) do
    post_changeset = Post.changeset(%Post{}, attrs)

    # Inicializar la transaccion
    Multi.new()
    # Intentamos insertar el post
    |> Multi.insert(:post, post_changeset)
    # Si hay medios, asociarlos al post y quitarles el flag de temporal
    |> Multi.run(:medias, fn _repo, %{post: post} -> handle_medias(post, attrs) end)
    # Si hay links, asociarlos al post y quitarles el flag de temporal
    |> Multi.run(:links, fn _repo, %{post: post} -> handle_links(post, attrs) end)
    # Buscar tags en los atributos y en el cuerpo el post
    |> Multi.run(:tags, fn _repo, %{post: post} -> handle_tags(post, attrs) end)
    # Actualizar el contador de respuestas del post padre
    |> Multi.run(:post_replies, fn _repo, %{post: post} ->
      update_parent_post_replies(post, attrs)
    end)
    # Si el post es compartido, realizar las acciones correspondientes
    # (Como actualizar el contador de compartidos)
    |> Multi.run(:related_to, fn _repo, %{post: post} -> handle_related_to(post, attrs) end)
    # Ejecutar la transaccion
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post} = _results} ->
        # El post se creo exitosamente, asi que levantamos todas las
        # asociaciones que hacen falta para poder mostrarlo en el front
        post =
          post
          |> Repo.preload([
            [user: :meta],
            :media,
            :links,
            :tags,
            :reactions,
            [related_to: [:media, :links, :tags, :reactions, user: :meta]]
          ])
          |> Post.fill_nsfw()

        # Disparamos un evento
        Embers.Event.emit(:post_created, post)

        {:ok, post}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp update_parent_post_replies(post, _attrs) do
    if post.nesting_level > 0 do
      {_, [parent]} =
        Repo.update_all(
          from(
            p in Post,
            where: p.id == ^post.parent_id,
            update: [inc: [replies_count: 1]]
          ),
          [],
          returning: true
        )

      Embers.Event.emit(:post_comment, %{
        from: post.user_id,
        recipient: parent.user_id,
        source: parent.id
      })
    end

    {:ok, nil}
  end

  defp handle_related_to(post, _attrs) do
    if not is_nil(post.related_to_id) do
      {_, [parent]} =
        Repo.update_all(
          from(
            p in Post,
            where: p.id == ^post.related_to_id,
            where: is_nil(p.deleted_at),
            update: [inc: [shares_count: 1]]
          ),
          [],
          returning: true
        )

      Embers.Event.emit(:post_shared, %{
        from: post.user_id,
        recipient: parent.user_id,
        source: post.id
      })
    end

    {:ok, nil}
  end

  defp handle_medias(post, attrs) do
    medias = attrs["medias"]

    if is_nil(medias) do
      {:ok, nil}
    else
      if length(medias) <= @max_media_count do
        medias = attrs["medias"]

        ids = Enum.map(medias, fn x -> IdHasher.decode(x["id"]) end)

        {_count, medias} =
          Repo.update_all(
            from(m in MediaItem, where: m.id in ^ids),
            [set: [temporary: false]],
            returning: true
          )

        post
        |> Repo.preload(:media)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:media, medias)
        |> Repo.update()
      else
        {:error, "media count exceeded"}
      end
    end
  end

  defp handle_links(post, attrs) do
    links = attrs["links"]

    if is_nil(links) do
      {:ok, nil}
    else
      ids = Enum.map(links, fn x -> IdHasher.decode(x["id"]) end)

      {_count, links} =
        Repo.update_all(
          from(l in Link, where: l.id in ^ids),
          [set: [temporary: false]],
          returning: true
        )

      post
      |> Repo.preload(:links)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:links, links)
      |> Repo.update()
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post, actor \\ nil) do
    if post.nesting_level > 0 do
      # Update parent post replies count
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.parent_id,
          update: [inc: [replies_count: -1]]
        ),
        []
      )
    end

    unless is_nil(post.related_to_id) do
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.related_to_id,
          update: [inc: [shares_count: -1]]
        ),
        []
      )
    end

    with {:ok, post} <- Repo.soft_delete(post) do
      Embers.Event.emit(:post_disabled, %{post: post, actor: actor})
      {:ok, post}
    else
      error -> error
    end
  end

  def restore_post(%Post{} = post, actor \\ nil) do
    if post.nesting_level > 0 do
      # Update parent post replies count
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.parent_id,
          update: [inc: [replies_count: 1]]
        ),
        []
      )
    end

    unless is_nil(post.related_to_id) do
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.parent_id,
          update: [inc: [shares_count: 1]]
        ),
        []
      )
    end

    with {:ok, post} <- Repo.restore_entry(post) do
      Embers.Event.emit(:post_restored, %{post: post, actor: actor})
      {:ok, post}
    else
      error -> error
    end
  end

  @doc """
  Hard deletes a Post.

  ## Examples

      iex> hard_delete_post(post)
      {:ok, %Post{}}

      iex> hard_delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def hard_delete_post(%Post{} = post, actor \\ nil) do
    if post.nesting_level > 0 do
      # Update parent post replies count
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.parent_id,
          update: [inc: [replies_count: -1]]
        ),
        []
      )
    end

    unless is_nil(post.related_to_id) do
      Repo.update_all(
        from(
          p in Post,
          where: p.id == ^post.parent_id,
          update: [inc: [shares_count: -1]]
        ),
        []
      )
    end

    with {:ok, deleted_post} <- Repo.delete(post) do
      Embers.Event.emit(:post_deleted, %{post: deleted_post, actor: actor})
      {:ok, deleted_post}
    else
      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{source: %Post{}}

  """
  def change_post(%Post{} = post) do
    Post.changeset(post, %{})
  end

  @doc """
  Devuelve las respuestas a un post.
  """
  def get_post_replies(parent_id, opts \\ []) do
    order = Keyword.get(opts, :order, :asc)

    query =
      from(
        post in Post,
        where: post.parent_id == ^parent_id and is_nil(post.deleted_at),
        left_join: user in assoc(post, :user),
        left_join: meta in assoc(user, :meta),
        preload: [user: {user, meta: meta}],
        preload: [:reactions, :media, :links, :tags]
      )

    query =
      case order do
        :desc -> from(post in query, order_by: [desc: post.inserted_at])
        :asc -> from(post in query, order_by: [asc: post.inserted_at])
      end

    query
    |> Paginator.paginate(opts)
    |> fill_nsfw()
  end

  defp fill_nsfw(page) do
    %{
      page
      | entries: Enum.map(page.entries, fn post -> Post.fill_nsfw(post) end)
    }
  end

  defp handle_tags(post, attrs) do
    hashtag_regex = ~r/(?<!\w)#\w+/

    # Buscar tags en el cuerpo del post
    hashtags =
      if is_nil(post.body) do
        []
      else
        hashtag_regex
        |> Regex.scan(post.body)
        |> Enum.map(fn [txt] -> String.replace(txt, "#", "") end)
      end

    # Sumarle los tags enviados en el campo "tags"
    hashtags =
      if Map.has_key?(attrs, "tags") and is_list(attrs["tags"]) do
        Enum.concat(hashtags, attrs["tags"])
      else
        hashtags
      end

    # Crear los tags que hacaen falta y obtener los ids que hacen falta
    tags_ids = Tags.bulk_create_tags(hashtags)

    # Generar una lista de los datos a insertar en la tabla "tag_post"
    tag_post_list =
      Enum.map(tags_ids, fn tag_id ->
        %{
          post_id: post.id,
          tag_id: tag_id,
          inserted_at: current_date_naive(),
          updated_at: current_date_naive()
        }
      end)

    Embers.Repo.insert_all(Embers.Tags.TagPost, tag_post_list)

    # Devolver un tuple con {:ok, _algo} porque esta accion se realiza
    # dentro de una transaccion.
    # Se podria hacer que falle toda la operacion si no se pudo insertar
    # un tag.
    {:ok, nil}
  end

  defp current_date_naive do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end