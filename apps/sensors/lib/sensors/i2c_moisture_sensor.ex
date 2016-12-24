defmodule Sensors.I2CMoistureSensor do
  use GenServer

  @moisture_register <<0>>
  @light_measure_register <<3>>
  @light_register <<4>>
  @temperature_register <<5>>

  def start_link(device_address) do
    GenServer.start_link(__MODULE__, device_address, name: via_tuple(device_address))
  end

  def via_tuple(device_address) do
    {:via, :gproc, {:n, :l, {:i2c_moisture_sensor, device_address}}}
  end

  def init(device_address) do
    {:ok, pid} = I2c.start_link("i2c-1", device_address)
    {:ok, pid}
  end

  def temp(device_address) do
    device_address
    |> via_tuple
    |> GenServer.call({:temp})
  end

  def light(device_address) do
    device_address
    |> via_tuple
    |> GenServer.call({:light})
  end

  def moisture(device_address) do
    device_address
    |> via_tuple
    |> GenServer.call({:moisture})
  end

  def status(device_address) do
    temp = temp(device_address)
    light = light(device_address)
    moisture = moisture(device_address)
    {temp, light, moisture}
  end

  def handle_call({:temp}, _from, pid) do
    << temp :: integer-size(16) >> = I2c.write_read(pid, @temperature_register, 2)
    
    temp = temp * 0.1
    |> c_to_f
    |> Float.round(2)

    {:reply, temp, pid}
  end

  def handle_call({:light}, _from, pid) do
    I2c.write(pid, @light_measure_register)
    :timer.sleep(3000)

    << light :: integer-size(16) >> = I2c.write_read(pid, @light_register, 2)

    {:reply, light, pid}
  end

  def handle_call({:moisture}, _from, pid) do
    << moisture :: integer-size(16) >> = I2c.write_read(pid, @moisture_register, 2)

    {:reply, moisture, pid}
  end

  defp c_to_f(int) do
    int * 1.8 + 32
  end
end
