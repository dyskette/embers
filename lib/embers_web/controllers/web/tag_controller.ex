defmodule EmbersWeb.Web.TagController do
  @moduledoc false

  use EmbersWeb, :controller

  alias Embers.Tags
  alias Embers.Helpers.IdHasher

  def show(conn, %{"name" => name} = params) do
    tag = case Tags.get_by_name(name) do
      nil -> %Tags.Tag{name: name, description: nil}
      tag -> tag
    end

    page = if is_nil(tag.id) do
      Embers.Paginator.Page.empty()
    else
      Tags.list_tag_posts(tag.name,
        before: IdHasher.decode(params["before"]), limit: params["limit"]
      )
    end

    if params["entries"] == "true" do
      conn
      |> put_layout(false)
      |> Embers.Paginator.put_page_headers(page)
      |> render("entries.html", page: page)
    else
      conn
      |> render("show.html", tag: tag, page: page)
    end
  end

  def list_popular(conn, _params) do
    popular = Tags.get_popular_tags(limit: 5)

    conn
    |> render("popular.json", popular: popular)
  end

  def list_hot(conn, _params) do
    hot = Tags.get_hot_tags(limit: 5)

    conn
    |> render("hot.json", hot: hot)
  end
end