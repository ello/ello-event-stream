defmodule Ello.EventStream.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Ello.EventStream.Kinesis.StreamSupervisor, []),
    ]

    opts = [strategy: :one_for_one, name: Ello.EventStream.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
