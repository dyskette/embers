defmodule Embers.Paginator do
  @moduledoc """
  Paginates a query result using cursor based pagination.
  See [this article](https://coderwall.com/p/lkcaag/pagination-you-re-probably-doing-it-wrong)
  for an explanation of the method used here.
  """

  import Ecto.Query, warn: false

  alias Embers.Helpers.IdHasher
  alias Embers.Paginator.Options
  alias Embers.Paginator.Page
  alias Embers.Repo

  @doc """
  Fetches all the results matching the query between the cursors

  It relies on the `id` column for the cursor

  ## Options

  * `after` - Fetch the records after this id
  * `before` - Fetch the records before this id
  * `limit` - Limits the number of records returned per page. Note that this number
    will be capped by `:max_limit`. Defaults to 50
  * `max_limit` - Sets a maximum cap for `:limit`. This option can be useful when `:limit`
    is set dynamically (e.g from a URL param set by a user) but you still want to
    enforce a maximum. Defaults to `500`.

  ## Usage

      iex> paginate(query, opts)
      %Page{entries: [], last_page: false, next: "next cursor"}

  """
  @spec paginate(Ecto.Query.t(), list()) :: Embers.Paginator.Page.t()
  def paginate(queryable, opts \\ []) do
    opts = Options.build(opts)

    limit_plus_one = opts.limit + 1

    query =
      queryable
      |> limit(^limit_plus_one)

    query =
      unless is_nil(opts.before) do
        from(q in query,
          where: q.id <= ^opts.before
        )
      end || query

    query =
      unless is_nil(opts.after) do
        from(q in query,
          where: q.id >= ^opts.after
        )
      end || query

    all_entries = Repo.all(query)
    entries_count = Enum.count(all_entries)
    last_entry = List.last(all_entries)
    last_page = entries_count <= opts.limit

    entries =
      if last_page do
        all_entries
      else
        Enum.drop(all_entries, -1)
      end

    next =
      if last_page or is_nil(last_entry) do
        nil
      else
        IdHasher.encode(last_entry.id)
      end

    %Page{entries: entries, next: next, last_page: last_page}
  end
end
