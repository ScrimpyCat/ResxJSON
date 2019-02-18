defmodule ResxJSON.Decoder do
    use Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        case format_query(opts[:query]) do
            { :ok, query } ->
                case validate_type(content.type) do
                    { :ok, { type, :json } } ->
                        content = Content.Stream.new(content)
                        { :ok, %{ resource | content: %{ content | type: type, data: content |> Jaxon.Stream.query(query) } } }
                    { :ok, { type, :json_seq } } ->
                        content = Content.Stream.new(content)
                        { :ok, %{ resource | content: %{ content | type: type, data: Stream.concat([["["], Stream.transform(content, true, &format_sequence/2), ["]"]]) |> Jaxon.Stream.query(query) } } }
                    error -> error
                end
            { :error, error } -> { :error, { :internal, "Invalid query format: " <> error.message } }
        end
    end

    defp format_query(nil), do: { :ok, [:root] }
    defp format_query(query) when is_list(query), do: { :ok, query }
    defp format_query(query), do: Jaxon.Path.parse(query)

    defp format_sequence(sequence, false), do: { [Regex.scan(~r/[\x1e\n]/, sequence, return: :index) |> convert_sequence_to_array(sequence, false) |> IO.iodata_to_binary], false }
    defp format_sequence(sequence, true) do
        Regex.scan(~r/[\x1e\n]/, sequence, return: :index)
        |> convert_sequence_to_array(sequence, true)
        |> case do
            formatted when is_list(formatted) -> { [IO.iodata_to_binary(formatted)], false }
            formatted -> { [IO.iodata_to_binary(formatted)], true }
        end
    end

    defp convert_sequence_to_array(indexes, sequence, first, index \\ 0, parts \\ [])
    defp convert_sequence_to_array([], sequence, _, _, _), do: sequence
    defp convert_sequence_to_array([[{ start, 1 }]|indexes], sequence, false, index, parts) do
        part_length = start - index
        case sequence do
            <<part :: binary-size(part_length), "\x1e", sequence :: binary>> -> [part, ","|convert_sequence_to_array(indexes, sequence, false, start + 1)]
            <<part :: binary-size(part_length), "\n", sequence :: binary>> -> [part|convert_sequence_to_array(indexes, sequence, false, start + 1)]
        end
    end
    defp convert_sequence_to_array([[{ start, 1 }]|indexes], sequence, true, index, parts) do
        part_length = start - index
        case sequence do
            <<part :: binary-size(part_length), "\x1e", sequence :: binary>> -> [part|convert_sequence_to_array(indexes, sequence, false, start + 1)]
        end
    end

    @default_json_types [
        { ~r/\/(json(\+json)?|(.*?\+)json)(;|$)/, "/\\3x.erlang.native\\4", :json },
        { ~r/\/(json-seq?|(.*?\+)json-seq)(;|$)/, "/\\2x.erlang.native\\3", :json_seq }
    ]
    defp validate_type(types) do
        cond do
            new_type = validate_type(types, Application.get_env(:resx_json, :json_types, [])) -> { :ok, new_type }
            new_type = validate_type(types, @default_json_types) -> { :ok, new_type }
            true -> { :error, { :internal, "Invalid resource type" } }
        end
    end

    defp validate_type(_, []), do: nil
    defp validate_type(type_list = [type|types], [{ match, replacement, decoder }|matches]) do
        if type =~ match do
            { [String.replace(type, match, "/\\3x.erlang.native\\4")|types], decoder }
        else
            validate_type(type_list, matches)
        end
    end
end
