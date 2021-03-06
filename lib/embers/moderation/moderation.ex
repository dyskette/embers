defmodule Embers.Moderation do
  # TODO document
  alias Embers.Accounts.User
  alias Embers.Moderation.Ban
  alias Embers.Sessions

  alias Embers.Paginator
  alias Embers.Repo
  import Ecto.Query, only: [from: 2]

  def banned?(nil), do: false

  def banned?(%User{} = user) do
    banned?(user.id)
  end

  def banned?(user_id) when is_binary(user_id) do
    not is_nil(get_active_ban(user_id))
  end

  def ban_expired?(%{expires_at: nil}), do: false

  def ban_expired?(ban) do
    Timex.compare(ban.expires_at, Timex.now(), :days) <= 0
  end

  def get_active_ban(user_id) when is_binary(user_id) do
    Repo.one(bans_query(user_id))
  end

  def get_active_ban(%User{} = user) do
    get_active_ban(user.id)
  end

  @doc """
  Returns a page with active bans, ordered by date.
  See `Embers.Paginator.paginate/2` for options.
  """
  @spec list_all_bans(options :: keyword()) :: Paginator.Page.t(Ban.t())
  def list_all_bans(opts \\ []) do
    from(ban in Ban,
      order_by: [desc: ban.id],
      where: is_nil(ban.deleted_at),
      preload: [user: [:meta]]
    )
    |> Paginator.paginate(opts)
    |> Paginator.map(fn ban ->
      update_in(ban.user.meta, &Embers.Profile.Meta.load_avatar_map/1)
    end)
  end

  @doc """
  Lists bans for the given user.
  See `Embers.Paginator.paginate/2` for options.
  """
  @spec list_bans_for(user :: String.t() | User.t(), options :: keyword()) ::
          Paginator.Page.t(Ban.t())
  def list_bans_for(user, opts \\ [])

  def list_bans_for(user_id, opts) when is_binary(user_id) do
    user_id
    |> bans_query(opts)
    |> Repo.all()
  end

  def list_bans(%User{} = user, opts) do
    list_bans(user.id, opts)
  end

  def ban_user(user, opts \\ [])

  def ban_user(user_id, opts) when is_binary(user_id) do
    if is_nil(get_active_ban(user_id)) do
      duration = Keyword.get(opts, :duration, 7)

      duration =
        cond do
          is_integer(duration) ->
            duration

          is_binary(duration) ->
            {duration, _} = Integer.parse(duration)
            duration

          true ->
            nil
        end

      indefinite? = duration <= 0

      expires =
        unless indefinite? do
          Timex.shift(DateTime.utc_now(), days: duration)
        end

      case Repo.insert(
             Ban.changeset(%Ban{}, %{
               user_id: user_id,
               reason: Keyword.get(opts, :reason),
               expires_at: expires
             })
           ) do
        {:ok, ban} ->
          Sessions.delete_user_sessions(user_id)
          actor = Keyword.get(opts, :actor, nil)
          Embers.Event.emit(:user_banned, %{ban: ban, actor: actor})
          {:ok, ban}

        error ->
          error
      end
    else
      {:error, :already_banned}
    end
  end

  def ban_user(%User{} = user, opts) do
    ban_user(user.id, opts)
  end

  def unban_user(user_id) when is_binary(user_id) do
    case get_active_ban(user_id) do
      nil -> {:ok, nil}
      ban -> soft_delete(ban)
    end
  end

  def unban_user(%User{} = user) do
    unban_user(user.id)
  end

  defp soft_delete(%Ban{} = ban) do
    current_datetime = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.update(Ecto.Changeset.change(ban, %{deleted_at: current_datetime}))
  end

  defp bans_query(user_id, opts \\ []) do
    query =
      from(ban in Ban,
        where: ban.user_id == ^user_id
      )

    load_deleted? = Keyword.get(opts, :deleted, false)

    query =
      if not load_deleted? do
        from(ban in query, where: is_nil(ban.deleted_at))
      end || query

    query
  end
end
