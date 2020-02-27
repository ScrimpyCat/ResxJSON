defmodule ResxJSON.MixProject do
    use Mix.Project

    def project do
        [
            app: :resx_json,
            description: "JSON encoding/decoding transformer for the resx library",
            version: "0.2.1",
            elixir: "~> 1.7",
            start_permanent: Mix.env() == :prod,
            deps: deps(),
            dialyzer: [plt_add_deps: :transitive],
            package: package()
        ]
    end

    def application do
        [extra_applications: [:logger]]
    end

    defp deps do
        [
            { :resx, "~> 0.1.0" },
            { :callback, "~> 0.1.0" },
            { :jaxon, "~> 1.0" },
            { :poison, "~> 4.0" },
            { :ex_doc, "~> 0.18", only: :dev, runtime: false },
            { :simple_markdown, "~> 0.5.4", only: :dev, runtime: false },
            { :simple_markdown_extension_highlight_js, "~> 0.1.0", only: :dev, runtime: false },
            { :ex_doc_simple_markdown, "~> 0.3", only: :dev, runtime: false }
        ]
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/ResxJSON" }
        ]
    end
end
