defmodule ResxJSON.Encoder do
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
end
