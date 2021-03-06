defmodule Mint.UnsafeProxy do
  @moduledoc false

  alias Mint.{Types, UnsafeProxy}

  @behaviour Mint.Core.Conn

  defstruct [
    :hostname,
    :port,
    :scheme,
    :module,
    :state
  ]

  @opaque t() :: %UnsafeProxy{}

  @type host_triple() :: {Types.scheme(), hostname :: String.t(), :inet.port_number()}

  @spec connect(host_triple(), host_triple(), opts :: keyword()) ::
          {:ok, t()} | {:error, term()}
  def connect(proxy, host, opts \\ []) do
    {proxy_scheme, proxy_hostname, proxy_port} = proxy
    {scheme, hostname, port} = host

    with {:ok, state} <- Mint.HTTP1.connect(proxy_scheme, proxy_hostname, proxy_port, opts) do
      conn = %UnsafeProxy{
        scheme: scheme,
        hostname: hostname,
        port: port,
        module: state.__struct__,
        state: state
      }

      {:ok, conn}
    end
  end

  @impl true
  @spec initiate(
          module(),
          Mint.Core.Transport.socket(),
          String.t(),
          :inet.port_number(),
          keyword()
        ) :: no_return()
  def initiate(_transport, _transport_state, _hostname, _port, _opts) do
    raise "initiate/5 does not apply for #{inspect(__MODULE__)}"
  end

  @impl true
  @spec open?(t()) :: boolean()
  def open?(%UnsafeProxy{module: module, state: state}) do
    module.open?(state)
  end

  @impl true
  @spec request(
          t(),
          method :: String.t(),
          path :: String.t(),
          Types.headers(),
          body :: iodata() | nil | :stream
        ) ::
          {:ok, t(), Types.request_ref()}
          | {:error, t(), term()}
  def request(
        %UnsafeProxy{module: module, state: state} = conn,
        method,
        path,
        headers,
        body \\ nil
      ) do
    path = request_line(conn, path)

    case module.request(state, method, path, headers, body) do
      {:ok, state, request} -> {:ok, %{conn | state: state}, request}
      {:error, state, reason} -> {:error, %{conn | state: state}, reason}
    end
  end

  @impl true
  @spec stream_request_body(t(), Types.request_ref(), iodata() | :eof) ::
          {:ok, t()} | {:error, t(), term()}
  def stream_request_body(%UnsafeProxy{module: module, state: state} = conn, ref, body) do
    case module.stream_request_body(state, ref, body) do
      {:ok, state} -> {:ok, %{conn | state: state}}
      {:error, state, reason} -> {:error, %{conn | state: state}, reason}
    end
  end

  @impl true
  @spec stream(t(), term()) ::
          {:ok, t(), [Types.response()]}
          | {:error, t(), term(), [Types.response()]}
          | :unknown
  def stream(%UnsafeProxy{module: module, state: state} = conn, message) do
    case module.stream(state, message) do
      {:ok, state, responses} -> {:ok, %{conn | state: state}, responses}
      {:error, state, reason, responses} -> {:error, %{conn | state: state}, reason, responses}
      :unknown -> :unknown
    end
  end

  @impl true
  @spec put_private(t(), atom(), term()) :: t()
  def put_private(%UnsafeProxy{module: module, state: state} = conn, key, value) do
    state = module.put_private(state, key, value)
    %{conn | state: state}
  end

  @impl true
  @spec get_private(t(), atom(), term()) :: term()
  def get_private(%UnsafeProxy{module: module, state: state}, key, default \\ nil) do
    module.get_private(state, key, default)
  end

  @impl true
  @spec delete_private(t(), atom()) :: t()
  def delete_private(%UnsafeProxy{module: module, state: state} = conn, key) do
    state = module.delete_private(state, key)
    %{conn | state: state}
  end

  defp request_line(%UnsafeProxy{scheme: scheme, hostname: hostname, port: port}, path) do
    %URI{scheme: Atom.to_string(scheme), host: hostname, port: port, path: path}
    |> URI.to_string()
  end

  @impl true
  @spec get_socket(t()) :: Mint.Core.Transport.socket()
  def get_socket(%UnsafeProxy{module: module, state: state}) do
    module.get_socket(state)
  end
end
