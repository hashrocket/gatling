defmodule Example.Mixfile do
  use Mix.Project

  @moduledoc """
  Mix file exemplifying how one might generate the project version a commit
  """

  def project do
    [
      app: :example,
      version: "0.0.#{committed_at}",
      elixir: "~> 1.3",
    ]
  end

  @doc "Unix timestamp of the last commit."
  def committed_at do
    System.cmd("git", ~w[log -1 --date=short --pretty=format:%ct]) |> elem(0)
  end

end
