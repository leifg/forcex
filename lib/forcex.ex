defmodule Forcex do
  @moduledoc """
  The main module for interacting with Salesforce
  """

  require Logger

  @type client :: map
  @type response :: map | {number, any}
  @type method :: :get | :put | :post | :patch | :delete

  @api Application.get_env(:forcex, :api) || Forcex.Api.Http

  @spec json_request(method, String.t, map | String.t, list, list) :: response
  def json_request(method, url, body, headers, options) do
    @api.raw_request(method, url, Poison.encode!(body), headers, options)
  end

  @spec post(String.t, map | String.t, client) :: response
  def post(path, body \\ "", client) do
    url = client.endpoint <> path
    json_request(:post, url, body, client.authorization_header, [])
  end

  @spec patch(String.t, String.t, client) :: response
  def patch(path, body \\ "", client) do
    url = client.endpoint <> path
    json_request(:patch, url, body, client.authorization_header, [])
  end

  @spec delete(String.t, client) :: response
  def delete(path, client) do
    url = client.endpoint <> path
    @api.raw_request(:delete, url, "", client.authorization_header, [])
  end

  @spec get(String.t, map | String.t, list, client) :: response
  def get(path, body \\ "", headers \\ [], client) do
    url = client.endpoint <> path
    json_request(:get, url, body, headers ++ client.authorization_header, [])
  end

  @spec versions(client) :: response
  def versions(%Forcex.Client{} = client) do
    get("/services/data", client)
  end

  @spec services(client) :: response
  def services(%Forcex.Client{} = client) do
    get("/services/data/v#{client.api_version}", client)
  end

  @basic_services [
    limits: :limits,
    describe_global: :sobjects,
    quick_actions: :quickActions,
    recently_viewed_items: :recent,
    tabs: :tabs,
    theme: :theme,
  ]

  for {function, service} <- @basic_services do
    @spec unquote(function)(client) :: response
    def unquote(function)(%Forcex.Client{} = client) do
      client
      |> service_endpoint(unquote(service))
      |> get(client)
    end
  end

  @spec describe_sobject(String.t, client) :: response
  def describe_sobject(sobject, %Forcex.Client{} = client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/#{sobject}/describe/"
    |> get(client)
  end

  def attachment_body(binary_path, %Forcex.Client{} = client) do
    base = service_endpoint(client, "sobjects")

    "#{base}/Attachment/#{binary_path}/Body"
    |> get(client)
  end

  @spec metadata_changes_since(String.t, String.t, client) :: response
  def metadata_changes_since(sobject, since, client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/#{sobject}/describe/"
    |> get("", [{"If-Modified-Since", since}], client)
  end

  @spec query(String.t, client) :: response
  def query(query, %Forcex.Client{} = client) do
    base = service_endpoint(client, :query)
    params = %{"q" => query} |> URI.encode_query

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec query_all(String.t, client) :: response
  def query_all(query, %Forcex.Client{} = client) do
    base = service_endpoint(client, :queryAll)
    params = %{"q" => query} |> URI.encode_query

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec service_endpoint(client, String.t) :: String.t
  defp service_endpoint(%Forcex.Client{services: services}, service) do
    Map.get(services, service)
  end
end
