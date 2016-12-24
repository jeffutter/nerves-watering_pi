defmodule Sensors.HistoryManager do
  require Logger
  use GenServer

  alias Sensors.History, as: History
  alias Sensors.I2CMoistureSensor, as: I2CMoistureSensor

  defstruct [:device_address, :history, :options]

  @pause_ms 60_000

  def start_link(device_address, options \\ [persist: true]) do
    GenServer.start_link(__MODULE__, {device_address, options}, name: via_tuple(device_address))
  end

  def via_tuple(device_address) do
    {:via, :gproc, {:n, :l, {:sensors_history, device_address}}}
  end

  def init({device_address, options}) do
    state = default(device_address, options)
    Sensors.TempInstrumenter.setup
    Sensors.MoistureInstrumenter.setup
    Sensors.LightInstrumenter.setup
    Process.send_after(self, :update, @pause_ms)
    {:ok, state}
  end

  def add(device_address, entry) do
    device_address
    |> via_tuple
    |> GenServer.cast({:add, entry})
    entry
  end

  def get_history(device_address) do
    device_address
    |> via_tuple
    |> GenServer.call(:get_history)
  end

  def handle_info(:update, state) do
    state.device_address
    |> via_tuple
    |> GenServer.cast({:update})

    Process.send_after(self, :update, @pause_ms)
    {:noreply, state}
  end

  def handle_call(:get_history, _f, state) do
    {:reply, state.history, state}
  end

  def handle_cast({:update}, state) do
    state
    |> add_latest

    {:noreply, state}
  end

  def handle_cast({:add, entry}, state) do
    entry |> cast
    {:noreply, %__MODULE__{state | history: state.history |> History.add(entry)}}
  end

  defp add_latest(state) do
    {temp, light, moisture} = I2CMoistureSensor.status(state.device_address)

    entry = Sensors.Entry.new(temp, moisture, light)

    state.device_address
    |> via_tuple
    |> GenServer.cast({:add, entry})

    entry
  end

  defp default(device_address, options) do
    new(device_address, History.new, options)
  end

  defp new(device_address, history, options) do
    %__MODULE__{device_address: device_address, history: history, options: options}
  end

  defp cast(entry) do
    :gproc.send({:p, :l, {:listener, :temp}}, {:update, "temp", entry.temp})
    :gproc.send({:p, :l, {:listener, :moisture}}, {:update, "moisture", entry.moisture})
    :gproc.send({:p, :l, {:listener, :light}}, {:update, "light", entry.light})
    Sensors.TempInstrumenter.set_temp(entry.temp)
    Sensors.MoistureInstrumenter.set_moisture(entry.moisture)
    Sensors.LightInstrumenter.set_light(entry.light)
  end
end
