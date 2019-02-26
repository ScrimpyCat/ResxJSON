defmodule ResxJSON.Partial.Sequence do
    @moduledoc """
      This struct can be used to group a batch of partials in a partial stream
      that will be processed by `ResxJSON.Encoder`.

        %ResxJSON.Partial.Sequence{
            nodes: [
                %ResxJSON.Partial.key("foo"),
                "bar",
            ]
        }
    """

    defstruct [nodes: []]
end
