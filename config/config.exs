# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :resx_json, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:resx_json, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

if Mix.env == :dev do
    import_config "simple_markdown_rules.exs"

    config :simple_markdown_extension_highlight_js,
        source: Enum.at(Path.wildcard(Path.join(Mix.Project.deps_path(), "ex_doc/formatters/html/dist/*.js")), 0, ""),
        include: ["json"]

    config :ex_doc_simple_markdown, [
        rules: fn rules ->
            :ok = SimpleMarkdownExtensionHighlightJS.setup
            rules
        end
    ]

    config :ex_doc, :markdown_processor, ExDocSimpleMarkdown
end

if Mix.env == :test do
    config :mime, :types, %{
        "application/json-seq" => [],
        "application/geo+json-seq" => [],
        "json/json" => [],
        "json/json+json" => [],
        "json/jsons" => [],
        "json/json+jsons" => []
    }
end
