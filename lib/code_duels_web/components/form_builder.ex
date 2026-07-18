defmodule CodeDuelsWeb.FormBuilder do
  @moduledoc """
  A declarative form builder that renders fields from a definition list and validates them.

  ## Usage

  Define fields as a list of maps, each with a `:type` key:

      fields = [
        %{name: :email, type: :text, label: "Email", required: true},
        %{name: :phone, type: :phone, label: "Phone"},
        %{
          type: :checkbox,
          label_prefix: "I agree to the ",
          link_text: "terms",
          link_url: "/terms",
          required: true
        }
      ]

  Render in a template:

      <.form_fields form={@form} fields={fields} />

  Validate on submit:

      case FormBuilder.validate(params, fields) do
        :ok -> # proceed
        {:error, form} -> assign(socket, form: form)
      end

  ## Field types

  | Type | Description |
  |------|-------------|
  | `:text` | Text input. See options below. |
  | `:phone` | Two-part input (country code + masked body). |
  | `:select` | Dropdown select. |
  | `:group` | Groups child fields in a bordered box. |
  | `:toggle` | Radio toggle that shows/hides sections. |
  | `:info` | Read-only informational box. |
  | `:checkbox_group` | Grid of checkbox groups with headers. |
  | `:checkbox` | Checkbox with linked label text. |

  ## Common field options

    - `name` — atom, optional. Auto-generated from `:type` if omitted (unique per form).
    - `:type` — atom, required. One of the supported types.
    - `:required` — boolean, optional. Adds a required validation.
    - `:validate` — `(String.t() -> :ok | {:error, String.t()})`, optional. Custom format validation called when the value is non-empty.

  ## Type-specific options

  ### `:text`

    - `:input_type` — HTML input type, default `"text"`. Use `"email"`, `"url"`, etc. for browser-native validation/keyboards.
    - `:label` — label text.
    - `:placeholder` — placeholder text.

  ### `:phone`

    - `:label` — label text, default `"Телефон"`.
    - `:default_code` — default country code, default `"+7"`.

  ### `:select`

    - `:label` — label text.
    - `:prompt` — placeholder prompt shown when nothing is selected.
    - `:options` — list of option strings.

  ### `:group`

    - `:label` — group label text.
    - `:hint` — hint text shown below the group.
    - `:children` — list of child field maps.
    - `:required` — when true, validates at least one child is filled.

  ### `:toggle`

    - `:label` — label text.
    - `:options` — list of `{label, value}` tuples for toggle options.
    - `:sections` — map of `value` → list of child field maps shown when that option is selected.

  ### `:info`

    - `:text` — informational text. Supports newlines.

  ### `:checkbox_group`

    - `:label` — label text.
    - `:hint` — hint text shown below.
    - `:groups` — list of `%{label: String.t(), prefix: String.t(), count: pos_integer()}`.

  ### `:checkbox`

    - `:label_prefix` — text before the link.
    - `:link_text` — link text (e.g. "terms").
    - `:link_url` — URL the link points to.
    - `:label_suffix` — text after the link.
  """

  use Phoenix.Component
  import CodeDuelsWeb.CoreComponents

  def validate(params, fields) do
    fields = assign_names(fields)

    missing_errors =
      fields
      |> flatten_fields_active(params)
      |> Enum.filter(& &1[:required])
      |> Enum.filter(fn field ->
        value = get_field_value(params, field)
        is_nil(value) or value == ""
      end)
      |> Enum.map(&{&1.name, {"Обязательное поле", []}})

    group_errors =
      fields
      |> Enum.filter(& &1[:children])
      |> Enum.filter(fn field ->
        field.children
        |> Enum.all?(fn child ->
          value = get_field_value(params, child)
          is_nil(value) or value == ""
        end)
      end)
      |> Enum.map(&{&1.name, {"Обязательное поле", []}})

    format_errors =
      fields
      |> flatten_fields_active(params)
      |> Enum.flat_map(fn
        %{type: :phone} = field ->
          code = Map.get(params, "phone_code", "")
          body = Map.get(params, "phone_body", "")

          cond do
            code == "" or body == "" ->
              []

            not Regex.match?(~r/^\+\d{1,4}$/, code) ->
              [{field.name, {"Неверный код страны", []}}]

            not Regex.match?(~r/^\(\d{3}\) \d{3}-\d{2}-\d{2}$/, body) ->
              [{field.name, {"Формат: (999) 123-45-67", []}}]

            true ->
              []
          end

        %{validate: validate_fn} = field when is_function(validate_fn, 1) ->
          value = get_field_value(params, field)

          if value != "" do
            case validate_fn.(value) do
              :ok -> []
              {:error, msg} -> [{field.name, {msg, []}}]
            end
          else
            []
          end

        _ ->
          []
      end)

    all_errors = missing_errors ++ group_errors ++ format_errors

    if all_errors == [] do
      :ok
    else
      {:error, to_form(params, as: :form, errors: all_errors, action: :validate)}
    end
  end

  defp get_field_value(params, %{type: :phone}) do
    code = Map.get(params, "phone_code", "")
    body = Map.get(params, "phone_body", "")
    if code != "" and body != "", do: code <> " " <> body, else: ""
  end

  defp get_field_value(params, field) do
    Map.get(params, to_string(field.name))
  end

  attr :form, :any, required: true
  attr :fields, :list, required: true

  def form_fields(assigns) do
    fields = assign_names(assigns.fields)
    assigns = assign(assigns, :fields, fields)

    ~H"""
    <div class="space-y-6">
      <%= for field <- @fields do %>
        <.render_field form={@form} field={field} />
      <% end %>
    </div>
    """
  end

  def assign_names(fields) do
    all_fields = flatten_fields(fields)

    unnamed_by_type =
      all_fields
      |> Enum.reject(&Map.has_key?(&1, :name))
      |> Enum.frequencies_by(& &1.type)

    {fields, _} = do_assign_names(fields, unnamed_by_type, %{})
    fields
  end

  defp flatten_fields(fields) do
    Enum.flat_map(fields, fn field ->
      [field | flatten_fields(field_children(field))]
    end)
  end

  defp flatten_fields_active(fields, params) do
    Enum.flat_map(fields, fn field ->
      children =
        case field do
          %{type: :toggle, sections: sections} ->
            current_value = to_string(Map.get(params, to_string(field.name), "yes"))
            Map.get(sections, current_value, [])

          _ ->
            field_children(field)
        end

      [field | flatten_fields_active(children, params)]
    end)
  end

  defp field_children(%{type: :group, children: c}), do: c

  defp field_children(%{type: :toggle, sections: s}) when is_map(s),
    do: s |> Map.values() |> List.flatten()

  defp field_children(_), do: []

  defp do_assign_names(fields, unnamed_by_type, counters) do
    Enum.map_reduce(fields, counters, fn field, counters ->
      {processed_children, counters} =
        field
        |> field_children()
        |> do_assign_names(unnamed_by_type, counters)

      field = rebuild_children(field, processed_children)

      if Map.has_key?(field, :name) do
        {field, counters}
      else
        count = Map.fetch!(unnamed_by_type, field.type)
        {name, counters} = generate_name(field.type, count, counters)
        {Map.put(field, :name, name), counters}
      end
    end)
  end

  defp generate_name(type, 1, counters), do: {type, counters}

  defp generate_name(type, _count, counters) do
    num = Map.get(counters, type, 0) + 1
    {String.to_atom("#{type}-#{num}"), Map.put(counters, type, num)}
  end

  defp rebuild_children(%{type: :group} = field, children), do: %{field | children: children}

  defp rebuild_children(%{type: :toggle, sections: sections} = field, new_children) do
    {_, new_sections} =
      Enum.reduce(sections, {new_children, %{}}, fn {key, section_children}, {remaining, acc} ->
        {taken, rest} = Enum.split(remaining, length(section_children))
        {rest, Map.put(acc, key, taken)}
      end)

    %{field | sections: new_sections}
  end

  defp rebuild_children(field, _), do: field

  defp render_field(%{field: %{type: :checkbox}} = assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <input
        type="checkbox"
        name={@form[@field.name].name}
        value="true"
        class="checkbox checkbox-sm"
      />
      <span class="text-sm">
        {@field[:label_prefix] || ""}
        <a href={@field[:link_url] || "#"} class="link link-primary" target="_blank">
          {@field[:link_text] || ""}
        </a>
        {@field[:label_suffix] || ""}
      </span>
    </div>
    """
  end

  defp render_field(%{field: %{type: :text}} = assigns) do
    assigns =
      assign_new(assigns, :input_type, fn -> to_string(assigns.field[:input_type] || "text") end)

    ~H"""
    <.input
      field={@form[@field.name]}
      type={@input_type}
      label={@field[:label] || ""}
      placeholder={@field[:placeholder]}
      required={@field[:required]}
    />
    """
  end

  defp render_field(%{field: %{type: :phone}} = assigns) do
    assigns =
      assigns
      |> assign_new(:phone_label, fn -> assigns.field[:label] || "Телефон" end)
      |> assign_new(:phone_default_code, fn -> assigns.field[:default_code] || "+7" end)

    ~H"""
    <div>
      <label class="label text-sm font-medium mb-1">{@phone_label}</label>
      <div class="flex gap-2 items-center">
        <input
          type="text"
          name="form[phone_code]"
          id="phone-code"
          value={@phone_default_code}
          list="phone-country-codes"
          phx-hook="PhoneCodeHook"
          class="input input-bordered w-24 text-sm"
          placeholder="+7"
        />
        <datalist id="phone-country-codes">
          <option value="+7">Россия</option>
          <option value="+1">США / Канада</option>
          <option value="+44">Великобритания</option>
          <option value="+49">Германия</option>
          <option value="+33">Франция</option>
          <option value="+34">Испания</option>
          <option value="+39">Италия</option>
          <option value="+31">Нидерланды</option>
          <option value="+32">Бельгия</option>
          <option value="+41">Швейцария</option>
          <option value="+43">Австрия</option>
          <option value="+48">Польша</option>
          <option value="+420">Чехия</option>
          <option value="+36">Венгрия</option>
          <option value="+40">Румыния</option>
          <option value="+385">Хорватия</option>
          <option value="+381">Сербия</option>
          <option value="+386">Словения</option>
          <option value="+387">Босния и Герцеговина</option>
          <option value="+389">Северная Македония</option>
          <option value="+355">Албания</option>
          <option value="+359">Болгария</option>
          <option value="+30">Греция</option>
          <option value="+358">Финляндия</option>
          <option value="+46">Швеция</option>
          <option value="+47">Норвегия</option>
          <option value="+45">Дания</option>
          <option value="+370">Литва</option>
          <option value="+371">Латвия</option>
          <option value="+372">Эстония</option>
          <option value="+375">Беларусь</option>
          <option value="+380">Украина</option>
          <option value="+373">Молдова</option>
          <option value="+374">Армения</option>
          <option value="+994">Азербайджан</option>
          <option value="+995">Грузия</option>
          <option value="+992">Таджикистан</option>
          <option value="+993">Туркменистан</option>
          <option value="+996">Кыргызстан</option>
          <option value="+998">Узбекистан</option>
          <option value="+86">Китай</option>
          <option value="+81">Япония</option>
          <option value="+82">Южная Корея</option>
          <option value="+886">Тайвань</option>
          <option value="+91">Индия</option>
          <option value="+92">Пакистан</option>
          <option value="+90">Турция</option>
          <option value="+98">Иран</option>
          <option value="+966">Саудовская Аравия</option>
          <option value="+971">ОАЭ</option>
          <option value="+972">Израиль</option>
          <option value="+880">Бангладеш</option>
          <option value="+94">Шри-Ланка</option>
          <option value="+95">Мьянма</option>
          <option value="+66">Таиланд</option>
          <option value="+60">Малайзия</option>
          <option value="+62">Индонезия</option>
          <option value="+63">Филиппины</option>
          <option value="+65">Сингапур</option>
          <option value="+84">Вьетнам</option>
          <option value="+855">Камбоджа</option>
          <option value="+856">Лаос</option>
          <option value="+977">Непал</option>
          <option value="+55">Бразилия</option>
          <option value="+52">Мексика</option>
          <option value="+54">Аргентина</option>
          <option value="+56">Чили</option>
          <option value="+57">Колумбия</option>
          <option value="+61">Австралия</option>
          <option value="+64">Новая Зеландия</option>
        </datalist>
        <input
          type="text"
          name="form[phone_body]"
          id="phone-body"
          phx-hook="PhoneMaskHook"
          class="input input-bordered flex-1 text-sm"
          placeholder="(999) 123-45-67"
        />
      </div>
      <%= for {msg, _opts} <- @form[@field.name].errors do %>
        <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
          <.icon name="hero-exclamation-circle" class="size-5" />
          {msg}
        </p>
      <% end %>
    </div>
    """
  end

  defp render_field(%{field: %{type: :info}} = assigns) do
    ~H"""
    <div class="flex gap-3 items-start p-4 rounded-lg border border-form bg-info/10 text-sm text-base-content/80 ">
      <.icon name="hero-information-circle" class="size-5 text-info shrink-0 mt-0.5" />
      <span class="whitespace-pre-line">{@field.text}</span>
    </div>
    """
  end

  defp render_field(%{field: %{type: :group}} = assigns) do
    ~H"""
    <div>
      <label class="label text-sm font-medium mb-1">{@field.label}</label>
      <div class={[
        "border rounded-lg py-4 px-3 space-y-4",
        @form[@field.name].errors != [] && "border-error",
        @form[@field.name].errors == [] && "border-form"
      ]}>
        <%= for child <- @field.children do %>
          <.render_field form={@form} field={child} />
        <% end %>
      </div>
      <%= for {msg, _opts} <- @form[@field.name].errors do %>
        <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
          <.icon name="hero-exclamation-circle" class="size-5" />
          {msg}
        </p>
      <% end %>
      <%= if @field[:hint] do %>
        <div class="label">
          <span class="label-text-alt opacity-50">{@field.hint}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_field(%{field: %{type: :select}} = assigns) do
    ~H"""
    <.input
      field={@form[@field.name]}
      type="select"
      label={@field.label}
      prompt={@field[:prompt]}
      options={@field.options}
    />
    """
  end

  defp render_field(%{field: %{type: :toggle}} = assigns) do
    current_value = to_string(assigns.form[assigns.field.name].value || "yes")
    children = Map.get(assigns.field[:sections] || %{}, current_value, [])
    assigns = assign(assigns, :current_value, current_value) |> assign(:children, children)

    ~H"""
    <div>
      <label class="label text-sm font-medium mb-1">{@field.label}</label>
      <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
        <div class={[
          "absolute w-1/2 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 transition-[left]",
          @current_value != "no" && "left-0",
          @current_value == "no" && "left-1/2"
        ]} />
        <%= for {label, value} <- @field.options do %>
          <label class="flex p-2 cursor-pointer w-1/2 justify-center items-center gap-2 relative z-10">
            <input
              type="radio"
              class="sr-only"
              name={"form[#{@field.name}]"}
              value={value}
              checked={@current_value == value}
            />
            <span class={[
              "text-sm transition-opacity",
              @current_value == value && "opacity-100",
              @current_value != value && "opacity-75"
            ]}>
              {label}
            </span>
          </label>
        <% end %>
      </div>
      <%= if length(@children) > 1 do %>
        <div class="border rounded-lg py-4 px-3 space-y-4 border-form mt-4">
          <%= for child <- @children do %>
            <.render_field form={@form} field={child} />
          <% end %>
        </div>
      <% else %>
        <%= for child <- @children do %>
          <div class="space-y-4 border-form mt-4">
            <%= for child <- @children do %>
              <.render_field form={@form} field={child} />
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_field(%{field: %{type: :checkbox_group}} = assigns) do
    total = Enum.sum(Enum.map(assigns.field.groups, & &1.count))
    last_idx = length(assigns.field.groups) - 1
    assigns = assign(assigns, :total, total) |> assign(:last_idx, last_idx)

    ~H"""
    <div>
      <label class="label text-sm font-medium mb-1">{@field.label}</label>

      <div class={[
        "border rounded-lg py-4 px-3",
        @form[@field.name].errors != [] && "border-error",
        @form[@field.name].errors == [] && "border-form"
      ]}>
        <div class="grid mb-3" style={"grid-template-columns: repeat(#{@total}, 1fr)"}>
          <%= for {group, idx} <- Enum.with_index(@field.groups) do %>
            <div
              class={[
                "text-center",
                idx < @last_idx && "border-r border-base-content/10"
              ]}
              style={"grid-column: span #{group.count}"}
            >
              <span class="text-xs sm:text-sm font-medium opacity-70 whitespace-nowrap">
                {group.label}
              </span>
            </div>
          <% end %>
        </div>

        <div class="grid items-end" style={"grid-template-columns: repeat(#{@total}, 1fr)"}>
          <%= for {group, idx} <- Enum.with_index(@field.groups) do %>
            <div
              class={[
                "flex justify-center gap-1 sm:gap-3 flex-wrap",
                idx < @last_idx && "border-r border-base-content/10"
              ]}
              style={"grid-column: span #{group.count}"}
            >
              <%= for i <- 1..group.count do %>
                <label class="flex flex-col items-center gap-1 cursor-pointer select-none px-1">
                  <span class="text-xs opacity-60 font-mono">{i}</span>
                  <input
                    type="checkbox"
                    class="checkbox checkbox-sm"
                    name={"form[#{@field.name}]"}
                    value={"#{group.prefix}-#{i}"}
                    checked={@form[@field.name].value == "#{group.prefix}-#{i}"}
                  />
                </label>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%= for {msg, _opts} <- @form[@field.name].errors do %>
        <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
          <.icon name="hero-exclamation-circle" class="size-5" />
          {msg}
        </p>
      <% end %>

      <%= if @field[:hint] do %>
        <div class="label">
          <span class="label-text-alt opacity-50">
            {@field.hint}
          </span>
        </div>
      <% end %>
    </div>
    """
  end
end
