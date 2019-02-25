defmodule ResxJSON.Encoder do
    use Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        case opts[:format] || :json do
            :json ->
                case validate_type(content.type, "json") do
                    { :ok, { type, encoder } } ->
                        content = Content.Stream.new(Callback.call(encoder, [content]))
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
        Stream.transform(nodes, previous, fn
            node, acc ->
                { json, acc } = encode(node, acc)
                { [json], acc }
        end)
    end
    defp encode(data, { previous, _ }), do: { previous <> Poison.encode!(data), { ",", false } }

    def encode(data) do
        Stream.transform(data, { "", false }, fn
            node, acc ->
                { json, acc } = encode(node, acc)
                { [json], acc }
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
    defp validate_type(type_list = [type|types], [{ match, replacement, encoder }|matches], format) do
        if type =~ match do
            { [String.replace(type, match, Callback.call(replacement, [format]))|types], encoder }
        else
            validate_type(type_list, matches, format)
        end
    end
end
