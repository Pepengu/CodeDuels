defmodule CodeDuelsWeb.RegulationsController do
  use CodeDuelsWeb, :controller

  def show(conn, _params) do
    path = Path.expand("priv/regulations/regulations.html")

    case File.read(path) do
      {:ok, html} ->
        render(conn, :show, html: HtmlSanitizeEx.html5(html))

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "Регламент ещё не сгенерирован. Попробуйте позже.")
    end
  end

  def pdf(conn, _params) do
    path = Path.expand("priv/regulations/regulations.pdf")

    case File.stat(path) do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", ~s(attachment; filename="regulations.pdf"))
        |> send_file(200, path)

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "PDF ещё не сгенерирован. Попробуйте позже.")
    end
  end
end
