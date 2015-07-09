defmodule IElixir.Heartbeat do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: MyHeartbeat)
  end

  def init(opts) do
    { :ok, sock } = :erlzmq.socket(opts[:ctx], [:rep, {:active, true }])
    conn_info = opts[:conn_info]
    url = conn_info["transport"] <> "://" <> conn_info["ip"] <> ":" <> Integer.to_string(conn_info["hb_port"])
    Logger.info(url)
    :ok = :erlzmq.bind(sock, url)
    { :ok, id } = :erlzmq.getsockopt(sock, :identity)
    { :ok, { sock, id } }
  end

  def terminate(_reason, { sock, _ }) do
    :erlzmq.close(sock)
  end

  def send_message(pid) do
    GenServer.cast(pid, :message1)
  end

  # def handle_cast(request, state) do
  #   Logger.info("Przyszedł jakiś request")
  #   {:noreply, []}
  # end
  def handle_info({ :zmq, _, data, [] }, state = { sock, id }) do
    Logger.info("GOT HEARTBEAT")
    :erlzmq.send(sock, data)
    { :noreply, state }
  end
  def handle_info(msg, state) do
    Lager.warn("Got unexpected message on hb process: #{inspect msg}")
    { :noreply, state}
  end
end
