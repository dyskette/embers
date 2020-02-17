defmodule EmbersWeb.TagView do
  @moduledoc false

  use EmbersWeb, :view

  alias Embers.Helpers.IdHasher

  def render("tags.json", %{tags: tags}) do
    render_many(tags, __MODULE__, "tag.json")
  end

  def render("tags_paginated.json", %{entries: tags} = metadata) do
    %{
      items: render_many(tags, __MODULE__, "tag.json"),
      next: metadata.next,
      last_page: metadata.last_page
    }
  end

  def render("tags_ids.json", %{entries: ids} = metadata) do
    %{
      ids: render_many(ids, __MODULE__, "tag_id"),
      next: metadata.next,
      last_page: metadata.last_page
    }
  end

  def render("tag_id", %{tag: id}) do
    IdHasher.encode(id)
  end

  def render("tag.json", %{tag: %{tag: tag, level: level}}) do
    %{
      id: IdHasher.encode(tag.id),
      name: tag.name,
      description: tag.description,
      sub_level: level
    }
  end

  def render("tag.json", %{tag: tag}) do
    %{
      id: IdHasher.encode(tag.id),
      name: tag.name,
      description: tag.description,
      sub_level: nil
    }
  end

  def render("popular.json", %{popular: tags}) do
    render_many(tags, __MODULE__, "tag_with_count.json")
  end

  def render("hot.json", %{hot: tags}) do
    render_many(tags, __MODULE__, "tag_with_count.json")
  end

  def render("tag_with_count.json", %{tag: tag}) do
    %{
      count: tag.count,
      tag: render_one(tag.tag, __MODULE__, "tag.json")
    }
  end
end
