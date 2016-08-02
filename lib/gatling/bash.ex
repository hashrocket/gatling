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

  if Mix.env == :test do
    #ignore commands in test
    def bash("nginx", _, _), do: Mix.Shell.IO.info "Nginx command"
    def bash("service", _, _), do: Mix.Shell.IO.info "Service command"
    def bash("update-rc.d", _, _), do: Mix.Shell.IO.info "Update-rc.d command"
  end

  def bash(command, args, opts) do
    default_options = [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
    {message, opts} = Keyword.pop(opts, :message)
    options         = Keyword.merge(default_options, opts)

    if message, do: log(message)
    System.cmd(command, args, options) |> elem(0)
  end

end
