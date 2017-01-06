defmodule Pump.Pump do
  use GenServer

  def start_link(pwm_gpio, gpio1, gpio2) do
    GenServer.start_link(__MODULE__, {pwm_gpio, gpio1, gpio2}, name: via_tuple({pwm_gpio, gpio1, gpio2}))
  end

  def via_tuple({pwm_gpio, gpio1, gpio2}) do
    {:via, :gproc, {:n, :l, {:pump, pwm_gpio, gpio1, gpio2}}}
  end

  def init({pwm_gpio, gpio1, gpio2}) do
    {:ok, pwm_pid} = Gpio.start_link(pwm_gpio, :output)
    {:ok, gpio1_pid} = Gpio.start_link(gpio1, :output)
    {:ok, gpio2_pid} = Gpio.start_link(gpio2, :output)

    {:ok, {pwm_pid, gpio1_pid, gpio2_pid}}
  end

  def on(gpios) do
    gpios
    |> via_tuple()
    |> GenServer.call({:on})
  end

  def off(gpios) do
    gpios
    |> via_tuple()
    |> GenServer.call({:off})
  end

  def run(gpios, seconds) do
    on(gpios)

    :timer.sleep(seconds * 1000)
    
    off(gpios)
  end

  def handle_call({:on}, _from, {pwm_pid, gpio1_pid, gpio2_pid}) do
    Gpio.write(gpio1_pid, 1)
    Gpio.write(gpio2_pid, 0)
    Gpio.write(pwm_pid, 1)
  end

  def handle_call({:off}, _from, {pwm_pid, gpio1_pid, gpio2_pid}) do
    Gpio.write(gpio1_pid, 0)
    Gpio.write(gpio2_pid, 0)
    Gpio.write(pwm_pid, 0)
  end
end
