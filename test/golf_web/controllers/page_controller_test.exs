defmodule GolfWeb.PageControllerTest do
  use GolfWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert conn.status == 200
    # assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
