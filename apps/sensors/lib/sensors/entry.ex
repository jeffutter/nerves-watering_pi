defmodule Sensors.Entry do
  @derive [Poison.Encoder]

  defstruct [:time, :temp, :moisture, :light]
  @type t :: %__MODULE__{time: DateTime.t, temp: float, moisture: integer, light: integer}

  @spec new(float, integer, integer) :: t
  def new(temp, moisture, light) do
    new(DateTime.utc_now, temp, moisture, light)
  end
  @spec new(DateTime.t, float, integer, integer) :: t
  def new(time, temp, moisture, light) do
    %__MODULE__{time: time, temp: temp, moisture: moisture, light: light}
  end

  def eql?(l, r) do
    l.temp == r.temp
    && l.moisture == r.moisture
    && l.light == r.light
  end
end
