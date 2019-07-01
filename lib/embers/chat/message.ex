defmodule Embers.Chat.Message do
  @moduledoc """
  Mensaje de chat.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Embers.Repo

  schema "chat_messages" do
    belongs_to(:sender, Embers.Accounts.User)
    belongs_to(:receiver, Embers.Accounts.User)

    field(:text, :string)

    field(:read_at, :utc_datetime)
    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender_id, :receiver_id, :text, :read_at])
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:receiver_id)
    |> check_blocked(attrs)
    |> trim_text(attrs)
    |> validate_length(:text, min: 1, max: 1600)
    |> validate_required([:text])
  end

  def read_changeset(message) do
    message
    |> change(read_at: DateTime.utc_now())
  end

  defp trim_text(changeset, %{"text" => text} = _attrs) do
    changeset
    |> change(text: String.trim(text))
  end

  defp check_blocked(changeset, attrs) do
    user_id = get_change(changeset, :sender_id)
    receiver_id = get_change(changeset, :receiver_id)

    is_blocked? =
      Repo.exists?(
        from(
          b in Embers.Feed.Subscriptions.UserBlock,
          where: b.source_id == ^user_id and b.user_id == ^receiver_id,
          or_where: b.source_id == ^receiver_id and b.user_id == ^user_id
        )
      )

    if is_blocked? do
      changeset
      |> Ecto.Changeset.add_error(:blocked, "conversation blocked")
    else
      changeset
    end
  end
end