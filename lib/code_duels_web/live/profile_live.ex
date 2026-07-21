defmodule CodeDuelsWeb.ProfileLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.Helpers.SubmissionHelpers

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <%= if @user do %>
          <%= if @head_to_head do %>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <.user_header
                user={@user}
                is_own_profile={@current_user && @current_user.id == @user.id}
                class="md:col-span-2"
              />
              <.head_to_head_card head_to_head={@head_to_head} />
            </div>
          <% else %>
            <div class="mb-8">
              <.user_header
                user={@user}
                is_own_profile={@current_user && @current_user.id == @user.id}
              />
            </div>
          <% end %>
          <details class="mb-8 group">
            <summary class="cursor-pointer flex items-center gap-2 text-xl font-semibold p-2 rounded-lg hover:bg-base-200 select-none">
              <.icon
                name="hero-chevron-down"
                class="w-5 h-5 transition-transform group-open:rotate-180"
              /> Статистика
            </summary>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 mb-8">
              <.languages_card profile_stats={@profile_stats} />
              <.verdicts_card
                profile_stats={@profile_stats}
                verdict_segments={@verdict_segments}
                verdict_total={@verdict_total}
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <.tournaments_card stats={@stats} tournament_ranks={@tournament_ranks} />
              <.duels_card duel_stats={@duel_stats} />
              <.recent_submissions_card recent_submissions={@recent_submissions} />
            </div>
          </details>

          <.tournament_history
            participations={@participations}
            tournament_wdl={@tournament_wdl}
            tournament_ranks={@tournament_ranks}
          />
        <% else %>
          <div class="alert alert-error">
            <span>Пользователя с ID {@user_id} не существует</span>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    user = CodeDuels.Accounts.get_user(id)
    participations = CodeDuels.Tournaments.get_user_history(id)
    stats = calculate_stats(participations)
    profile_stats = CodeDuels.Tournaments.get_user_profile_stats(id)
    {duel_stats, tournament_wdl} = CodeDuels.Tournaments.get_user_duel_stats(id)
    tournament_ranks = calculate_tournament_ranks(id, participations)
    recent_submissions = CodeDuels.Tournaments.get_user_recent_submissions(id, 5)

    profile_user_id = String.to_integer(id)

    head_to_head =
      case socket.assigns do
        %{current_user: %{id: viewer_id}} when viewer_id != profile_user_id ->
          CodeDuels.Tournaments.get_head_to_head_duels(viewer_id, profile_user_id)

        _ ->
          nil
      end

    profile_stats =
      Map.update!(profile_stats, :languages, fn langs ->
        langs
        |> Enum.group_by(fn {lang, _} -> language_family(lang) end, fn {_, count} -> count end)
        |> Enum.map(fn {lang, counts} -> {lang, Enum.sum(counts)} end)
        |> Enum.sort(fn {_, lhs}, {_, rhs} -> lhs > rhs end)
      end)

    verdict_total = profile_stats.verdicts |> Map.values() |> Enum.sum()

    verdict_segments = build_verdict_segments(profile_stats.verdicts, verdict_total)

    {:ok,
     assign(socket, %{
       user: user,
       participations: participations,
       user_id: id,
       stats: stats,
       profile_stats: profile_stats,
       duel_stats: duel_stats,
       tournament_wdl: tournament_wdl,
       tournament_ranks: tournament_ranks,
       verdict_segments: verdict_segments,
       verdict_total: verdict_total,
       recent_submissions: recent_submissions,
       head_to_head: head_to_head
     })}
  end

  # -- Components --------------------------------------------------------

  defp user_header(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-xl", assigns[:class]]}>
      <div class="card-body">
        <div class="flex items-center gap-6">
          <%= if @user.avatar_path do %>
            <img
              src={"/uploads/" <> @user.avatar_path}
              class="w-20 h-20 rounded-full object-cover ring-2 ring-base-300"
              alt={@user.username}
            />
          <% else %>
            <div class="w-20 h-20 rounded-full bg-neutral text-neutral-content flex items-center justify-center text-3xl font-bold select-none">
              {String.first(@user.username) |> String.upcase()}
            </div>
          <% end %>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-3">
              <h2 class="card-title text-2xl">{@user.username}</h2>
              <%= if @user.is_admin do %>
                <span class="badge badge-error">Админ</span>
              <% end %>
              <%= if @is_own_profile do %>
                <.link
                  href="#"
                  class="btn btn-ghost btn-xs hover:opacity-100 ml-auto"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.link>
              <% end %>
            </div>
            <p class="text-lg">{@user.name}</p>
            <p class="text-sm opacity-70">ID: {@user.id}</p>
            <p class="text-sm opacity-70">
              Участник с {Calendar.strftime(@user.inserted_at, "%d.%m.%Y")}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp head_to_head_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h3 class="card-title text-xl">Дуэли между вами</h3>
        <div class="grid grid-cols-3 gap-3">
          <div
            class="flex flex-col items-center gap-1 p-3 rounded-lg"
            style="background: color-mix(in srgb, var(--color-player-a) 18%, transparent)"
          >
            <.icon
              name="hero-arrow-trending-up"
              class="w-5 h-5 text-[var(--color-player-a)]"
            />
            <span class="text-2xl font-bold tabular-nums" style="color: var(--color-player-a)">
              {@head_to_head.wins}
            </span>
            <span class="text-xs opacity-60">побед</span>
          </div>
          <div
            class="flex flex-col items-center gap-1 p-3 rounded-lg"
            style="background: color-mix(in srgb, var(--color-draw) 18%, transparent)"
          >
            <.icon name="hero-minus" class="w-5 h-5 text-[var(--color-draw)]" />
            <span class="text-2xl font-bold tabular-nums" style="color: var(--color-draw)">
              {@head_to_head.draws}
            </span>
            <span class="text-xs opacity-60">ничьих</span>
          </div>
          <div
            class="flex flex-col items-center gap-1 p-3 rounded-lg"
            style="background: color-mix(in srgb, var(--color-player-b) 18%, transparent)"
          >
            <.icon
              name="hero-arrow-trending-down"
              class="w-5 h-5 text-[var(--color-player-b)]"
            />
            <span class="text-2xl font-bold tabular-nums" style="color: var(--color-player-b)">
              {@head_to_head.losses}
            </span>
            <span class="text-xs opacity-60">поражений</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp languages_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body flex flex-col h-full">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <h3 class="card-title text-xl">Языки программирования</h3>
        </div>

        <%= if Enum.empty?(@profile_stats.languages) do %>
          <div class="alert alert-info mt-4">Нет принятых языков.</div>
        <% else %>
          <% max_count = @profile_stats.languages |> List.first() |> elem(1) %>
          <div class="flex flex-col gap-2 mt-4">
            <%= for {lang, count} <- @profile_stats.languages do %>
              <% pct =
                if @profile_stats.verdicts.accepted > 0,
                  do: count / @profile_stats.verdicts.accepted * 100,
                  else: 0 %>
              <% bar_width = if max_count > 0, do: count / max_count * 100, else: 0 %>
              <div class="flex items-center gap-3">
                <img
                  :if={language_logo_url(lang)}
                  src={language_logo_url(lang)}
                  class="w-5 h-5 shrink-0"
                  alt=""
                />
                <span class="text-sm font-medium w-28 truncate shrink-0">
                  {language_display(lang)}
                </span>
                <div class="flex-1 h-3 rounded-full overflow-hidden bg-base-300">
                  <div
                    class="h-full rounded-full"
                    style={"width: #{bar_width}%; background-color: #{language_color(lang)}"}
                  >
                  </div>
                </div>
                <span
                  class="text-sm font-semibold tabular-nums w-8 text-right shrink-0"
                  style={"color: #{language_color(lang)}"}
                >
                  {count}
                </span>
                <span class="text-xs opacity-50 tabular-nums w-12 text-right shrink-0">
                  {round(pct)}%
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp verdicts_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body px-4 py-5">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <h3 class="card-title text-xl">Статистика вердиктов</h3>
          <div class="text-sm opacity-70">
            Всего посылок: {@profile_stats.total_submissions}
          </div>
        </div>

        <div class="mt-4 flex flex-col items-center gap-6 sm:flex-row sm:items-center sm:justify-center">
          <% circumference = 2 * :math.pi() * 20 %>
          <div class="relative w-40 h-40 donut-wrap transition-opacity duration-200">
            <div class="default-readout absolute inset-0 flex flex-col items-center justify-center pointer-events-none transition-opacity duration-200">
              <span class="text-2xl font-bold leading-none">
                {@verdict_total}
              </span>
              <span class="text-sm opacity-60 mt-0.5">всего</span>
            </div>

            <svg
              viewBox="0 0 48 48"
              class="absolute inset-0 w-40 h-40 -rotate-90 pointer-events-none"
            >
              <circle
                cx="24"
                cy="24"
                r="20"
                fill="none"
                class="stroke-base-300"
                stroke-width="4"
              />
            </svg>

            <svg viewBox="0 0 48 48" class="absolute inset-0 w-40 h-40 -rotate-90">
              <%= for seg <- @verdict_segments do %>
                <% seg_arc = circumference * (seg.pct / 100) %>
                <% gap = if seg.pct < 100, do: 1.5, else: 0 %>
                <% style = verdict_style(seg.verdict) %>
                <g
                  class="g-seg cursor-pointer transition-transform duration-300 hover:scale-[1.04]"
                  style="transform-origin: 24px 24px"
                >
                  <circle
                    cx="24"
                    cy="24"
                    r="20"
                    fill="none"
                    stroke="transparent"
                    stroke-width="24"
                    stroke-dasharray={"#{max(seg_arc - gap, 0)} #{circumference}"}
                    stroke-dashoffset={-seg.offset / 100 * circumference}
                  />
                  <circle
                    cx="24"
                    cy="24"
                    r="20"
                    fill="none"
                    stroke-width="4"
                    stroke-dasharray={"#{max(seg_arc - gap, 0)} #{circumference}"}
                    stroke-dashoffset={-seg.offset / 100 * circumference}
                    class={[
                      donut_color(seg.verdict),
                      "seg-arc transition-all duration-200"
                    ]}
                  />
                  <foreignObject
                    x="0"
                    y="0"
                    width="48"
                    height="48"
                    class="pointer-events-none"
                  >
                    <div
                      xmlns="http://www.w3.org/1999/xhtml"
                      class="seg-readout hidden flex-col items-center justify-center w-full h-full text-center rotate-90"
                    >
                      <span class={["text-[7px] font-bold leading-none", style.text]}>
                        {seg.count}
                      </span>
                      <%= for word <- String.split(verdict_label(seg.verdict), " ") do %>
                        <span class="text-[4px] opacity-70 leading-tight">{word}</span>
                      <% end %>
                      <span class="text-[4px] opacity-50 mt-0.5">
                        {round(seg.pct)}%
                      </span>
                    </div>
                  </foreignObject>
                </g>
              <% end %>
            </svg>
          </div>

          <ul class="grid grid-cols-1 gap-2 text-sm w-full sm:w-auto">
            <%= for seg <- @verdict_segments do %>
              <% style = verdict_style(seg.verdict) %>
              <li class="flex items-center gap-2">
                <span class={["inline-block w-3 h-3 rounded-sm shrink-0", style.bar]}></span>
                <.icon
                  name={verdict_icon(seg.verdict)}
                  class={["w-4 h-4 shrink-0", style.text] |> Enum.join(" ")}
                />
                <span class="opacity-80">{verdict_label(seg.verdict)}</span>
                <span class="ml-auto font-semibold tabular-nums">{seg.count}</span>
                <span class="opacity-60 text-xs tabular-nums w-10 text-right">
                  {round(seg.pct)}%
                </span>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp tournaments_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl flex flex-col">
      <div class="card-body flex flex-col flex-1">
        <% ranks =
          @tournament_ranks
          |> Map.values()
          |> Enum.reject(&is_nil/1)

        gold = Enum.count(ranks, &(&1 == 1))
        silver = Enum.count(ranks, &(&1 == 2))
        bronze = Enum.count(ranks, &(&1 == 3)) %>
        <div class="flex items-center justify-between">
          <h3 class="card-title text-xl">Турниры</h3>
          <span class="text-sm opacity-70">
            Всего: <span class="font-bold">{@stats.total}</span>
          </span>
        </div>
        <div class="flex flex-col items-center gap-3 mt-auto pt-3">
          <div class="flex items-end gap-1 justify-center">
            <div class="flex flex-col items-center gap-1">
              <span class="text-xs">🥈</span>
              <div class="w-10 h-10 bg-gray-400/30 rounded-t flex items-center justify-center">
                <span class="text-sm font-bold">{silver}</span>
              </div>
            </div>
            <div class="flex flex-col items-center gap-1">
              <span class="text-xs">🥇</span>
              <div class="w-10 h-14 bg-warning/30 rounded-t flex items-center justify-center">
                <span class="text-sm font-bold">{gold}</span>
              </div>
            </div>
            <div class="flex flex-col items-center gap-1">
              <span class="text-xs">🥉</span>
              <div class="w-10 h-8 bg-amber-700/30 rounded-t flex items-center justify-center">
                <span class="text-sm font-bold">{bronze}</span>
              </div>
            </div>
          </div>
          <div class="grid grid-cols-3 gap-2 w-full">
            <%= for role <- ["participant", "organizer", "volunteer"] do %>
              <% count = Map.get(@stats.roles, role, 0) %>
              <div class={"flex flex-col items-center gap-0.5 p-2 rounded-lg #{participant_role_tint(role)}"}>
                <span class="text-xs opacity-60">
                  {participant_role_label(role)}
                </span>
                <span class="text-xl font-bold">{count}</span>
              </div>
            <% end %>
          </div>
          <%= if @stats.disqualified > 0 do %>
            <div class="flex items-center gap-1.5">
              <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-error" />
              <span class="text-sm font-semibold text-error">
                Дисквалификации: {@stats.disqualified}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp duels_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl flex flex-col">
      <div class="card-body flex flex-col flex-1">
        <% total_duels = @duel_stats.wins + @duel_stats.draws + @duel_stats.losses %>
        <% win_rate =
          if total_duels > 0, do: round(@duel_stats.wins / total_duels * 100), else: 0 %>

        <div class="flex items-center justify-between">
          <h3 class="card-title text-xl">Дуэли</h3>
          <span class="text-sm opacity-70">
            Всего: <span class="font-bold">{total_duels}</span>
          </span>
        </div>

        <div class="mt-auto pt-3">
          <div class="mb-3">
            <div class="flex justify-between items-center mb-1.5">
              <span class="text-sm font-semibold" style="color: var(--color-player-a)">
                {win_rate}% побед
              </span>
            </div>
            <div class="flex h-2 rounded-full overflow-hidden bg-base-300">
              <div
                class="h-full transition-all duration-300"
                style={"width: #{if total_duels > 0, do: @duel_stats.wins / total_duels * 100, else: 0}%; background: var(--color-player-a)"}
              >
              </div>
              <div
                class="h-full transition-all duration-300"
                style={"width: #{if total_duels > 0, do: @duel_stats.draws / total_duels * 100, else: 0}%; background: var(--color-draw)"}
              >
              </div>
              <div
                class="h-full transition-all duration-300"
                style={"width: #{if total_duels > 0, do: @duel_stats.losses / total_duels * 100, else: 0}%; background: var(--color-player-b)"}
              >
              </div>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-3">
            <div
              class="flex flex-col items-center gap-1 p-3 rounded-lg"
              style="background: color-mix(in srgb, var(--color-player-a) 18%, transparent)"
            >
              <.icon
                name="hero-arrow-trending-up"
                class="w-5 h-5 text-[var(--color-player-a)]"
              />
              <span class="text-2xl font-bold tabular-nums" style="color: var(--color-player-a)">
                {@duel_stats.wins}
              </span>
              <span class="text-xs opacity-60">побед</span>
            </div>
            <div
              class="flex flex-col items-center gap-1 p-3 rounded-lg"
              style="background: color-mix(in srgb, var(--color-draw) 18%, transparent)"
            >
              <.icon name="hero-minus" class="w-5 h-5 text-[var(--color-draw)]" />
              <span class="text-2xl font-bold tabular-nums" style="color: var(--color-draw)">
                {@duel_stats.draws}
              </span>
              <span class="text-xs opacity-60">ничьих</span>
            </div>
            <div
              class="flex flex-col items-center gap-1 p-3 rounded-lg"
              style="background: color-mix(in srgb, var(--color-player-b) 18%, transparent)"
            >
              <.icon
                name="hero-arrow-trending-down"
                class="w-5 h-5 text-[var(--color-player-b)]"
              />
              <span class="text-2xl font-bold tabular-nums" style="color: var(--color-player-b)">
                {@duel_stats.losses}
              </span>
              <span class="text-xs opacity-60">поражений</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp recent_submissions_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl flex flex-col">
      <div class="card-body flex flex-col flex-1">
        <div class="flex items-center justify-between">
          <h3 class="card-title text-xl">Последние посылки</h3>
          <span class="text-sm opacity-70">
            Всего: <span class="font-bold">{length(@recent_submissions)}</span>
          </span>
        </div>
        <div class="mt-auto">
          <%= if Enum.empty?(@recent_submissions) do %>
            <p class="text-sm opacity-50">Нет посылок</p>
          <% else %>
            <div class="flex flex-col gap-3">
              <%= for sub <- @recent_submissions do %>
                <div class="flex items-center gap-3">
                  <.icon
                    name={verdict_icon(sub.verdict)}
                    class={"w-5 h-5 shrink-0 #{verdict_style(sub.verdict).text}"}
                  />
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <span class="font-semibold text-sm">
                        {sub.problem_letter}
                      </span>
                      <span class="text-xs opacity-50">·</span>
                      <span class="text-sm opacity-70 truncate">
                        {sub.problem && sub.problem.title}
                      </span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2 shrink-0">
                    <img
                      :if={language_logo_url(sub.language)}
                      src={language_logo_url(sub.language)}
                      class="w-4 h-4"
                      alt=""
                    />
                    <span class="text-xs opacity-50">{time_ago(sub.inserted_at)}</span>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp tournament_history(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h3 class="card-title text-xl mb-4">История турниров</h3>

        <%= if Enum.empty?(@participations) do %>
          <div class="alert alert-info">
            <span>Пользователь ещё не участвовал ни в одном турнире.</span>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>Турнир</th>
                  <th>Роль</th>
                  <th>Штраф</th>
                  <th>Раундов</th>
                  <th>В/Н/П</th>
                  <th>Ранг</th>
                  <th>Дата</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for p <- @participations do %>
                  <tr>
                    <td><strong>{p.tournament.name}</strong></td>
                    <td>
                      <span class={["badge", participant_role_badge(p.role)]}>
                        {participant_role_label(p.role)}
                      </span>
                    </td>
                    <td>{if p.score, do: Float.round(p.score, 1), else: "—"}</td>
                    <td>{p.tournament.rounds_amount}</td>
                    <td>
                      {wdl_text(Map.get(@tournament_wdl, p.tournament.id))}
                    </td>
                    <td>{rank_text(Map.get(@tournament_ranks, p.tournament.id))}</td>
                    <td>
                      <%= if p.tournament.start_time do %>
                        {Calendar.strftime(p.tournament.start_time, "%d.%m.%Y %H:%M")}
                      <% else %>
                        —
                      <% end %>
                    </td>
                    <td>
                      <.link
                        navigate={~p"/tournament/#{p.tournament.id}"}
                        class="btn btn-sm btn-primary btn-outline"
                      >
                        Подробнее
                      </.link>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # -- Private helpers ---------------------------------------------------

  defp build_verdict_segments(verdicts, total) do
    if total <= 0 do
      []
    else
      {_acc, segments} =
        verdicts
        |> Enum.sort_by(fn {_k, v} -> v end, :desc)
        |> Enum.reduce({0.0, []}, fn {verdict, count}, {offset, acc} ->
          pct = count / total * 100

          segment = %{
            verdict: verdict,
            count: count,
            pct: pct,
            offset: offset
          }

          {offset + pct, acc ++ [segment]}
        end)

      segments
    end
  end

  defp calculate_stats(participations) do
    total = length(participations)
    disqualified = Enum.count(participations, &(&1.role == "disqualified"))

    roles =
      participations
      |> Enum.reject(&(&1.role == "disqualified"))
      |> Enum.frequencies_by(& &1.role)

    %{
      total: total,
      disqualified: disqualified,
      roles: roles
    }
  end

  defp calculate_tournament_ranks(user_id, participations) do
    Enum.reduce(participations, %{}, fn p, acc ->
      tournament_id = p.tournament_id

      {user_id, _} = Integer.parse(user_id)

      rank =
        case CodeDuels.Tournaments.Standings.get_with_stats(tournament_id)
             |> Enum.find(&(&1.user_id == user_id)) do
          nil -> nil
          entry -> entry.rank
        end

      Map.put(acc, tournament_id, rank)
    end)
  end

  defp wdl_text(nil), do: "—"
  defp wdl_text(%{wins: w, draws: d, losses: l}), do: "#{w} / #{d} / #{l}"

  defp rank_text(nil), do: "—"
  defp rank_text(rank), do: "##{rank}"

  defp participant_role_label("participant"), do: "Участник"
  defp participant_role_label("organizer"), do: "Организатор"
  defp participant_role_label("disqualified"), do: "Дисквалифицирован"
  defp participant_role_label("volunteer"), do: "Волонтёр"
  defp participant_role_label(role), do: role

  defp participant_role_badge("participant"), do: "badge-success"
  defp participant_role_badge("organizer"), do: "badge-info"
  defp participant_role_badge("disqualified"), do: "badge-error"
  defp participant_role_badge("volunteer"), do: "badge-warning"
  defp participant_role_badge(_), do: "badge-ghost"

  defp participant_role_tint("participant"), do: "bg-success/20"
  defp participant_role_tint("organizer"), do: "bg-info/20"
  defp participant_role_tint("volunteer"), do: "bg-warning/20"
  defp participant_role_tint(_), do: "bg-base-300/20"
end
