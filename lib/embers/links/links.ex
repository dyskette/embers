defmodule Embers.Links do
  @moduledoc """
  `Link`s are user uploaded urls. They contain the URL and metadata about the
  link to be used for clients to show it, such as title or thumbnail.

  The main difference between a `Link` and an `Embers.Media` is that `Link`s do
  not point to any file hosted by Embers, they only store metadata.

  In short: `Link`s store metadata only while `Embers.Media` can store actual
  files.
  """

  alias Embers.Posts.Post
  alias Embers.Links.{EmbedSchema, Link, LinkPost}
  alias Embers.Repo

  @providers [
    Embers.Links.GfycatProvider,
    Embers.Links.SoundcloudProvider,
    Embers.Links.SteamProvider,
    Embers.Links.TwitterProvider,
    Embers.Links.YouTubeProvider,
    Embers.Links.FacebookProvider,
    Embers.Links.TwitchProvider,
    Embers.Links.VimeoProvider,
    Embers.Links.DailymotionProvider
  ]

  def get_by(%{id: id}) do
    Repo.get(Link, id)
  end

  def get_by(%{url: url}) do
    Repo.get_by!(Link, url: url)
  end

  def save(attrs) do
    %Link{}
    |> Link.changeset(attrs)
    |> Repo.insert()
  end

  def attach_to(%Link{id: link}, %Post{id: post}) do
    attach_to(link, post)
  end

  def attach_to(%Link{id: link}, post) when is_integer(post) do
    attach_to(link, post)
  end

  def attach_to(link, post) when is_integer(link) and is_integer(post) do
    %LinkPost{}
    |> LinkPost.changeset(%{link_id: link, post_id: post})
    |> Repo.insert()
  end

  @spec fetch(binary()) :: {:error, :cant_process_url} | {:ok, Embers.Links.EmbedSchema.t()}
  def fetch(url) do
    content_type = get_content_type(url)

    if !is_nil(content_type) && Regex.match?(~r/image\/(\w+)/, content_type) do
      {:ok, handle_image(url)}
    else
      {:ok, handle_url(url)}
    end
  end

  defp handle_url(url) do
    case Enum.find(@providers, fn provider -> provider.provides?(url) end) do
      nil -> handle_og(url)
      provider -> provider.get(url)
    end
  end

  defp handle_og(url) do
    case OpenGraph.fetch(url) do
      {:error, _} ->
        nil

      {:ok, og} ->
        og_to_schema(og, url)
    end
  end

  defp handle_image(url) do
    %EmbedSchema{
      url: url,
      type: "image",
      title: url,
      thumbnail_url: url
    }
  end

  defp get_content_type(url) do
    case HTTPoison.head(url) do
      {:ok, %{headers: headers}} ->
        with {_, content_type} <- List.keyfind(headers, "Content-Type", 0) do
          content_type
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp og_to_schema(og, url) do
    schema = %EmbedSchema{
      url: og.url || url,
      type: og.type || "link",
      title: og.title,
      description: og.description,
      thumbnail_url: og.image
    }

    case og do
      %{type: "video." <> _} ->
        %{schema | type: "video", url: og.video}

      _ ->
        schema
    end
  end
end
