defmodule Boneyard do
  @doc """
  Looks up `Application` config or raises if keyspace is not configured.

  ## Examples

      config :boneyard, :files, [
        uploads_dir: Path.expand("../priv/uploads", __DIR__),
        host: [scheme: "http", host: "localhost", port: 4000],
      ]

      iex> Boneyard.config([:files, :uploads_dir])
      iex> Boneyard.config([:files, :host, :port])
  """
  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:boneyard, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

  def base_uri() do
    config = Enum.into(Boneyard.config([BoneyardWeb.Endpoint, :url]), %{})
    scheme = Map.get(config, :scheme, "http")
    host = Map.get(config, :host, "localhost")
    port = Map.get(config, :port, String.to_integer(System.get_env("PORT") || "4000"))
    %URI{scheme: scheme, host: host, port: port}
  end

  def mix_env, do: config([:mix_env])
end
