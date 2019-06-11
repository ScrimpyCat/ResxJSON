defmodule ResxJSON.Encoder do
    @moduledoc """
      Encode data resources into strings of JSON.

      ### Media Types

      Only `x.erlang.native` types are valid. This can either be a subtype or suffix.

      Valid: `application/x.erlang.native`, `application/geo+x.erlang.native`.
      If an error is being returned when attempting to open a data URI due to
      `{ :invalid_reference, "invalid media type: \#{type}" }`, the MIME type
      will need to be added to the config.

      To add additional media types to be encoded, that can be done by configuring
      the `:native_types` option.

        config :resx_json,
            native_types: [
                { "application/x.my-type", &("application/\#{&1}"), &(&1) }
            ]

      The `:native_types` field should contain a list of 3 element tuples with the
      format `{ pattern :: String.pattern | Regex.t, (replacement_type :: String.t -> replacement :: String.t), preprocessor :: (Resx.Resource.content -> Resx.Resource.content) }`.

      The `pattern` and `replacement` are arguments to `String.replace/3`. While the
      preprocessor performs any operations on the content before it is encoded.

      The replacement becomes the new media type of the transformed resource. Nested
      media types will be preserved. By default the current matches will be replaced
      (where the `x.erlang.native` type part is), with the new type (currently `json`),
      in order to denote that the content is now a JSON type. If this behaviour is not desired
      simply override the match with `:native_types` for the media types that should
      not be handled like this.

      ### Encoding

      All literals are encoded using the `Poison` library.

      The JSON format (final encoding type) is specified when calling transform,
      by providing an atom to the `:format` option. This type is then used to infer
      how the content should be encoded, as well as what type will be used for the
      media type.

        Resx.Resource.transform(resource, ResxJSON.Encoder, format: :json)

      The current formats are:

      * `:json` - This encodes the data into standard JSON. This is the default encoding format.

      ### Partial Streams

      JSON may be built up from partial data, by using the functions provided in
      `ResxJSON.Partial`. Note that this is only applied to content streams.

      Any non-partials literals in the stream will be encoded as-is.

      A stream with the shape of:

        # assumes ResxJSON.Partial was imported
        [
            object(),
                key("f"), key("oo"), key(["ba", "r"], :end), 3,
                key("a", :end), value("b", :end),
                key("c", :end), array(),
                    object(),
                        key("foo", :end), [1, 2, 3],
                    object(:end),
                array(:end),
            object(:end)
        ]

      Will result in the following JSON (if `:json` format was used;
      whitespace/indentation was added, normally would be packed):

    ```json
    {
        "foobar": 3,
        "a": "b",
        "c": [
            {
                "foo": [1, 2, 3]
            }
        ]
    }
    ```

      #### Codepoints
      Values or keys must contain the full codepoint, partial codepoints (when
      the bytes that make up a codepoint are split) may result in an error or
      incorrect encoding.

      e.g. A stream consisting of `[value(["\\xf0\\x9f"]), value(["\\x8d\\x95"], :end)]`
      will raise an `UnicodeConversionError`, the intended character (`"🍕"`) must be
      included in the same value partial: `value(["\\xf0\\x9f", "\\x8d\\x95"], :end)`.
      However if you have two separate codepoints such as `[value(["e"]), value(["́"], :end)]`
      then this will correctly produce the intended character (`"é"`).
    """
    use Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        case opts[:format] || :json do
            :json ->
                case validate_type(content.type, "json") do
                    { :ok, { type, preprocessor } } ->
                        content = Content.Stream.new(Callback.call(preprocessor, [content]))
                        { :ok, %{ resource | content: %{ content | type: type, data: encode(content) } } }
                    error -> error
                end
            _ -> { :error, { :internal, "Unknown encoding format: #{inspect(opts[:format])}" } }
        end
    end

    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator, element: true, prefix: prefix, suffix: suffix, end: true }, { previous, false }), do: { previous <> prefix <> literal <> suffix, { separator, false } }
    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator, element: true, prefix: prefix }, { previous, false }), do: { previous <> prefix <> literal, { separator, true } }
    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator, element: true, suffix: suffix, end: true  }, { previous, true }), do: { previous <> literal <> suffix, { separator, false } }
    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator, element: true  }, { previous, true }), do: { previous <> literal, { separator, true } }
    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator, end: true }, _), do: { literal, { separator, false } }
    defp encode(%ResxJSON.Partial{ literal: literal, separator: separator }, _), do: { literal, { separator, true } }
    defp encode(%ResxJSON.Partial.Sequence{ nodes: nodes }, previous) do
        Enum.map_reduce(nodes, previous, &encode/2)
    end
    defp encode(data, { previous, _ }), do: { previous <> Poison.encode!(data), { ",", false } }

    @doc false
    def encode(data) do
        Stream.transform(data, { "", false }, fn
            node, acc ->
                case encode(node, acc) do
                    { json, acc } when is_list(json) -> { json, acc }
                    { json, acc } -> { [json], acc }
                end
        end)
    end

    defp validate_type(types, format) do
        cond do
            new_type = validate_type(types, Application.get_env(:resx_json, :native_types, []), format) -> { :ok, new_type }
            new_type = validate_type(types, [{ ~r/\/(x\.erlang\.native(\+x\.erlang\.native)?|(.*?\+)x\.erlang\.native)(;|$)/, &("/\\3#{&1}\\4"), &(&1) }], format) -> { :ok, new_type }
            true -> { :error, { :internal, "Invalid resource type" } }
        end
    end

    defp validate_type(_, [], _), do: nil
    defp validate_type(type_list = [type|types], [{ match, replacement, preprocessor }|matches], format) do
        if type =~ match do
            { [String.replace(type, match, Callback.call(replacement, [format]))|types], preprocessor }
        else
            validate_type(type_list, matches, format)
        end
    end
end
