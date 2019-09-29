defmodule Wechat.Access do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com/cgi-bin"
  plug Tesla.Middleware.JSON

  @app_id Application.get_env(:wechat, :app_id)
  @app_secret Application.get_env(:wechat, :app_secret)

  def get_token() do
    query_params = [
      grant_type: "client_credential",
      appid: @app_id,
      secret: @app_secret
    ]

    with {:ok, %Tesla.Env{body: %{"access_token" => access_token}}} <-
           get("/token", query: query_params) do
      {:ok, access_token}
    else
      _ -> :error
    end
  end

end
