defmodule ResxJSON.DecoderTest do
    use ExUnit.Case

    test "queries" do
        assert [%{}] == (Resx.Resource.open!(~S(data:application/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder)).content |> Resx.Resource.Content.data
        assert [%{ "a" => "foo", "b" => "bar" }] == (Resx.Resource.open!(~S(data:application/json,{"a": "foo", "b": "bar"})) |> Resx.Resource.transform!(ResxJSON.Decoder)).content |> Resx.Resource.Content.data
        assert [%{ "a" => 1, "b" => 2 }] == (Resx.Resource.open!(~S(data:application/json,{"a": 1, "b": 2})) |> Resx.Resource.transform!(ResxJSON.Decoder)).content |> Resx.Resource.Content.data
        assert [%{ "a" => [1, 2, 3], "b" => [4, 5, 6] }] == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder)).content |> Resx.Resource.Content.data
        assert [%{ "a" => %{ "x" => 1, "y" => 2 }, "b" => %{ "x" => 3, "y" => 4 } }] == (Resx.Resource.open!(~S(data:application/json,{"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})) |> Resx.Resource.transform!(ResxJSON.Decoder)).content |> Resx.Resource.Content.data

        assert [%{}] == (Resx.Resource.open!(~S(data:application/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root])).content |> Resx.Resource.Content.data
        assert [%{ "a" => "foo", "b" => "bar" }] == (Resx.Resource.open!(~S(data:application/json,{"a": "foo", "b": "bar"})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root])).content |> Resx.Resource.Content.data
        assert [%{ "a" => 1, "b" => 2 }] == (Resx.Resource.open!(~S(data:application/json,{"a": 1, "b": 2})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root])).content |> Resx.Resource.Content.data
        assert [%{ "a" => [1, 2, 3], "b" => [4, 5, 6] }] == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root])).content |> Resx.Resource.Content.data
        assert [%{ "a" => %{ "x" => 1, "y" => 2 }, "b" => %{ "x" => 3, "y" => 4 } }] == (Resx.Resource.open!(~S(data:application/json,{"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root])).content |> Resx.Resource.Content.data

        assert [1, 2, 3] == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root, "a", :all])).content |> Resx.Resource.Content.data
        assert [4, 5, 6] == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root, "b", :all])).content |> Resx.Resource.Content.data
        assert [4] == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root, "b", 0])).content |> Resx.Resource.Content.data
        assert [%{ "x" => 1, "y" => 2 }] == (Resx.Resource.open!(~S(data:application/json,{"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root, "a"])).content |> Resx.Resource.Content.data
        assert [1] == (Resx.Resource.open!(~S(data:application/json,{"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:root, "a", "x"])).content |> Resx.Resource.Content.data
        assert [1, 2, "foo"] == (Resx.Resource.open!(~S(data:application/json,[{"a": 1}, {"a": 2}, {"a": "foo"}])) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [:all, "a"])).content |> Resx.Resource.Content.data
        assert [2] == (Resx.Resource.open!(~S(data:application/json,[{"a": 1}, {"a": 2}, {"a": "foo"}])) |> Resx.Resource.transform!(ResxJSON.Decoder, query: [1, "a"])).content |> Resx.Resource.Content.data
    end

    test "streams" do
        resource = Resx.Resource.open!(~S(data:application/json,{}))
        assert [2] == (%{ resource | content: %{ Resx.Resource.Content.Stream.new(resource.content) | data: ~W([{"a": 1}, {"a": 2}, {"a": "foo"}]) } } |> Resx.Resource.transform!(ResxJSON.Decoder, query: [1, "a"])).content |> Resx.Resource.Content.data
        assert [2] == (%{ resource | content: %{ Resx.Resource.Content.Stream.new(resource.content) | data: ~W([ { " a " : 1 } , { " a " : 2 } , { " a " : " f o o " } ]) } } |> Resx.Resource.transform!(ResxJSON.Decoder, query: [1, "a"])).content |> Resx.Resource.Content.data
    end
end
