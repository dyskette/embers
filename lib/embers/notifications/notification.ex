defmodule Embers.Notifications.Notification do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @valid_types ~w(follow comment mention system)

  @type t :: %__MODULE__{}

  @primary_key {:id, Embers.Hashid, autogenerate: true}
  schema "notifications" do
    field(:type, :string, null: false)
    field(:source_id, Embers.Hashid)
    field(:text, :string)
    field(:status, :integer)

    belongs_to(:from, Embers.Accounts.User, type: Embers.Hashid)
    belongs_to(:recipient, Embers.Accounts.User, type: Embers.Hashid)

    timestamps()
  end

  def create_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:type, :recipient_id, :from_id, :source_id, :text, :status])
    |> validate_required([:type, :recipient_id])
    |> validate_inclusion(:status, [0, 1, 2])
    |> validate_inclusion(
      :type,
      @valid_types,
      message: "is not a valid type, use one of: #{Enum.join(@valid_types, " ")}"
    )
  end
end
