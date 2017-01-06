defmodule Mqtt.Client do
  use GenMQTT
  require Logger

  def start_link do
    host = Application.get_env(:mqtt, :host)
    client_name = Application.get_env(:mqtt, :client_name)
    GenMQTT.start_link(__MODULE__, [], [name: via_tuple(), host: host, client: client_name])
  end

  def via_tuple() do
    {:via, :gproc, {:n, :l, {:mqtt_client}}}
  end

  def init(state) do
    :gproc.reg({:p, :l, {:listener, :temp}})
    :gproc.reg({:p, :l, {:listener, :moisture}})
    :gproc.reg({:p, :l, {:listener, :light}})
    
    {:ok, state}
  end

  def publish(topic, payload, qos) do
    via_tuple()
    |> GenServer.whereis
    |> GenMQTT.publish(topic, payload, qos, false)
  end

  def on_connect(state) do
    Logger.debug "MQTT Connected"
    {:ok, state}
  end

  def on_disconnect(state) do
    Logger.debug "MQTT Disconnected"
    {:ok, state}
  end

  def on_connect_error(reason, state) do
    Logger.debug "MQTT Connect Error: #{inspect reason}"
    {:ok, state}
  end

  def on_publish(topic, payload, state) do
    Logger.debug "MQTT Message Received: #{inspect topic} - #{inspect payload}"
    {:ok, state}
  end

  def handle_info({:update, sensor, label, value}, state) do
    topic = "sensors/watering_pi/#{sensor}/#{label}"
    value = value |> to_string

    Logger.debug "Sending: #{value} to #{topic}"

    publish(topic, value, 2)

    {:noreply, state}
  end
end
