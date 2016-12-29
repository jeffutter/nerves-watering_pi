defmodule Sensors.MetricCollector do
  use GenServer

  def start_link(address) do
    GenServer.start_link(__MODULE__, address, name: via_tuple(address))
  end

  def via_tuple({multiplexer_address, device_address, channel}) do
    {:via, :gproc, {:n, :l, {:sensor_metric_collector, multiplexer_address, device_address, channel}}}
  end
  def via_tuple(device_address) do
    {:via, :gproc, {:n, :l, {:sensors_metric_collector, device_address}}}
  end

  def init(address) do
    Sensors.TempInstrumenter.setup
    Sensors.MoistureInstrumenter.setup
    Sensors.LightInstrumenter.setup
    :gproc.reg({:p, :l, {:listener, :temp}})
    :gproc.reg({:p, :l, {:listener, :moisture}})
    :gproc.reg({:p, :l, {:listener, :light}})
    {:ok, address}
  end

  def handle_info({:update, "temp", label, value}, address) do
    Sensors.TempInstrumenter.set_temp(label, value)
    {:noreply, address}
  end
  def handle_info({:update, "moisture", label, value}, address) do
    Sensors.MoistureInstrumenter.set_moisture(label, value)
    {:noreply, address}
  end
  def handle_info({:update, "light", label, value}, address) do
    Sensors.LightInstrumenter.set_light(label, value)
    {:noreply, address}
  end
end
