defmodule Wechat.Web do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com/sns")
  plug(Tesla.Middleware.JSON)
  plug(Wechat.Tesla.Middleware.ForceDecodeJSON)

  @app_id Application.get_env(:wechat, :app_id)
  @app_secret Application.get_env(:wechat, :app_secret)

  @spec authorise_with(String.t()) ::
          {:ok, %{access_token: String.t(), open_id: String.t(), refresh_token: String.t()}}
          | {:error, any()}
  def authorise_with(code) do
    query_params = [
      appid: @app_id,
      secret: @app_secret,
      code: code,
      grant_type: "authorization_code"
    ]

    with {:ok, %Tesla.Env{body: body, status: 200}} <-
           get("/oauth2/access_token", query: query_params) do
      case body do
        %{"access_token" => access_token, "openid" => open_id, "refresh_token" => refresh_token} ->
          {:ok,
           %{
             access_token: access_token,
             open_id: open_id,
             refresh_token: refresh_token
           }}

        %{"errcode" => 40029} ->
          {:error, :invalid_code}

        %{"errcode" => 40163} ->
          {:error, :code_already_used}

        _ ->
          body
      end
    end
  end

  @spec refresh_token(String.t()) :: {:ok, String.t()} | :error
  def refresh_token(refresh_token) do
    query_params = [appid: @app_id, refresh_token: refresh_token, grant_type: "refresh_token"]

    with {:ok, %Tesla.Env{body: %{"access_token" => web_access_token}}} <-
           get("/oauth2/refresh_token", query: query_params) do
      {:ok, web_access_token}
    else
      _ ->
        :error
    end
  end

  @spec is_valid?(String.t(), String.t()) :: boolean | {:error, :upstream_error}
  def is_valid?(web_access_token, open_id) do
    with {:ok, %Tesla.Env{body: %{"errcode" => 0}}} <-
           get("/auth", query: [access_token: web_access_token, openid: open_id]) do
      true
    else
      {:ok, _} ->
        false

      {:error, _} ->
        {:error, :upstream_error}
    end
  end

  # JSSDK related

  @spec get_jsapi_ticket(String.t()) :: {:ok, String.t()} | :error
  def get_jsapi_ticket(access_token) do
    query_params = [
      type: "jsapi",
      access_token: access_token
    ]

    with {:ok, %Tesla.Env{body: %{"ticket" => ticket}}} <-
           get("https://api.weixin.qq.com/cgi-bin/ticket/getticket", query: query_params) do
      {:ok, ticket}
    else
      _ -> :error
    end
  end

  @spec generate_jssdk_signature(String.t(), String.t(), String.t(), non_neg_integer()) ::
          String.t()
  def generate_jssdk_signature(url, jsapi_ticket, random_string, timestamp) do
    data =
      [
        jsapi_ticket: jsapi_ticket,
        noncestr: random_string,
        timestamp: timestamp,
        url: url
      ]
      |> Enum.map(fn {k, v} -> Atom.to_string(k) <> "=" <> to_string(v) end)
      |> Enum.join("&")

    :crypto.hash(:sha, data)
    |> Base.encode16()
    |> String.downcase()
  end
end
