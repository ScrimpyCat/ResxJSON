defmodule ResxJSON.Decoder do
    @behaviour Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        case format_query(opts[:query]) do
            { :ok, query } ->
                content = Content.Stream.new(content)
                { :ok, %{ resource | content: %{ content | data: Content.Stream.new(content) |> Jaxon.Stream.query(query) } } }
            { :error, error } -> { :error, { :internal, "Invalid query format: " <> error.message } }
        end
    end

    defp format_query(nil), do: { :ok, [:root] }
    defp format_query(query) when is_list(query), do: { :ok, query }
    defp format_query(query), do: Jaxon.Path.parse(query)
end
