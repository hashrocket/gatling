defmodule Gatling.Tasks.LoadTest do
  use ExUnit.Case, async: true

  import Gatling.TestHelpers

  setup do
    on_exit fn ->
      File.rm_rf("test/root")
    end

    :ok
  end

  test ".run" do
    Mix.Tasks.Gatling.Load.run(["test_project"])

    assert_exists "test/root/home/ubuntu/test_project/.git/hooks/post-update"
    assert_exists "test/root/home/ubuntu/deployments/test_project"
  end

end
