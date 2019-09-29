defmodule Wechat.Tesla.Middleware.ForceDecodeJSON do
  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts \\ []) do
    with {:ok, env} <- Tesla.run(env, next),
         {:ok, body} <- Jason.decode(env.body) do
      {:ok, %{env | body: body}}
    end
  end
end
