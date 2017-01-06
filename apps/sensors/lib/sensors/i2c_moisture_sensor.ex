defmodule Sensors.I2CMoistureSensor do
  use GenServer
  require Logger

  @moisture_register <<0>>
  @light_measure_register <<3>>
  @light_register <<4>>
  @temperature_register <<5>>

  def start_link(address) do
    GenServer.start_link(__MODULE__, address, name: via_tuple(address))
  end

  def via_tuple({multiplexer_address, device_address, channel}) do
    {:via, :gproc, {:n, :l, {:i2c_moisture_sensor, multiplexer_address, device_address, channel}}}
  end
  def via_tuple(device_address) do
    {:via, :gproc, {:n, :l, {:i2c_moisture_sensor, device_address}}}
  end

  def init({multiplexer_address, device_address, channel}) do
    {:ok, {multiplexer_address, device_address, channel}}
  end
  def init(device_address) do
    {:ok, pid} = I2c.start_link("i2c-1", device_address)
    {:ok, pid}
  end

  def temp(address) do
    address
    |> via_tuple()
    |> GenServer.call({:temp})
  end

  def light(address) do
    address
    |> via_tuple()
    |> GenServer.call({:light})
  end

  def moisture(address) do
    address
    |> via_tuple()
    |> GenServer.call({:moisture})
  end

  def status(address) do
    temp = temp(address)
    light = light(address)
    moisture = moisture(address)
    {temp, light, moisture}
  end

  def handle_call({:temp}, _from, address) do
    case write_read(address, @temperature_register, 2) do
      << temp :: integer-size(16) >> -> 
        temp = temp * 0.1
        |> c_to_f
        |> Float.round(2)

        {:reply, temp, address}
      {:error, msg} ->
        Logger.error "Error WriteReading #{inspect @temperature_register}, 2 to #{inspect address}: #{inspect msg}"
        {:reply, 0, address}
    end
  end

  def handle_call({:light}, _from, address) do
    case write(address, @light_measure_register) do
      {:error, msg} ->
        Logger.error "Error Writing #{inspect @light_measure_register} to #{inspect address}: #{inspect msg}"
        {:reply, 0, address}
      _ ->
      :timer.sleep(3000)

      case write_read(address, @light_register, 2) do
        << light :: integer-size(16) >> -> 
          {:reply, light, address}
        {:error, msg} ->
          Logger.error "Error WriteReading #{inspect @light_register}, 2 to #{inspect address}: #{inspect msg}"
          {:reply, 0, address}
      end
    end
  end

  def handle_call({:moisture}, _from, address) do
    case write_read(address, @moisture_register, 2) do
      << moisture :: integer-size(16) >> ->
        {:reply, moisture, address}
      {:error, msg} ->
        Logger.error "Error WriteReading #{inspect @moisture_register}, 2 to #{inspect address}: #{inspect msg}"
        {:reply, 0, address}
    end
  end

  defp write({multiplexer_address, device_address, channel}, write_data) do
    Sensors.I2CMultiplexer.write(multiplexer_address, device_address, channel, write_data)
  end
  defp write(pid, write_data) do
    I2c.write(pid, write_data)
  end

  defp write_read({multiplexer_address, device_address, channel}, write_data, read_count) do
    Sensors.I2CMultiplexer.write_read(multiplexer_address, device_address, channel, write_data, read_count)
  end
  defp write_read(pid, write_data, read_count) do
    I2c.write_read(pid, write_data, read_count)
  end

  defp c_to_f(int) do
    int * 1.8 + 32
  end
end
