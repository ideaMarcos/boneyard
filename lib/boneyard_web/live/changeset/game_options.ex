defmodule BoneyardWeb.Changeset.GameOptions do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :player_name, :string, default: ""
  end

  def new(), do: %__MODULE__{}

  def changeset(%__MODULE__{} = game, attrs) do
    game
    |> cast(attrs, [:player_name])
    |> validate_required([:player_name])
    |> update_change(:player_name, &String.trim/1)
    |> update_change(:player_name, &String.downcase/1)
    |> validate_length(:player_name, min: 1, max: 10)
    |> validate_format(:player_name, ~r/^[\w\s]+$/,
      message: "Only letters, numbers, and spaces are allowed"
    )
  end

  def apply_update(changeset), do: apply_action(changeset, :update)
end
