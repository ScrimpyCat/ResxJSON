defmodule ResxJSON.Partial do
    @moduledoc """
      Functions that can be used to build partials for a partial stream will be
      processed by `ResxJSON.Encoder`.
    """

    defstruct [literal: "", separator: "", element: true, prefix: "", suffix: "", end: false]

    @doc """
      Create part of a JSON string value.

      A stream containing the following list of partials will result in the
      string `"\"abcd\""`.

        [ResxJSON.Partial.value("a"), ResxJSON.Partial.value(["b", "c"]), ResxJSON.Partial.value("d", :end)] #=> "\"abcd\""
    """
    def value(data), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\"" }
    def value(data, :end), do: %__MODULE__{ literal: to_string(data), separator: ",", prefix: "\"", suffix: "\"", end: true }

    @doc """
      Create part of a JSON object key.

      A stream containing the following list of partials will result in the
      key `"\"abcd\":"`.

        [ResxJSON.Partial.key("a"), ResxJSON.Partial.key(["b", "c"]), ResxJSON.Partial.key("d", :end)] #=> "\"abcd\":"

      This should be used inside an object (`ResxJSON.Partial.object/0`) and should
      be followed by a value (literal or partial) that will become the value for
      that key.
    """
    def key(data), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\":" }
    def key(data, :end), do: %__MODULE__{ literal: to_string(data), prefix: "\"", suffix: "\":", end: true }

    @doc """
      Create part of a JSON array.

      A stream containing the following list of partials will result in the
      array `"[]"`.

        [ResxJSON.Partial.array(), ResxJSON.Partial.array(:end)] #=> "[]"

      Any elements between the two array functions will be put inside the resulting
      array.
    """
    def array(), do: %__MODULE__{ literal: "[", end: true }
    def array(:end), do: %__MODULE__{ literal: "]", separator: ",", element: false, end: true }

    @doc """
      Create part of a JSON object.

      A stream containing the following list of partials will result in the
      object `"{}"`.

        [ResxJSON.Partial.object(), ResxJSON.Partial.object(:end)] #=> "{}"

      Any key/value pairs between the two object functions will be put inside the
      resulting object. Keys should be referenced with by `ResxJSON.Partial.key/1`,
      while values may be partials or literals.
    """
    def object(), do: %__MODULE__{ literal: "{", end: true }
    def object(:end), do: %__MODULE__{ literal: "}", separator: ",", element: false, end: true }
end
