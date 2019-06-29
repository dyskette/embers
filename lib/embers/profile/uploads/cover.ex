defmodule Embers.Profile.Uploads.Cover do
  @moduledoc false
  alias Embers.Helpers.IdHasher
  alias Embers.Uploads

  @path Keyword.get(Application.get_env(:embers, Embers.Profile), :cover_path, "/user/cover")

  def upload(cover, %Embers.Accounts.User{} = user) do
    upload(cover, user.id)
  end

  def upload(cover, user_id) when is_integer(user_id) do
    if valid?(cover) do
      processed = process(cover)

      id = IdHasher.encode(user_id)

      with {:ok, _} <-
             Uploads.upload(processed.path, get_bucket(), "#{@path}/#{id}.jpg",
               content_type: "image/png"
             ) do
        :ok
      else
        error -> error
      end
    else
      {:error, :invalid_format}
    end
  end

  def delete(%Embers.Accounts.User{} = user) do
    delete(user.id)
  end

  def delete(user_id) when is_integer(user_id) do
    id = IdHasher.encode(user_id)

    with :ok <- Uploads.delete(get_bucket(), "#{@path}/#{id}.jpg") do
      :ok
    else
      error -> error
    end
  end

  defp valid?(file) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.filename))
  end

  defp process(image) do
    image.path
    |> Mogrify.open()
    |> Mogrify.custom("strip")
    |> Mogrify.resize("960x320")
    |> Mogrify.custom("background", "#1a1b1d")
    |> Mogrify.gravity("center")
    |> Mogrify.extent("960x320")
    |> Mogrify.format("png")
    |> Mogrify.save()
  end

  defp get_bucket do
    Keyword.get(Application.get_env(:embers, Embers.Profile), :bucket, "local")
  end
end
