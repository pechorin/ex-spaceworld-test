defmodule Spaceworld.DrawServer do

  @moduledoc """
  Сервер отрисовки игровой карты.
  Просто рисует в консоле матрицу игры, где "*" -> пустая клетка, а "X" -> игрок
  """

  alias Spaceworld.GameServer.WorldState

  def start_link do
    {:ok, spawn_link(&loop/0)}
  end

  def loop do
    receive do
      {:draw, %WorldState{} = world_state} -> 
        draw_state(world_state)
        loop()

      _ -> 
        IO.puts "uknown message for draw server"
        loop()
    end
  end

  defp draw_state(%WorldState{} = world_state) do
    draw_matrix = draw_line(world_state, world_state.area.x, [])

    picture = []
    picture = picture ++ [ "" ]
    picture = picture ++ [ draw_separator(world_state.area.x, []) ]
    picture = picture ++ draw_matrix
    picture = picture ++ [ draw_separator(world_state.area.x, []) ]
    picture = picture ++ [ "" ]

    IO.puts(Enum.join(picture, "\n"))
  end

  def draw_separator(index, result) when index > 0 , do: draw_separator(index - 1, result ++ [ "- " ])
  def draw_separator(index, result) when index == 0, do: Enum.join(result, "")

  defp draw_line(world_state, index, result) when index > 0 do
    line = draw_line_point(world_state, index, world_state.area.y, [])
    joined_line = List.to_string(line)

    draw_line(world_state, index - 1, result ++ [ joined_line ])
  end

  defp draw_line(world_state, index, result) when index == 0, do: result

  defp draw_line_point(world_state, x_index, y_index, result) when y_index > 0 do
    is_point_occupied = fn -> 
      world_state.clients_positions
      |> Enum.any? fn { client_id, position } ->
        position.x == x_index && position.y == y_index 
      end
    end

    point = case is_point_occupied.() do
      true  -> "X "
      false -> "* "
    end

    draw_line_point(world_state, x_index, y_index - 1, result ++ [ point ])
  end

  defp draw_line_point(world_state, x_index, y_index, result) when y_index == 0, do: result

end
