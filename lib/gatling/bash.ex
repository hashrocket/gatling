defmodule Gatling.Bash do
  def log(message) do
    Mix.Shell.IO.info(message)
    message
  end

  def bash(command, args) do
    bash(command, args, [])
  end

  if Mix.env == :test do
    # ignore commands in test
    def bash("nginx", args, _), do: Mix.Shell.IO.info "Command: nginx " <> Enum.join(args, " ")
    def bash("service", args, _), do: Mix.Shell.IO.info "Command: service " <> Enum.join(args, " ")
    def bash("systemctl", args, _), do: Mix.Shell.IO.info "Command: systemctl " <> Enum.join(args, " ")
    def bash("update-rc.d", args, _), do: Mix.Shell.IO.info "Command: update-rc.d " <> Enum.join(args, " ")

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
