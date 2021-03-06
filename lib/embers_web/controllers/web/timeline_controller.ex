defmodule EmbersWeb.Web.TimelineController do
  @moduledoc false
  use EmbersWeb, :controller

  import EmbersWeb.Authorize

  alias Embers.Feed.Timeline

  plug(:user_check when action in [:show, :hide_activity])

  action_fallback(EmbersWeb.FallbackController)

  def index(conn, params) do
    user = conn.assigns.current_user

    results =
      Timeline.get(
        user_id: user.id,
        with_replies: 2,
        after: params["after"],
        before: params["before"],
        limit: params["limit"]
      )

    {:ok, page_metadata} =
      Map.from_struct(results)
      |> Map.drop([:entries])
      |> Jason.encode()

    conn
    |> put_layout(false)
    |> Plug.Conn.put_resp_header("embers-page-metadata", page_metadata)
    |> render(:index, results: results)
  end

  def hide_activity(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, _activity} <- Timeline.delete_activity(user.id, id) do
      conn
      |> json(nil)
    end
  end
end
