defmodule CodeDuelsWeb.Router do
  use CodeDuelsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CodeDuelsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CodeDuelsWeb.Plugs.Auth, :fetch_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CodeDuelsWeb do
    pipe_through :browser

    get "/login", AuthController, :new
    post "/login", AuthController, :create
    get "/logout", AuthController, :delete

    pipe_through :redirect_if_not_authenticated

    live_session :default,
      on_mount: {CodeDuelsWeb.LiveAuth, :default} do
      live "/", HomePageLive, :index
      live "/tournament", TournamentPageLive, :index
      live "/tournament/:id", TournamentDetailLive, :show
      live "/tournament/:id/registration", TournamentRegistrationLive, :show
      live "/tournament/:id/standings", StandingsLive, :show
      live "/tournament/:id/pairings", PairingsLive, :show
      live "/tournament/:tournament_id/:round_number/submissions", SubmissionsLive, :show

      live "/tournament/:tournament_id/:round_number/submissions/:submission_id",
           SubmissionViewLive,
           :show

      live "/tournament/:tournament_id/:round_number", RoundDetailLive, :show
      live "/tournament/:tournament_id/:round_number/problem", ProblemLive, :show
      live "/tournament/:tournament_id/:round_number/submit", SubmitLive, :show
    end

    get "/:tournament_id/:round_number/:filename", ProblemFileController, :serve_statement_file
  end

  if Application.compile_env(:code_duels, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      import Phoenix.LiveDashboard.Router

      live_dashboard "/dashboard", metrics: CodeDuelsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def redirect_if_not_authenticated(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in.")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
