defmodule Wechat.Util do

  @app_id Application.get_env(:wechat, :app_id)

  @spec gen_portal_uri(String.t()) :: String.t()
  def gen_portal_uri(redirect_uri) do
    query_params =
      [
        {"appid", @app_id},
        {"redirect_uri", redirect_uri},
        {"response_type", "code"},
        {"scope", "snsapi_base"}
      ]

    "https://open.weixin.qq.com/connect/oauth2/authorize#wechat_redirect"
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(query_params))
    |> URI.to_string()
  end

  @spec gen_random_str() :: String.t()
  def gen_random_str() do
    :crypto.strong_rand_bytes(12)
    |> Base.encode64
  end

  @spec timestamp_now() :: non_neg_integer()
  def timestamp_now() do
    Timex.to_unix(Timex.now)
  end
end
