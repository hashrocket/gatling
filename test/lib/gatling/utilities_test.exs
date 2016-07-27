defmodule Gatling.UtilitiesTest do
  use ExUnit.Case, async: true

  alias Gatling.Utilities

  # configured in config/test.exs
  test ".build_path" do
    expected_path = "/gatling/test/root/home/ubuntu/foo"
    regex = ~r/#{expected_path}$/
    path = Utilities.build_path("foo")
    assert Regex.match?(regex, path)
  end

  test ".deploy_dir" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/foo"
    regex = ~r/#{expected_path}$/
    path = Utilities.deploy_dir("foo")
    assert Regex.match?(regex, path)
  end

  test ".upgrade_dir" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/foo/releases/0.0.0-git1234567"
    regex = ~r/#{expected_path}$/
    path = Utilities.upgrade_dir("foo", "0.0.0-git1234567")
    assert Regex.match?(regex, path)
  end

  test ".nginx_path" do
    expected_path = "/gatling/test/root/etc/nginx"
    regex = ~r/#{expected_path}$/
    path = Utilities.nginx_path
    assert Regex.match?(regex, path)
  end

  test ".etc_path" do
    expected_path = "/gatling/test/root/etc/init.d"
    regex = ~r/#{expected_path}$/
    path = Utilities.etc_path
    assert Regex.match?(regex, path)
  end

end
