defmodule Gatling.Call do
  defmacro __using__(_) do
    quote do

      def call(env, action) do
        callback(env, action, :before)
        apply(__MODULE__, action, [env])
        callback(env, action, :after)
        env
      end

      def callback(env, type, action) do
        module          = env.deploy_callback_module
        callback_action = callback_action(type, action)

        if function_exported?(module, callback_action, 1) do
          apply(module, callback_action, [env])
        end

        nil
      end

      def callback_action(type, action) do
        [type, action]
        |> Enum.map(&to_string/1)
        |> Enum.join("_")
        |> String.to_atom()
      end

    end
  end
end
