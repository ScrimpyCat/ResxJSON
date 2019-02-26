defmodule ResxJSON.Decoder do
    @moduledoc """
      Decode JSON string resources into erlang terms.

      ### Media Types

      Only JSON types are valid. This can either be a JSON subtype or suffix.

      Valid: `application/json`, `application/geo+json`, `application/json-seq`
      If an error is being returned when attempting to open a data URI due to
      `{ :invalid_reference, "invalid media type: \#{type}" }`, the MIME type
      will need to be added to the config.

      To add additional media types to be decoded, that can be done by configuring
      the `:json_types` option.

        config :resx_json,
            json_types: [
                { "application/x.my-type", "application/x.erlang.native", :json }
            ]

      The `:json_types` field should contain a list of 3 element tuples with the
      format `{ pattern :: String.pattern | Regex.t, replacement :: String.t, decoder :: :json | :json_seq }`.

      The `pattern` and `replacement` are arguments to `String.replace/3`. While the
      decoder specifies the JSON decoder to be used. The current decoder are:

      * `:json` - Decodes standard JSON using the `Jaxon` library (see `Jaxon.Stream.query/2`).
      * `:json_seq` - Decodes [JSON text sequences](https://tools.ietf.org/html/rfc7464) using the `Jaxon` library (see `Jaxon.Stream.query/2`).

      The replacement becomes the new media type of the transformed resource. Nested
      media types will be preserved. By default the current matches will be replaced
      (where the `json` type part is), with `x.erlang.native`, in order to denote
      that the content is now a native erlang type. If this behaviour is not desired
      simply override the match with `:json_types` for the media types that should
      not be handled like this.

      ### Query

      A query can be performed in the transformation, to only return a resource with
      the result of that query. The query format is either a string (`Jaxon.Path`) or
      a regular query as expected by `Jaxon.Stream.query/2`.

        Resx.Resource.transform(resource, ResxJSON.Decoder, query: "[*].foo")
    """
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

    defp convert_sequence_to_array(indexes, sequence, first, index \\ 0)
    defp convert_sequence_to_array([], sequence, _, _), do: sequence
    defp convert_sequence_to_array([[{ start, 1 }]|indexes], sequence, false, index) do
        part_length = start - index
        case sequence do
            <<part :: binary-size(part_length), "\x1e", sequence :: binary>> -> [part, ","|convert_sequence_to_array(indexes, sequence, false, start + 1)]
            <<part :: binary-size(part_length), "\n", sequence :: binary>> -> [part|convert_sequence_to_array(indexes, sequence, false, start + 1)]
        end
    end
    defp convert_sequence_to_array([[{ start, 1 }]|indexes], sequence, true, index) do
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
            { [String.replace(type, match, replacement)|types], decoder }
        else
            validate_type(type_list, matches)
        end
    end
end
