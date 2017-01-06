defmodule Sensors.HistoryManager do
  require Logger
  use GenServer

  alias Sensors.History, as: History
  alias Sensors.I2CMoistureSensor, as: I2CMoistureSensor

  defstruct [:address, :history]

  @pause_ms 60_000

  def start_link(address) do
    GenServer.start_link(__MODULE__, address, name: via_tuple(address))
  end

  def via_tuple({multiplexer_address, device_address, channel}) do
    {:via, :gproc, {:n, :l, {:sensor_history, multiplexer_address, device_address, channel}}}
  end
  def via_tuple(device_address) do
    {:via, :gproc, {:n, :l, {:sensors_history, device_address}}}
  end

  def init(address) do
    state = default(address)
    Process.send_after(self(), :update, @pause_ms)
    {:ok, state}
  end

  def add(address, entry) do
    address
    |> via_tuple()
    |> GenServer.cast({:add, entry})
    entry
  end

  def get_history(address) do
    address
    |> via_tuple()
    |> GenServer.call(:get_history)
  end

  def handle_info(:update, state) do
    state.address
    |> via_tuple()
    |> GenServer.cast({:update})

    Process.send_after(self(), :update, @pause_ms)
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
    state.address
    |> cast(entry)
    {:noreply, %__MODULE__{state | history: state.history |> History.add(entry)}}
  end

  defp add_latest(state) do
    {temp, light, moisture} = I2CMoistureSensor.status(state.address)

    entry = Sensors.Entry.new(temp, moisture, light)

    state.address
    |> via_tuple()
    |> GenServer.cast({:add, entry})

    entry
  end

  defp default(address) do
    new(address, History.new)
  end

  defp new(address, history) do
    %__MODULE__{address: address, history: history}
  end

  defp cast(address, entry) do
    :gproc.send({:p, :l, {:listener, :temp}}, {:update, "temp", label(address), entry.temp})
    :gproc.send({:p, :l, {:listener, :moisture}}, {:update, "moisture", label(address), entry.moisture})
    :gproc.send({:p, :l, {:listener, :light}}, {:update, "light", label(address), entry.light})
  end

  defp label({multiplexer_address, device_address, channel}) do
    "#{inspect multiplexer_address}_#{inspect device_address}_#{inspect channel}"
    |> String.to_atom
  end
  defp label(device_address) do
    "#{inspect device_address}"
    |> String.to_atom
  end
end
