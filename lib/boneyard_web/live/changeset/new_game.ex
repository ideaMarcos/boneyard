defmodule BoneyardWeb.Changeset.NewGame do
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
    |> validate_length(:player_name, min: 2, max: 20)
    |> update_change(:player_name, &String.trim/1)
    |> validate_format(:player_name, ~r/^[\w\s]+$/)
  end

  def apply(changeset), do: apply_action!(changeset, :update)
end
