defmodule Gatling.Bash do
  def log(message) do
    Mix.Shell.IO.info(message)
    message
  end

  def bash(command, args) do
    bash(command, args, [])
  end

  if Mix.env == :test do
    #ignore commands in test
    def bash("nginx", _, _), do: Mix.Shell.IO.info "Nginx command"
    def bash("service", _, _), do: Mix.Shell.IO.info "Service command"
    def bash("update-rc.d", _, _), do: Mix.Shell.IO.info "Update-rc.d command"
  end

  def bash(command, args, opts) do
    options = [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
              |> Keyword.merge(opts)

    message = if opts[:cd] do
      ["$", command | args ] ++ ["(#{opts[:cd]})"]
    else
      ["$", command | args]
    end

    log Enum.join(message, " ")
    System.cmd(command, args, options)
  end

end
