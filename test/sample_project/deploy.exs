defmodule SampleProject.DeployCallbacks do
  def before_mix_deps_get(_env) do
    "before_mix_deps_get"
  end

  def after_mix_deps_get(_env) do
    "after_mix_deps_get"
  end
end
