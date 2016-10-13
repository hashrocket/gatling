defmodule SampleProject.DeployCallbacks do
  import Gatling.Bash

  def before_mix_deps_get(_env) do
    log("this happens before mix_deps_get")
    "before_mix_deps_get"
  end

  def after_mix_deps_get(_env) do
    "after_mix_deps_get"
  end
end
