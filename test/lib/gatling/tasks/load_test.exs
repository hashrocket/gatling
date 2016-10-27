defmodule Gatling.Tasks.LoadTest do
  use ExUnit.Case, async: true

  test ".run" do
    on_exit fn-> File.rm_rf("test/root") end

    Mix.Tasks.Gatling.Load.run(["test_project"])

    expected_git_hook =  "test/root/home/ubuntu/test_project/.git/hooks/post-update"
    expected_deploy_dir =  "test/root/home/ubuntu/deployments/test_project"

    assert File.exists?(expected_git_hook)
    assert File.exists?(expected_deploy_dir)
  end

end
