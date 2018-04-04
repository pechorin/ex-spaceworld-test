defmodule Spaceworld.GameServer do

  alias Spaceworld.{Client, NasaSupervisor, GameLogic, DrawServer}
  alias Spaceworld.GameServer.{State, Point, WorldState}

  @moduledoc """
  Игровой сервер (одна планета = один сервак).

  - Отвечает за игровую логику,
  - принимает события от клиентов,
  - каждый тик просчитывает игровой мир исходя из текущего стейта + пришедших событий
  - и отправляет результаты клиентам и draw-серверу для отрисовки
  """

  defmodule Point do
    defstruct x: 0, y: 0
  end

  defmodule Position do
    @all_f_values [:N, :E, :S, :W]
    defstruct x: 0, y: 0, f: :N
  end

  defmodule WorldState do
    defstruct area: Point, clients_positions: %{}
  end

  defmodule State do
    defstruct [
      nasa_supervisor_pid: nil,
      draw_server_pid: nil,
      clients_pool: %{},
      commands_buffer: [],
      world_state: %WorldState{}
    ]
  end

  def start_link(%Point{} = area) do
    world_state = %WorldState{area: area}
    state       = %State{world_state: world_state}

    {:ok, nasa} = NasaSupervisor.start_link()
    state = %{state | nasa_supervisor_pid: nasa }

    {:ok, draw} = DrawServer.start_link()
    state = %{state | draw_server_pid: draw }

    {:ok, spawn_link(fn -> loop(state) end)}
  end

  def loop(%State{} = state) do
    receive do
      {:tick, n} ->
        # IO.puts "++> calculation new world state => #{ inspect(state) }"
        [new_world_state, player_errors] = GameLogic.update_world_state(state.world_state, state.commands_buffer)

        state = %{ state | world_state: new_world_state }
        state = %{ state | commands_buffer: [] }

        # IO.puts "+++\n--> new world state calculated -> #{ inspect(state) }, player_errors -> #{ inspect(player_errors) }\n"

        state.clients_pool
        |> Enum.each(fn { pid, client } ->
          if Process.alive?(pid) do
            player_errors = player_errors[client.id] || []
            send(pid, { :new_world_state, new_world_state, player_errors })
          end
        end)

        send(state.draw_server_pid, { :draw, state.world_state })

        loop(state)

      {:client_login, %Client{} = client, commands} when is_list(commands) ->
        {:ok, client_pid} = NasaSupervisor.start_client(state.nasa_supervisor_pid, self(), client)
        state = update_in(state.clients_pool, fn (map) -> put_in(map, [client_pid], client) end)

        send(client_pid, {:start_game, commands})
        loop(state)

      {:client_logout, %Client{} = client, client_pid} ->
        new_clients_pool = Map.delete(state.clients_pool, client_pid)
        new_world_state  = Map.delete(state.clients_positions, client.id)
        
        loop( %{ state | clients_pool: new_clients_pool, world_state: new_world_state } )

      {:client_command_request, command = %GameLogic.Command{}} ->
        state = update_in(state.commands_buffer, fn (list) when is_list(list) -> list ++ [command] end)

        loop(state)
    end
  end

  def loop(_) do
    raise "Unknown state type"
  end

end
