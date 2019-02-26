defmodule ResxJSON.EncoderTest do
    use ExUnit.Case
    import ResxJSON.Partial

    alias ResxJSON.Partial.Sequence

    test "media types" do
        assert ["application/json"] == (Resx.Resource.open!(~S(data:application/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/json"] == (Resx.Resource.open!(~S(data:application/json-seq,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/geo+json"] == (Resx.Resource.open!(~S(data:application/geo+json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/geo+json"] == (Resx.Resource.open!(~S(data:application/geo+json-seq,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type

        assert ["json/json"] == (Resx.Resource.open!(~S(data:json/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["json/json"] == (Resx.Resource.open!(~S(data:json/json+json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type

        Application.put_env(:resx_json, :json_types, [])
        Application.put_env(:resx_json, :native_types, [])
        assert { :error, { :internal, "Invalid resource type" } } = (Resx.Resource.open!(~S(data:json/jsons,{})) |> Resx.Resource.transform(ResxJSON.Encoder))
        assert { :error, { :internal, "Invalid resource type" } } == (Resx.Resource.open!(~S(data:json/json+jsons,{})) |> Resx.Resource.transform(ResxJSON.Encoder))

        Application.put_env(:resx_json, :json_types, [{ "json/jsons", "foo", :json }])
        Application.put_env(:resx_json, :native_types, [{ "foo", &(&1), &(&1) }])
        assert ["json"] == (Resx.Resource.open!(~S(data:json/jsons,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
    end

    describe "json" do
        test "encoding" do
            assert ~S({}) == (Resx.Resource.open!(~S(data:application/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"b":"bar","a":"foo"}) == (Resx.Resource.open!(~S(data:application/json,{"a": "foo", "b": "bar"})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"b":2,"a":1}) == (Resx.Resource.open!(~S(data:application/json,{"a": 1, "b": 2})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"b":[4,5,6],"a":[1,2,3]}) == (Resx.Resource.open!(~S(data:application/json,{"a": [1, 2, 3], "b": [4, 5, 6]})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"b":{"y":4,"x":3},"a":{"y":2,"x":1}}) == (Resx.Resource.open!(~S(data:application/json,{"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S("foo") == (Resx.Resource.open!(~S(data:application/json,"foo")) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S(1) == (Resx.Resource.open!(~S(data:application/json,1 )) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([1,2,3]) == (Resx.Resource.open!(~S(data:application/json,[1, 2, 3])) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([]) == (Resx.Resource.open!(~S(data:application/json,[])) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data

            resource = %{ Resx.Resource.open!(~S(data:,{})) | content: %Resx.Resource.Content.Stream{ type: ["application/x.erlang.native"], data: [] }}
            assert "" == (resource |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([]) == (%{ resource | content: %{ resource.content | data: [array(), array(:end)] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({}) == (%{ resource | content: %{ resource.content | data: [object(), object(:end)] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S(1) == (%{ resource | content: %{ resource.content | data: [1] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S("foo") == (%{ resource | content: %{ resource.content | data: ["foo"] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"foo":"bar"}) == (%{ resource | content: %{ resource.content | data: [%{ foo: "bar" }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([1,2,3]) == (%{ resource | content: %{ resource.content | data: [[1, 2, 3]] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S("foobar") == (%{ resource | content: %{ resource.content | data: [value("f"), value("oo"), value(["ba", "r"], :end)] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([1,2,"foo",3,[4],[5],6]) == (%{ resource | content: %{ resource.content | data: [array(), 1, 2, value("fo"), value("o", :end), 3, [4], array(), 5, array(:end), 6, array(:end)] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"foobar":3,"a":"b","c":[{"foo":[1,2,3]}]}) == (%{ resource | content: %{ resource.content | data: [object(), key("f"), key("oo"), key(["ba", "r"], :end), 3, key("a", :end), value("b", :end), key("c", :end), array(), object(), key("foo", :end), [1, 2, 3], object(:end), array(:end), object(:end)] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data

            assert "" == (%{ resource | content: %{ resource.content | data: [%Sequence{}] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([]) == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [array(), array(:end)] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({}) == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [object()] }, %Sequence{ nodes: [object(:end)] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S(1) == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [1] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S("foo") == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: ["foo"] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"foo":"bar"}) == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [%{ foo: "bar" }] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([1,2,3]) == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [[1, 2, 3]] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S("foobar") == (%{ resource | content: %{ resource.content | data: [%Sequence{ nodes: [value("f"), value("oo")] }, %Sequence{ nodes: [value(["ba", "r"], :end)] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S([1,2,"foo",3,[4],[5],6]) == (%{ resource | content: %{ resource.content | data: [array(), %Sequence{ nodes: [1, 2, value("fo")] }, value("o", :end), 3, %Sequence{ nodes: [[4], array(), 5, array(:end)] }, %Sequence{ nodes: [6, array(:end)] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
            assert ~S({"foobar":3,"a":"b","c":[{"foo":[1,2,3]}]}) == (%{ resource | content: %{ resource.content | data: [object(), %Sequence{ nodes: [key("f"), key("oo")] }, key(["ba", "r"], :end), 3, key("a", :end), %Sequence{ nodes: [value("b", :end), key("c", :end), array()] }, object(), key("foo", :end), [1, 2, 3], %Sequence{ nodes: [object(:end), array(:end), object(:end)] }] } } |> Resx.Resource.transform!(ResxJSON.Encoder)).content |> Resx.Resource.Content.data
        end
    end
end
