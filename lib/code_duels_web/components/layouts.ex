defmodule CodeDuelsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use CodeDuelsWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current logged in user"
  attr :locale, :string, default: "en"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-sm">
      <div class="navbar-start">
        <a class="text-2xl font-bold text-primary" href="/">⚡ CodeDuels</a>
      </div>
      <div class="navbar-center lg:flex gap-2">
        <.link navigate="/tournament/" class="btn">Турниры</.link>
        <.link navigate="/regulations" class="btn">Положение</.link>
      </div>
      <div class="navbar-end gap-2">
        <%= if @current_user do %>
          <a>{@current_user.name || @current_user.username}</a>
        <% end %>
        <.theme_toggle />
      </div>
    </div>

    {render_slot(@inner_block)}

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/2 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=tokyo-night]_&]:left-1/2 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="nord"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="tokyo-night"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  def locale_toggle(assigns) do
    ~H"""
    <div class="flex gap-1">
      <.link navigate={~p"/?locale=en"} class="btn btn-ghost btn-sm">
        EN
      </.link>
      <.link navigate={~p"/?locale=ru"} class="btn btn-ghost btn-sm">
        RU
      </.link>
    </div>
    """
  end
end
