defmodule Embers.Favorites do
  @moduledoc """
  Los favoritos son los contenidos que el usuario guardó para ver más tarde.

  Están implementados como una tabla pivote que relaciona a un post
  con un usuario.
  Para agregar o quitar un posts de los favoritos de un usuario, se debe
  crear o eliminar una entrada en la db con las funciones `create/2` y
  `delete/2`.

  Dado que los favoritos no son posts sino las entidades que representan la
  relación, al levantarlos de la db no traerán consigo al post en cuestión.
  Debe tenerse en cuenta esto ya que los métodos `create/1` y `delete/2`
  devuelven la entrada del favorito, no del post. Si se desea obetner el post,
  debe levantarse utilizando el campo `post_id` del favorito.
  """
  alias Embers.Favorites.Favorite
  alias Embers.Paginator
  alias Embers.Repo

  import Ecto.Query

  def create(user_id, post_id) do
    favorite = Favorite.changeset(%Favorite{}, %{user_id: user_id, post_id: post_id})

    Repo.insert(favorite)
  end

  def delete(user_id, post_id) do
    fav = Repo.get_by(Favorite, %{user_id: user_id, post_id: post_id})

    unless is_nil(fav) do
      Repo.delete(fav)
    end
  end

  def list_paginated(user_id, opts \\ []) do
    query =
      from(fav in Favorite,
        as: :favorite,
        where: fav.user_id == ^user_id
      )

    query
    |> with_post()
    |> Paginator.paginate(opts)
    |> set_faved_status()
    |> fill_nsfw()
  end

  defp with_post(query) do
    from([favorite: fav] in query,
      left_join: post in assoc(fav, :post),
      as: :post,
      order_by: [desc: fav.inserted_at, desc: post.inserted_at],
      preload: [
        post: [
          :media,
          :links,
          :tags,
          :reactions,
          user: [:meta],
          related_to: [:media, :tags, :links, :reactions, user: :meta]
        ]
      ]
    )
  end

  defp set_faved_status(%Embers.Paginator.Page{entries: favs} = page) do
    %{
      page
      | entries: Enum.map(favs, fn fav -> %{fav | post: %{fav.post | faved: true}} end)
    }
  end

  def fill_nsfw(page) do
    Map.update!(page, :entries, fn favs ->
      Enum.map(favs, fn fav ->
        %{fav | post: Embers.Posts.Post.fill_nsfw(fav.post)}
      end)
    end)
  end
end
