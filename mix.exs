defmodule Ello.EventStream.Mixfile do
  use Mix.Project

  def project do
    [app: :ello_event_stream,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Ello.EventStream.Application, []}]
  end

  defp deps do
    [
      {:erlavro, git: "https://github.com/klarna/erlavro"},
      {:gen_stage, "~> 0.11"},
      {:ex_aws, "~> 1.1.2"},
      {:poison, "~> 2.0"},
      {:hackney, "~> 1.6"},
    ]
  end
end
