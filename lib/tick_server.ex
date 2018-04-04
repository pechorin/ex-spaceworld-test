defmodule Spaceworld.TickServer do

  @moduledoc """
  Наш тупенький симулятор fps без просчета лагов :)
  """

  def start_link(interval, total_ticks, consumer_process) do
    spawn_link(fn -> loop(interval, total_ticks, consumer_process) end)
  end

  def loop(interval, total_ticks, consumer_process) do
    case total_ticks do
      num when num > 0 ->
        receive do
        after
          interval ->
            send consumer_process, {:tick, total_ticks}
            loop(interval, total_ticks - 1, consumer_process)
        end
      _ ->
        IO.puts "WorldTick finished"
    end
  end

end
