defmodule Mint.Core.Transport do
  @moduledoc false

  @type error() :: {:error, reason :: term()}

  alias Mint.Types

  @callback connect(host :: String.t(), port :: :inet.port_number(), opts :: keyword()) ::
              {:ok, Types.socket()} | error()

  @callback upgrade(
              Types.socket(),
              old_transport :: module(),
              hostname :: String.t(),
              :inet.port_number(),
              opts :: keyword()
            ) :: {:ok, {module(), Types.socket()}} | error()

  @callback negotiated_protocol(Types.socket()) ::
              {:ok, protocol :: binary()} | {:error, :protocol_not_negotiated}

  @callback send(Types.socket(), payload :: iodata()) :: :ok | error()

  @callback close(Types.socket()) :: :ok | error()

  @callback recv(Types.socket(), bytes :: non_neg_integer()) :: {:ok, binary()} | error()

  @callback setopts(Types.socket(), opts :: keyword()) :: :ok | error()

  @callback getopts(Types.socket(), opts :: keyword()) :: {:ok, opts :: keyword()} | error()
end
