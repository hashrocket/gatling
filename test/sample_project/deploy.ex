defmodule Gatling.Deploy do
  def before_mix_deps_get(env) do
    IO.puts "Hello"
  end

  def after_mix_deps_get(env) do
    IO.puts "Hello"
    env
  end
end
