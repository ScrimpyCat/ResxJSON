defmodule ResxJSON.EncoderTest do
    use ExUnit.Case

    test "media types" do
        assert ["application/json"] == (Resx.Resource.open!(~S(data:application/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/json"] == (Resx.Resource.open!(~S(data:application/json-seq,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/geo+json"] == (Resx.Resource.open!(~S(data:application/geo+json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["application/geo+json"] == (Resx.Resource.open!(~S(data:application/geo+json-seq,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type

        assert ["json/json"] == (Resx.Resource.open!(~S(data:json/json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert ["json/json"] == (Resx.Resource.open!(~S(data:json/json+json,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
        assert { :error, { :internal, "Invalid resource type" } } = (Resx.Resource.open!(~S(data:json/jsons,{})) |> Resx.Resource.transform(ResxJSON.Encoder))
        assert { :error, { :internal, "Invalid resource type" } } == (Resx.Resource.open!(~S(data:json/json+jsons,{})) |> Resx.Resource.transform(ResxJSON.Encoder))

        Application.put_env(:resx_json, :json_types, [{ "json/jsons", "foo", :json }])
        Application.put_env(:resx_json, :native_types, [{ "foo", &(&1), &(&1) }])
        assert ["json"] == (Resx.Resource.open!(~S(data:json/jsons,{})) |> Resx.Resource.transform!(ResxJSON.Decoder) |> Resx.Resource.transform!(ResxJSON.Encoder)).content.type
    end
end
