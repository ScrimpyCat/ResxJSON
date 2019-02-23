defmodule ResxJSON.Partial do
    defstruct [literal: "", separator: "", element: true, prefix: "", suffix: "", end: false]

    def value(data), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\"" }
    def value(data, :end), do: %__MODULE__{ literal: to_string(data), separator: ",", prefix: "\"", suffix: "\"", end: true }

    def key(data), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\":" }
    def key(data, :end), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\":", end: true }

    def array(), do: %__MODULE__{ literal: "[", end: true }
    def array(:end), do: %__MODULE__{ literal: "]", separator: ",", element: false, end: true }

    def object(), do: %__MODULE__{ literal: "{", end: true }
    def object(:end), do: %__MODULE__{ literal: "}", separator: ",", element: false, end: true }
end
