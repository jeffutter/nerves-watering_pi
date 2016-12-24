defmodule Sensors.History do
  use Timex
  require Logger

  alias Sensors.Entry, as: Entry

  defstruct [:duration, :data, :dirty]
  @type t :: %__MODULE__{duration: number, data: [Entry.t], dirty: boolean}

  @history_duration 60 * 60 * 24

  @spec new :: t
  def new do
    %__MODULE__{duration: @history_duration, data: [], dirty: false}
  end

  @spec add(t, Entry.t) :: t
  def add(history, entry) do
    data = history.data
    |> trim_duration(history.duration)
    |> split
    |> add_entry(entry)

    dirty = history.dirty || history.data != data

    %__MODULE__{history | data: data, dirty: dirty}
  end

  @spec mark_clean(t) :: t
  def mark_clean(history) do
    %__MODULE__{history | dirty: false}
  end

  @spec read(String.t) :: {:ok, t} | {:error, String.t}
  def read(path) do
    case File.read(path) do
      {:ok, serialized} ->
        case unserialize(serialized) do
          {:ok, history} -> {:ok, history}
          {:error, _} ->
            Logger.error "Error Parsing #{path}"
            {:error, "Parse Error"}
        end
      {:error, _} ->
        Logger.error "Error Loading #{path}"
        {:error, "Load Error"}
    end
  end

  @spec write(t, String.t) :: t
  def write(history, path) do
    case serialize(history) do
      {:ok, serialized} ->
        case File.write(path, serialized) do
          {:error, _} ->
            Logger.error "Error Writing #{path}"
            history
          :ok ->
            history
        end
      {:error, _} -> 
        Logger.error "Error Serializing History"
        history
    end
    |> mark_clean
  end

  defp serialize(history) do
    {:ok, :erlang.term_to_binary(history)}
  end
  defp unserialize(string) do
    {:ok, :erlang.binary_to_term(string)}
  end

  @spec add_entry({map, map, map, map}, [map]) :: [map]
  defp add_entry({nil,   nil,    nil,   []},   entry), do: [entry]
  defp add_entry({first, nil,    nil,   []},   entry), do: [entry, first]
  defp add_entry({first, second, nil,   []},   entry) do
    if entry_eql(entry, first, second) do
      [entry, second]
    else
      [entry, first, second]
    end
  end
  defp add_entry({first, second, third, rest}, entry) do
    if entry_eql(entry, first, second) do
      [entry, second, third]
    else
      [entry, first, second, third]
    end
    |> append_rest(rest)
  end

  defp append_rest(l, []), do: l
  defp append_rest(l, r), do: l ++ r

  @spec split([map]) :: {map, map, map, [map]}
  defp split([]),                            do: {nil,   nil,    nil,   []}
  defp split([first]),                       do: {first, nil,    nil,   []}
  defp split([first, second]),               do: {first, second, nil,   []}
  defp split([first, second, third]),        do: {first, second, third, []}
  defp split([first, second, third | rest]), do: {first, second, third, rest}

  @spec trim_duration([map], number) :: [map]
  defp trim_duration([], _duration), do: []
  defp trim_duration(data, duration) do
    data
    |> Enum.reverse
    |> trim_duration(nil, duration)
    |> Enum.reverse
  end

  @spec trim_duration([map], number, number) :: [map]
  defp trim_duration([head | _rest] = data, diff, duration) when is_nil(diff) do
    trim_duration(data, Timex.diff(Timex.now, head.time), duration)
  end
  defp trim_duration([_head| rest], diff, duration) when diff > (duration * 1000000) do
    trim_duration(rest, nil, duration)
  end
  defp trim_duration(data, _diff, _duration) do
    data
  end

  defp entry_eql(first, second, third) do
    Entry.eql?(first, second) && Entry.eql?(second, third)
  end
end
