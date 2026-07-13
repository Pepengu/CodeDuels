defmodule CodeDuelsWeb.Helpers.TableHelpers do
  def current_user_class(base_class, highlight?) do
    if highlight? do
      List.wrap(base_class) ++ ["bg-yellow-500/10"]
    else
      List.wrap(base_class)
    end
  end
end
