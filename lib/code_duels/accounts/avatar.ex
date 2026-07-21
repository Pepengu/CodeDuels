defmodule CodeDuels.Accounts.Avatar do
  @moduledoc """
  Handles storing user avatar uploads on disk, converting them to webp via Vix.
  """

  @allowed_content_types ["image/png", "image/jpeg", "image/webp"]
  @allowed_extensions [".png", ".jpg", ".jpeg", ".webp"]

  @doc """
  Stores a `%Plug.Upload{}` for the given user id, converting it to webp.

  Returns `{:ok, "avatars/{user_id}-{unix_ts}.webp"}` on success, or
  `{:error, reason}` on failure. Does not delete any previously stored avatar;
  callers that want replacement semantics should use
  `CodeDuels.Accounts.update_avatar/2`.
  """
  def store(user_id, %Plug.Upload{} = upload) do
    if valid_upload?(upload) do
      do_store(user_id, upload)
    else
      {:error, :invalid_file}
    end
  end

  def store(_user_id, _upload), do: {:error, :invalid_upload}

  defp valid_upload?(%Plug.Upload{content_type: content_type, filename: filename}) do
    ext = filename |> Path.extname() |> String.downcase()
    content_type in @allowed_content_types and ext in @allowed_extensions
  end

  defp do_store(user_id, %Plug.Upload{path: tmp_path}) do
    with {:ok, image} <- Vix.Vips.Image.new_from_file(tmp_path),
         :ok <- File.mkdir_p(avatars_dir()),
         filename <- "#{user_id}-#{System.os_time(:second)}.webp",
         dest_path <- Path.join(avatars_dir(), filename),
         :ok <- Vix.Vips.Image.write_to_file(image, dest_path, Q: 90) do
      {:ok, Path.join("avatars", filename)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp uploads_dir, do: Path.join(Application.app_dir(:code_duels), "priv/uploads")
  defp avatars_dir, do: Path.join(uploads_dir(), "avatars")

  @doc """
  Deletes the avatar file referenced by `avatar_path` (e.g. "avatars/5-123.webp").
  """
  def delete(nil), do: :ok

  def delete(avatar_path) do
    full_path = Path.join(uploads_dir(), avatar_path)
    if File.exists?(full_path), do: File.rm(full_path), else: :ok
  end
end
