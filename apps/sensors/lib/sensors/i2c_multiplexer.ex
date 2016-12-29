defmodule Sensors.I2CMultiplexer do
  use GenServer
  use Bitwise

  def start_link(multiplexer_address) do
    GenServer.start_link(__MODULE__, multiplexer_address, name: via_tuple(multiplexer_address))
  end

  def via_tuple(multiplexer_address) do
    {:via, :gproc, {:n, :l, {:i2c_multiplexer, multiplexer_address}}}
  end

  def init(multiplexer_address) do
    {:ok, pid} = I2c.start_link("i2c-1", multiplexer_address)
    {:ok, pid}
  end

  def write_read(multiplexer_address, device_address, channel, write_data, read_count) do
    multiplexer_address
    |> via_tuple
    |> GenServer.call({:write_read, device_address, channel, write_data, read_count})
  end

  def write(multiplexer_address, device_address, channel, write_data) do
    multiplexer_address
    |> via_tuple
    |> GenServer.call({:write, device_address, channel, write_data})
  end

  def handle_call({:write_read, device_address, channel, write_data, read_count}, _from, pid) do
    select_channel(pid, channel)
    result = I2c.write_read_device(pid, device_address, write_data, read_count)
    {:reply, result, pid}
  end

  def handle_call({:write,device_address,  channel, write_data}, _from, pid) do
    select_channel(pid, channel)
    result = I2c.write_device(pid, device_address, write_data)
    {:reply, result, pid}
  end

  defp select_channel(pid, channel) do
    channel = 1 <<< channel
    I2c.write(pid, <<channel>>)
  end
end
