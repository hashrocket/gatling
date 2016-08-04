defmodule Gatling.Tasks.LoadTest do
  use ExUnit.Case, async: true

  def setup do
    on_exit fn-> File.rm_rf("test/root") end
    :ok
  end

  test ".run" do
    Mix.Tasks.Gatling.Load.run(["test_project"])
    expected_path = "test/root/home/ubuntu/test_project"
    expected_git_hook =  "test/root/home/ubuntu/test_project/.git/hooks/post-update"
    assert File.exists?(expected_path)
    assert File.exists?(expected_git_hook)
  end

end
