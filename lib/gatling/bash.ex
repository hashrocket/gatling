defmodule Gatling.Bash do
  def log({message, _}), do: Mix.Shell.IO.info(message |> String.trim)
  def log(message), do: Mix.Shell.IO.info(message)

  def bash(command, args, opts\\[]) do
    default_options = [stderr_to_stdout: true]
    {message, opts} = Keyword.pop(opts, :pre_message)
    options         = Keyword.merge(default_options, opts)

    if message, do: log(message)
    System.cmd(command, args, options) |> log()
  end
end
