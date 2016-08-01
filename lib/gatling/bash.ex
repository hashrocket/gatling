defmodule Gatling.Bash do
  require Logger

  def log({message, _}) do
    message = String.trim(message)
    Mix.Shell.IO.info(message)
    message
  end

  def log(message) do
    Mix.Shell.IO.info(message)
    message
  end

  def bash(command, args, opts\\[]) do
    default_options = [stderr_to_stdout: true]
    {message, opts} = Keyword.pop(opts, :message)
    options         = Keyword.merge(default_options, opts)

    if message, do: log(message)
    try do
      System.cmd(command, args, options) |> log()
    rescue
      _ -> Logger.warn ~s[Command "#{command}" not found]
    end
  end

end
