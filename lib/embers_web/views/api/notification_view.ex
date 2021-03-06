defmodule EmbersWeb.Api.NotificationView do
  @moduledoc false

  use EmbersWeb, :view

  def render("notifications.json", %{entries: notifications} = metadata) do
    %{
      items: render_many(notifications, __MODULE__, "notification.json"),
      next: metadata.next,
      last_page: metadata.last_page
    }
  end

  def render("notification.json", %{notification: notification} = _assigns) do
    %{
      id: notification.id,
      type: notification.type,
      text: text_for(notification),
      status: notification.status,
      inserted_at: notification.inserted_at,
      source_id: notification.source_id,
      image: get_image(notification)
    }
    |> handle_from(notification)
  end

  defp handle_from(view, notification) do
    if(Ecto.assoc_loaded?(notification.from)) do
      user = render_one(notification.from, EmbersWeb.Api.UserView, "user.json")
      Map.put(view, "from", user.username)
    end || view
  end

  defp text_for(notification) do
    case notification.type do
      "comment" ->
        "**#{notification.from.username}** #{gettext("commented in your")} **post**"

      "mention" ->
        "**#{notification.from.username}** #{gettext("mentioned you in a")} **post**"

      "follow" ->
        "**#{notification.from.username}** #{gettext("is following you")}"
    end
  end

  defp get_image(notification) do
    if(Ecto.assoc_loaded?(notification.from)) do
      map = Embers.Profile.Meta.avatar_map(notification.from.meta)
      map.small
    else
      image_for_type(notification.type)
    end
  end

  defp image_for_type(type) do
    "/img/notifications/#{type}.png"
  end
end
