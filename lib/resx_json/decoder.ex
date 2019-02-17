defmodule ResxJSON.Decoder do
    use Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        case format_query(opts[:query]) do
            { :ok, query } ->
                case validate_type(content.type) do
                    { :ok, type } ->
                        content = Content.Stream.new(content)
                        { :ok, %{ resource | content: %{ content | type: type, data: Content.Stream.new(content) |> Jaxon.Stream.query(query) } } }
                    error -> error
                end
            { :error, error } -> { :error, { :internal, "Invalid query format: " <> error.message } }
        end
    end

    defp format_query(nil), do: { :ok, [:root] }
    defp format_query(query) when is_list(query), do: { :ok, query }
    defp format_query(query), do: Jaxon.Path.parse(query)

    @default_json_types [
        { ~r/\/(json(\+json)?|(.*?\+)json)(;|$)/, "/\\3x.erlang.native\\4" },
    ]
    defp validate_type([type|types]) do
        cond do
            new_type = validate_type(type, Application.get_env(:resx_json, :json_types, [])) -> { :ok, [new_type|types] }
            new_type = validate_type(type, @default_json_types) -> { :ok, [new_type|types] }
            true -> { :error, { :internal, "Invalid resource type" } }
        end
    end

    defp validate_type(_, []), do: nil
    defp validate_type(type, [{ match, replacement }|matches]) do
        if type =~ match do
            String.replace(type, match, "/\\3x.erlang.native\\4")
        else
            validate_type(type, matches)
        end
    end
end
