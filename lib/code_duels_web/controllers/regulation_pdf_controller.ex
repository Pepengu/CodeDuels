defmodule CodeDuelsWeb.RegulationPdfController do
  use CodeDuelsWeb, :controller

  def show(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {int_id, ""} when int_id > 0 ->
        path = Path.join(CodeDuels.Typst.cache_dir(int_id), "regulations.pdf")

        case File.stat(path) do
          {:ok, _} ->
            conn
            |> put_resp_content_type("application/pdf")
            |> put_resp_header(
              "content-disposition",
              ~s(attachment; filename="regulation_#{id}.pdf")
            )
            |> send_file(200, path)

          {:error, _} ->
            conn
            |> put_status(:not_found)
            |> put_resp_content_type("text/plain")
            |> send_resp(404, "PDF для этого турнира ещё не сгенерирован.")
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> send_resp(400, "Invalid tournament ID.")
    end
  end
end
