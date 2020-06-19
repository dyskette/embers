defmodule EmbersWeb.Api.LinkView do
  @moduledoc false

  use EmbersWeb, :view

  alias Embers.Helpers.IdHasher

  def render("show.json", assigns) do
    render("link.json", assigns)
  end

  def render("link.json", %{link: link}) do
    embed =
      link.embed
      |> clean_embed()

    %{
      "id" => IdHasher.encode(link.id),
      "url" => link.url,
      "embed" => embed
    }
  end

  defp clean_embed(embed) do
    embed
    |> Map.from_struct()
    |> Map.drop([:__meta__, :id])
  end
end