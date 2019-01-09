defmodule ResxJSON.Decoder do
    @behaviour Resx.Transformer

    alias Resx.Resource.Content

    @impl Resx.Transformer
    def transform(resource = %{ content: content }, opts) do
        content = Content.Stream.new(content)
        { :ok, %{ resource | content: %{ content | data: Content.Stream.new(content) |> Jaxon.Stream.query(opts[:query] || [:root]) } } }
    end
end
