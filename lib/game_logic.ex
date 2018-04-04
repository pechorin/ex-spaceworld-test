defmodule Spaceworld.GameLogic do

  @moduledoc """
  Игровая логика:
  — через этот модуль создаются игровые команды
  — этот модуль накладывает команды на состояние мира
  — генерирует игровые ошибки
  """

  alias Spaceworld.GameServer.Point
  alias Spaceworld.GameServer.Position
  alias Spaceworld.GameServer.WorldState

  defmodule CommandSpec do
    @callback new(client_id :: integer, name :: atom) :: Command.t
    @callback calculate(state :: map) :: map
  end

  defmodule Command do
    defstruct [ client_id: nil, action: :move, data: nil ]

    @type t :: %Command{ client_id: integer(), action: atom(), data: tuple() | none() }

    @enforce_keys [ :client_id, :action ]
  end

  @behaviour CommandSpec

  @commands_list [
    :enter,
    :move,
    :turn_left,
    :turn_right
  ]

  def new(client_id, name) do
    case name in @commands_list do
      true -> %Command{ :client_id => client_id, :action => name }
      _    -> raise "Unknown command"
    end
  end

  def new(client_id, name, data) do
    case name in @commands_list do
      true -> %Command{ :client_id => client_id, :action => name, :data => data }
      _    -> raise "Unknown command"
    end
  end

  def update_world_state(%WorldState{} = state, commands) when is_list(commands) do
    calculate(state, commands, %{})
  end

  def calculate(%WorldState{} = state, [command|t] = commands, player_errors)
      when is_list(commands) 
      when is_map(player_errors) do

    new_state = exec_command(state, command)

    case validate(new_state) do
      { :ok } ->
        calculate(new_state, t, player_errors)

      { :errors, errors } ->
        IO.puts "validation errors => #{ inspect errors } for possible state -> #{inspect new_state}"
        new_errors = put_in(player_errors, [command.client_id], errors)
        calculate(state, t, new_errors)
    end
  end

  def calculate(%WorldState{} = state, [], player_errors), do: [state, player_errors]

  defp exec_command(%WorldState{} = state, %Command{:action => :enter, :data => %Position{}} = command) do
    new_positions = put_in(state.clients_positions, [command.client_id], command.data)

    %{ state | clients_positions: new_positions }
  end

  defp exec_command(%WorldState{} = state, %Command{:action => :move} = command) do
    client_position = state.clients_positions[command.client_id]

    new_position = case client_position.f do
      :N -> %{client_position | y: client_position.y + 1}
      :E -> %{client_position | x: client_position.x + 1}
      :S -> %{client_position | y: client_position.y - 1}
      :W -> %{client_position | x: client_position.x - 1}
      _  -> raise "unknown direction #{inspect(client_position.f)}"
    end

    new_positions = put_in(state.clients_positions, [command.client_id], new_position)
    %{ state | clients_positions: new_positions }
  end

  defp exec_command(%WorldState{} = state, %Command{:action => :turn_left} = command) do
    client_position = state.clients_positions[command.client_id]

    new_position = case client_position.f do
      :N -> %{client_position | f: :W }
      :E -> %{client_position | f: :N }
      :S -> %{client_position | f: :E }
      :W -> %{client_position | f: :S }
    end

    new_positions = put_in(state.clients_positions, [command.client_id], new_position)
    %{ state | clients_positions: new_positions }
  end

  defp exec_command(%WorldState{} = state, %Command{:action => :turn_right} = command) do
    client_position = state.clients_positions[command.client_id]

    new_position = case client_position.f do
      :N -> %{client_position | f: :E }
      :E -> %{client_position | f: :S }
      :S -> %{client_position | f: :W }
      :W -> %{client_position | f: :N }
    end

    new_positions = put_in(state.clients_positions, [command.client_id], new_position)
    %{ state | clients_positions: new_positions }
  end

  defp exec_command(%WorldState{} = state, %Command{} = command) do
    raise "NOT IMPLEMENTED CMD: #{inspect(command)}"
  end

  defp validate(%WorldState{} = state) do
    # detect client map borders overlap
    map_overlaps = Enum.map(state.clients_positions, fn {_, pos} ->
      case pos.x > 0 && pos.y > 0 && pos.x <= state.area.x && pos.y <= state.area.y do
        true  -> { :ok }
        false -> { :error, :map_overlaped  }
      end
    end)

    # detect clients positions overlap
    clients_overlaps = Enum.map(state.clients_positions, fn {client_id, pos} ->
      case Enum.any?(state.clients_positions, fn {other_id, other_pos} ->
        other_id != client_id && other_pos == pos
      end) do
        true  -> { :error, :client_overlap }
        false -> { :ok }
      end
    end)

    errors = []

    errors = map_overlaps ++ clients_overlaps |> Enum.filter(fn result ->
      case result do
        {:ok}       -> false
        {:error, _} -> true
     end
    end)

    errors = errors |> Enum.map(fn {k,v} -> v end)

    if length(errors) > 0 do
      {:errors, errors}
    else
      {:ok}
    end
  end

end
