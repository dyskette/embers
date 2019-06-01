defmodule EmbersWeb.UserController do
  use EmbersWeb, :controller

  import EmbersWeb.Authorize
  import EmbersWeb.Helpers
  alias Embers.Accounts

  # the following plugs are defined in the controllers/authorize.ex file
  plug(:user_check when action in [:index, :show])
  plug(:id_check when action in [:edit, :update, :delete])

  def show(%Plug.Conn{assigns: %{current_user: current_user}} = conn, %{"id" => id}) do
    user =
      id
      |> Accounts.get_populated()
      |> Accounts.User.load_following_status(current_user.id)
      |> Accounts.User.load_follows_me_status(current_user.id)
      |> Accounts.User.load_blocked_status(current_user.id)

    render(conn, "show.json", user: user)
  end

  def update(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"user" => user_params}) do
    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        success(conn, "User updated successfully", user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "show.json", changeset: changeset)
    end
  end

  def delete(%Plug.Conn{assigns: %{current_user: user}} = conn, _) do
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> delete_session(:phauxth_session_id)
    |> success("User deleted successfully", session_path(conn, :new))
  end
end
