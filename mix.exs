defmodule ResxJSON.MixProject do
    use Mix.Project

    def project do
        [
            app: :resx_json,
            description: "JSON encoding/decoding transformer for the resx library",
            version: "0.0.3",
            elixir: "~> 1.7",
            start_permanent: Mix.env() == :prod,
            deps: deps(),
            dialyzer: [plt_add_deps: :transitive]
        ]
    end

    def application do
        [extra_applications: [:logger]]
    end

    defp deps do
        [
            { :resx, "~> 0.1.0" },
            { :jaxon, "~> 1.0" },
            { :ex_doc, "~> 0.18", only: :dev, runtime: false },
            { :simple_markdown, "~> 0.5.4", only: :dev, runtime: false },
            { :ex_doc_simple_markdown, "~> 0.3", only: :dev, runtime: false }
        ]
    end
end
