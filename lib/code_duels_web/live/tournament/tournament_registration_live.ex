defmodule CodeDuelsWeb.TournamentRegistrationLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.FormBuilder
  alias CodeDuelsWeb.FormBuilder

  def fields(tournament_id) do
    [
      %{name: :surname, type: :text, label: "Фамилия", placeholder: "Иванов", required: true},
      %{name: :name, type: :text, label: "Имя", placeholder: "Иван", required: true},
      %{
        name: :middle_name,
        type: :text,
        label: "Отчество",
        placeholder: "Иванович",
        required: true
      },
      %{
        name: :is_spbu_student,
        type: :toggle,
        label: "Вы студент СПбГУ?",
        options: [{"Да", "yes"}, {"Нет", "no"}],
        sections: %{
          "yes" => [
            %{
              name: :education_course,
              type: :checkbox_group,
              label: "Курс",
              hint: "Можно выбрать только один вариант",
              groups: [
                %{label: "Бакалавриат/Специалитет", prefix: "bachelor", count: 5},
                %{label: "Магистратура", prefix: "master", count: 2},
                %{label: "Аспирантура", prefix: "phd", count: 3}
              ],
              required: true
            },
            %{
              name: :program,
              type: :text,
              label: "Направление",
              placeholder: "Прикладная математика и информатика",
              required: true
            },
            %{
              name: :faculty,
              type: :select,
              label: "Факультет",
              prompt: " - Выберите факультет - ",
              options: [
                "Биологический факультет",
                "Восточный факультет",
                "Институт «Высшая школа журналистики и массовых коммуникаций»",
                "Институт «Высшая школа менеджмента»",
                "Институт истории",
                "Институт когнитивных исследований",
                "Институт наук о Земле",
                "Институт педагогики",
                "Институт развития конкуренции и антимонопольного регулирования",
                "Институт философии",
                "Институт химии",
                "Институт теологии",
                "Математико-механический факультет",
                "Медицинский институт",
                "Факультет иностранных языков",
                "Факультет искусств",
                "Факультет математики и компьютерных наук",
                "Факультет международных отношений",
                "Факультет политологии",
                "Факультет прикладной математики — процессов управления",
                "Факультет психологии",
                "Факультет свободных искусств и наук",
                "Факультет социологии",
                "Физический факультет",
                "Филологический факультет",
                "Экономический факультет",
                "Юридический факультет"
              ],
              required: true
            }
          ],
          "no" => [
            %{
              type: :info,
              text:
                "Организатор свяжется с вами для получения паспортных данных. Пожайлуйста, убедитесь что организатор действительно может с вами связаться. Аккаунт телеграм открытый, почта и номер верные и т.д.

              Не забудьте взять паспорт на мероприятие."
            }
          ]
        }
      },
      %{
        name: :contact_info,
        type: :group,
        label: "Контактная информация",
        hint: "Укажите хотя бы один способ связи",
        children: [
          %{name: :phone, type: :phone},
          %{
            name: :email,
            type: :text,
            input_type: "email",
            label: "Email",
            placeholder: "email@example.com",
            validate: fn value ->
              if not Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, value),
                do: {:error, "Некорректный формат email"},
                else: :ok
            end
          },
          %{
            name: :telegram,
            type: :text,
            label: "Telegram",
            placeholder: "@username или t.me/username",
            validate: fn value ->
              if not Regex.match?(~r/^(@[\w]{5,32}|(https?:\/\/)?t\.me\/[\w]{5,32})$/, value),
                do: {:error, "Некорректный формат"},
                else: :ok
            end
          }
        ]
      },
      %{
        name: :has_codeforses,
        type: :toggle,
        label: "Если ли у вас аккаунт на codeforces?",
        options: [{"Да", "yes"}, {"Нет", "no"}],
        sections: %{
          "yes" => [
            %{
              name: :codeforces_handle,
              type: :text,
              label: "Ваш хэндл",
              placeholder: "handle",
              required: true
            },
            %{
              name: :codeforces_rating,
              type: :text,
              label: "Ваш рейтинг",
              placeholder: "0",
              validate: fn value ->
                case Integer.parse(value) do
                  {_, ""} -> :ok
                  _ -> {:error, "Рейтинг должен быть числом"}
                end
              end
            }
          ],
          "no" => []
        }
      },
      %{
        name: :agree_to_rules,
        type: :checkbox,
        label_prefix: "Я ознакомлен с ",
        link_text: "положением",
        link_url: "/tournament/#{tournament_id}/regulation",
        required: true
      }
    ]
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 sm:px-8 py-8 max-w-2xl">
        <.link
          navigate="/tournament/"
          class="inline-flex items-center gap-1 text-sm opacity-60 hover:opacity-100 transition-opacity mb-6"
        >
          <.icon name="hero-arrow-left" class="size-4" />
          {@tournament.name}
        </.link>

        <h1 class="text-2xl font-bold mb-6">Регистрация на турнир</h1>

        <.form for={@form} id="registration-form" phx-change="validate" phx-submit="submit" novalidate>
          <.form_fields form={@form} fields={@fields} />

          <div class="mt-4 grid grid-cols-2 gap-4 items-center">
            <.error_box message={error_message(@error)} style={error_style(@error)} />
            <div class="flex justify-end">
              <button
                type="submit"
                class="btn btn-primary px-6"
                phx-disable-with="Отправка..."
              >
                Отправить
              </button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def error_message(:none), do: ""
  def error_message(:missing_required), do: "Не все обязательные поля заполнены"
  def error_message(_), do: ""

  def error_style(:none), do: "visibility: hidden"

  def error_style(:missing_required),
    do: "background-color: var(--color-error); color: var(--color-error-content);"

  def error_style(_), do: ""

  def mount(%{"id" => id}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(id)

    form =
      %{}
      |> to_form(as: :form)

    socket =
      socket
      |> assign(:tournament, tournament)
      |> assign(:form, form)
      |> assign(:fields, fields(id))
      |> assign(:error, :none)

    {:ok, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    params =
      if params["education_course"] == "false",
        do: Map.put(params, "education_course", ""),
        else: params

    form = %{socket.assigns.form | params: params}
    {:noreply, assign(socket, form: form, error: :none)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case FormBuilder.validate(params, socket.assigns.fields) do
      :ok ->
        socket =
          socket
          |> assign(:form, to_form(params, as: :form))
          |> put_flash(:info, "Регистрация отправлена")

        {:noreply, push_navigate(socket, to: "/tournament/#{socket.assigns.tournament.id}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form, error: :missing_required)}
    end
  end
end
