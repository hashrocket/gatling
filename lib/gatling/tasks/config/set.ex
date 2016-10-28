defmodule Mix.Tasks.Gatling.Config.Set do
  use Mix.Task
  import Gatling.Bash

  @moduledoc """
  Set Environment variables for the given project

  This mix task is for setting environment variables in a given Gatling
  project.

  ## Example

  ```
  mix gatling.config.set <project> --DATABASE_PASSWORD=password  --api-url=http://example.com

  #=> Updated Config for <project> (~/deployments/<project>/.env):
      DATABASE_PASSWORD=password
      API_URL=http://example.com
  ```
  """
  @shortdoc "Set Environment Variables For a Project"

  @type gatling_env :: %Gatling.Env{}
  @type project :: binary()

  @spec run([project]) :: gatling_env
  @doc """
  The main function of `Mix.Tasks.Gatling.Config.Set`
  """
  def run([project | options]) do
    config_path = Gatling.Utilities.config_path(project)

    file = config_from_file(config_path)
            |> Keyword.merge(config_from_options(options))
            |> List.keysort(0)
            |> Enum.map_join("\n", &export_statement/1)

    File.write(config_path, file)
    log("Updated Config for #{project} (#{config_path}):")
    log(file)
  end

  defp config_from_file(path) do
    case File.read(path) do
      {:error, _} -> []
      {:ok, file} ->
        tokens = Regex.scan(~r/\w+\s*=\s*\w+/, file)
        tokens
        |> List.flatten
        |> Enum.map(&to_env_tuple/1)
    end
  end

  defp config_from_options(options) do
    options
    |> OptionParser.parse()
    |> elem(0)
    |> Enum.map(&to_env_tuple/1)
  end

  defp export_statement({key, value}) do
    key = key |> to_string()
    "#{key}=#{value}"
  end

  defp to_env_tuple({key, value}) do
    key = key |> to_string() |> String.upcase() |> String.to_atom()
    { key, value }
  end

  defp to_env_tuple(string) when is_binary(string) do
    [key, value] = string |> String.replace(" ", "") |> String.split("=")
    { String.to_atom(key), value }
  end

end
