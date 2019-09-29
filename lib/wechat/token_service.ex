defmodule Wechat.TokenService do
  @moduledoc """
  Token fetching and caching
  """

  @spec initialise :: :ok | :service_down
  def initialise() do
    :ets.new(:wechat_tokens, [:set, :protected, :named_table])

    request_tokens()
  end

  @spec request_tokens :: :ok | :service_down
  def request_tokens() do
    with {:ok, access_token} <- request_access_token(),
         {:ok, _jsapi_ticket} <- request_jsapi_ticket(access_token) do
      :ets.insert(:wechat_tokens, {:service_status, :ok})
      :ok
    else
      _ ->
        :ets.insert(:wechat_tokens, {:service_status, :down})
        :service_down
    end
  end

  defp request_access_token() do
    with {:ok, access_token} <- Wechat.Access.get_token() do
      true = :ets.insert(:wechat_tokens, {:access_token, access_token})
      {:ok, access_token}
    end
  end

  defp request_jsapi_ticket(access_token) do
    with {:ok, jsapi_ticket} <- Wechat.Web.get_jsapi_ticket(access_token) do
      true = :ets.insert(:wechat_tokens, {:jsapi_ticket, jsapi_ticket})
      {:ok, jsapi_ticket}
    end
  end

  @spec fetch_access_token() :: {:ok, String.t()} | :error
  def fetch_access_token(), do: fetch_cached_token(:access_token)

  @spec fetch_jsapi_ticket() :: {:ok, String.t()} | :error
  def fetch_jsapi_ticket(), do: fetch_cached_token(:jsapi_ticket)

  @spec gen_jssdk_signature(String.t(), non_neg_integer(), String.t()) :: String.t()
  def gen_jssdk_signature(url, timestamp, random_str) do
    with {:ok, jsapi_ticket} <- fetch_jsapi_ticket() do
      Wechat.Web.generate_jssdk_signature(url, jsapi_ticket, random_str, timestamp)
    end
  end

  @spec fetch_cached_token(atom()) :: {:ok, String.t()} | :error
  defp fetch_cached_token(key) do
    with [{_, value} | _] <- :ets.lookup(:wechat_tokens, key) do
      {:ok, value}
    else
      [] -> :error
    end
  end
end
