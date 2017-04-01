use Mix.Config

if File.exists?("config/config.local.exs") do
  import_config "config.local.exs"
end
