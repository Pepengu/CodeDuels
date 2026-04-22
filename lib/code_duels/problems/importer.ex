defmodule CodeDuels.Problems.Importer do
  import SweetXml

  alias CodeDuels.Problems.Problem
  alias CodeDuels.Repo

  require Logger

  @base_path "priv/uploads/problems"

  def import_from_zip(zip_path) when is_binary(zip_path) do
    with {:ok, zip_data} <- File.read(zip_path),
         {:ok, problem} <- import_zip_data(zip_data) do
      {:ok, problem}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def import_from_url(url) when is_binary(url) do
    with {:ok, zip_data} <- download_zip(url),
         {:ok, problem} <- import_zip_data(zip_data) do
      {:ok, problem}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_zip(url) do
    cookie = System.get_env("CF_COOKIE")

    headers =
      if cookie do
        [{"cookie", cookie}]
      else
        []
      end

    case Req.get(url, headers: headers, follow_redirect: true) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp import_zip_data(zip_data) do
    with :ok <- ensure_base_path(),
         :ok <- ensure_temp_path(),
         {:ok, placeholder} <- insert_placeholder(),
         extract_path <- Path.join(@base_path, to_string(placeholder.id)),
         :ok <- File.mkdir_p(extract_path),
         :ok <- extract_zip(zip_data, extract_path),
         :ok <- validate_extracted(extract_path),
         {:ok, metadata} <- parse_problem_xml(extract_path),
         problem_attrs <- build_problem_attrs(metadata, extract_path),
         {:ok, _updated} <- update_problem(placeholder, problem_attrs) do
      {:ok, Repo.reload(placeholder)}
    else
      {:error, reason} ->
        Logger.error("Import failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp ensure_temp_path do
    temp_path = Path.join(Application.app_dir(:code_duels), @base_path <> "-temp")
    File.mkdir_p(temp_path)
  end

  defp insert_placeholder do
    %Problem{}
    |> Problem.changeset(%{
      title: "Importing...",
      files_path: ""
    })
    |> Repo.insert()
  end

  defp update_problem(problem, attrs) do
    problem
    |> Problem.changeset(attrs)
    |> Repo.update()
  end

  defp ensure_base_path do
    path = Path.join(Application.app_dir(:code_duels), @base_path)
    File.mkdir_p(path)
  end

  defp extract_zip(zip_data, extract_path) do
    zip_path = Path.join(extract_path, "temp.zip")

    case File.write(zip_path, zip_data) do
      :ok ->
        case :zip.unzip(to_charlist(zip_path), [{:cwd, to_charlist(extract_path)}]) do
          {:ok, _} ->
            File.rm(zip_path)
            :ok

          {:error, reason} ->
            File.rm(zip_path)
            {:error, {:zip_error, reason}}
        end

      {:error, reason} ->
        {:error, {:file_write_error, reason}}
    end
  end

  defp validate_extracted(path) do
    xml_path = Path.join(path, "problem.xml")
    if File.exists?(xml_path), do: :ok, else: {:error, :missing_problem_xml}
  end

  def parse_problem_xml(path) do
    xml_path = Path.join(path, "problem.xml")

    try do
      xml = File.read!(xml_path) |> SweetXml.parse()
      metadata = extract_title_and_limits(xml, path)
      {:ok, metadata}
    rescue
      e in _ ->
        {:error, {:xml_parse_error, Exception.message(e)}}
    end
  end

  defp extract_title_and_limits(xml, path) do
    short_name = xml |> SweetXml.xpath(~x"//name[@language='russian']/@value"s)
    time_limit = xml |> SweetXml.xpath(~x"//judging/testset/time-limit/text()"s)
    memory_limit = xml |> SweetXml.xpath(~x"//judging/testset/memory-limit/text()"s)

    checker_path = xml |> SweetXml.xpath(~x"//assets/checker/source/@path"s)
    validator_path = xml |> SweetXml.xpath(~x"//assets/validators/validator/source/@path"s)

    statement_path = xml |> SweetXml.xpath(~x"//statements/statement[@type='text/html']/@path"s)

    statement_lang =
      xml |> SweetXml.xpath(~x"//statements/statement[@type='text/html']/@language"s)

    solutions =
      xml
      |> SweetXml.xpath(~x"//assets/solutions/solution"l)
      |> Enum.map(fn sol ->
        tag = SweetXml.xpath(sol, ~x"@tag"s)
        source = SweetXml.xpath(sol, ~x"source/@path"s)
        type = SweetXml.xpath(sol, ~x"source/@type"s)
        language = extension_to_language(type && String.replace(type, ~r/\..*/, ""))
        code_path = source && Path.join(path, source)
        %{tag: tag, source_path: code_path, language: language}
      end)

    %{
      title: short_name || "Untitled Problem",
      time_limit_ms: parse_time_limit(time_limit),
      memory_limit_kb: parse_memory_limit(memory_limit),
      checker: checker_path && Path.join(path, checker_path),
      validator: validator_path && Path.join(path, validator_path),
      statement: statement_path && Path.join(path, statement_path),
      statement_lang: statement_lang,
      solutions: solutions
    }
  end

  defp parse_time_limit(nil), do: nil

  defp parse_time_limit(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace_suffix("s", "")
    |> String.replace_suffix("ms", "")
    |> Integer.parse()
    |> case do
      {ms, _} when ms < 1000 -> ms * 1000
      {ms, _} -> ms
      :error -> nil
    end
  end

  defp parse_memory_limit(nil), do: nil

  defp parse_memory_limit(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace_suffix("Mb", "")
    |> String.replace_suffix("MB", "")
    |> String.replace_suffix("kb", "")
    |> String.replace_suffix("KB", "")
    |> Integer.parse()
    |> case do
      {bytes, _} -> div(bytes, 1024)
      :error -> nil
    end
  end

  def build_problem_attrs(metadata, files_path) do
    %{
      title: metadata.title,
      time_limit_ms: metadata.time_limit_ms,
      memory_limit_kb: metadata.memory_limit_kb,
      statement: metadata.statement,
      statement_lang: metadata.statement_lang,
      solutions: metadata.solutions,
      checker: metadata.checker,
      validator: metadata.validator,
      files_path: files_path
    }
  end

  defp extension_to_language("cpp"), do: "C++"
  defp extension_to_language("c"), do: "C"
  defp extension_to_language("java"), do: "Java"
  defp extension_to_language("py"), do: "Python"
  defp extension_to_language("python3"), do: "Python"
  defp extension_to_language("go"), do: "Go"
  defp extension_to_language("rs"), do: "Rust"
  defp extension_to_language("js"), do: "JavaScript"
  defp extension_to_language(ext), do: String.upcase(ext)
end
