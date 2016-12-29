defmodule Sensors.TempInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :temperature,
                   labels: [:address],
                   help: "Temperature"])
  end

  def set_temp(label, temp) do
    Gauge.set([name: :temperature, labels: [label]], temp)
  end
end
