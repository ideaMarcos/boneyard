defmodule BoneyardWeb.PageController do
  use BoneyardWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
