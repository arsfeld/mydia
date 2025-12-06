defmodule MydiaWeb.AdultLive.Show do
  @moduledoc """
  LiveView for viewing individual adult media files with video player and metadata.
  """

  use MydiaWeb, :live_view

  alias Mydia.Library
  alias Mydia.Library.GeneratedMedia
  alias Mydia.Library.PreviewGenerator
  alias Mydia.Library.SpriteGenerator
  alias Mydia.Library.ThumbnailGenerator

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    file = Library.get_media_file!(id, preload: [:library_path])

    {:ok,
     socket
     |> assign(:file, file)
     |> assign(:page_title, get_display_name(file))
     |> assign(:generating_thumbnail, false)
     |> assign(:generating_sprites, false)
     |> assign(:generating_preview, false)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_thumbnail", _params, socket) do
    file = socket.assigns.file

    socket = assign(socket, :generating_thumbnail, true)

    # Generate thumbnail in a task to avoid blocking
    Task.start(fn ->
      case ThumbnailGenerator.generate_cover(file) do
        {:ok, checksum} ->
          # Update the media file with the new thumbnail
          Library.update_media_file(file, %{
            cover_blob: checksum,
            generated_at: DateTime.utc_now()
          })

          send(self(), {:thumbnail_generated, checksum})

        {:error, reason} ->
          send(self(), {:thumbnail_error, reason})
      end
    end)

    {:noreply, socket}
  end

  def handle_event("generate_sprites", _params, socket) do
    file = socket.assigns.file

    socket = assign(socket, :generating_sprites, true)

    Task.start(fn ->
      case SpriteGenerator.generate(file) do
        {:ok, result} ->
          # Update the media file with the new sprite and VTT
          Library.update_media_file(file, %{
            sprite_blob: result.sprite_checksum,
            vtt_blob: result.vtt_checksum,
            generated_at: DateTime.utc_now()
          })

          send(self(), {:sprites_generated, result})

        {:error, reason} ->
          send(self(), {:sprites_error, reason})
      end
    end)

    {:noreply, socket}
  end

  def handle_event("generate_preview", _params, socket) do
    file = socket.assigns.file

    socket = assign(socket, :generating_preview, true)

    Task.start(fn ->
      case PreviewGenerator.generate(file) do
        {:ok, checksum} ->
          Library.update_media_file(file, %{
            preview_blob: checksum,
            generated_at: DateTime.utc_now()
          })

          send(self(), {:preview_generated, checksum})

        {:error, reason} ->
          send(self(), {:preview_error, reason})
      end
    end)

    {:noreply, socket}
  end

  def handle_event("delete_file", _params, socket) do
    file = socket.assigns.file

    case Library.delete_media_file(file) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "File deleted successfully")
         |> push_navigate(to: ~p"/adult")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete file")}
    end
  end

  @impl true
  def handle_info({:thumbnail_generated, checksum}, socket) do
    file = %{socket.assigns.file | cover_blob: checksum}

    {:noreply,
     socket
     |> assign(:file, file)
     |> assign(:generating_thumbnail, false)
     |> put_flash(:info, "Thumbnail generated successfully")}
  end

  def handle_info({:thumbnail_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_thumbnail, false)
     |> put_flash(:error, "Failed to generate thumbnail: #{inspect(reason)}")}
  end

  def handle_info({:sprites_generated, _result}, socket) do
    # Reload the file to get updated sprite/vtt blobs
    file = Library.get_media_file!(socket.assigns.file.id, preload: [:library_path])

    {:noreply,
     socket
     |> assign(:file, file)
     |> assign(:generating_sprites, false)
     |> put_flash(:info, "Sprite sheet and VTT generated successfully")}
  end

  def handle_info({:sprites_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_sprites, false)
     |> put_flash(:error, "Failed to generate sprites: #{inspect(reason)}")}
  end

  def handle_info({:preview_generated, checksum}, socket) do
    file = %{socket.assigns.file | preview_blob: checksum}

    {:noreply,
     socket
     |> assign(:file, file)
     |> assign(:generating_preview, false)
     |> put_flash(:info, "Preview video generated successfully")}
  end

  def handle_info({:preview_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_preview, false)
     |> put_flash(:error, "Failed to generate preview: #{inspect(reason)}")}
  end

  defp get_display_name(file) do
    case file.relative_path do
      nil -> "Unknown"
      path -> Path.basename(path)
    end
  end

  defp get_sprite_url(file) do
    if file.sprite_blob do
      GeneratedMedia.url_path(:sprite, file.sprite_blob)
    else
      nil
    end
  end

  defp get_vtt_url(file) do
    if file.vtt_blob do
      GeneratedMedia.url_path(:vtt, file.vtt_blob)
    else
      nil
    end
  end

  defp get_preview_url(file) do
    if file.preview_blob do
      GeneratedMedia.url_path(:preview, file.preview_blob)
    else
      nil
    end
  end

  defp get_video_url(file) do
    # Use the existing stream endpoint with media file ID
    "/api/v1/stream/#{file.id}"
  end

  defp format_file_size(nil), do: "-"

  defp format_file_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 0)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_date(nil), do: "-"

  defp format_date(%DateTime{} = date) do
    Calendar.strftime(date, "%Y-%m-%d %H:%M")
  end
end
