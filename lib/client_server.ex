defmodule Spaceworld.ClientServer do

  @moduledoc """
  Сервер клиента. У каждого клиента есть сервер, задачи которого:
  — принять сообщение о том, что игра началась
  — принимать от игрового сервера тик с новым состоянием мира
  — обрабатывать состояние мира и отправлять на сервер новую игровую комманду
  """

  alias Spaceworld.GameLogic

  def start_link(client, game_server) when is_map(client) and is_pid(game_server) do 
    { :ok, spawn_link(__MODULE__, :init, [client, game_server]) } 
  end

  def init(client, game_server) do
    loop(client, game_server, [])
  end

  def loop(client, game_server, commands) do
    receive do
      {:start_game, commands} when is_list(commands) ->
        command = GameLogic.new(client.id, :enter, client.position)
        send(game_server, { :client_command_request, command })

        loop(client, game_server, commands)

      {:new_world_state, new_world_state, client_errors} ->
        next_commands = if length(client_errors) > 0 do
          # запланированный ход обломался, значит пропускаем и ждем :)
          IO.puts "oops, command failed: #{inspect client_errors}"  
          commands
        else
          next_command = GameLogic.new(client.id, hd(commands))
          # IO.puts "sending next cmd: #{ inspect next_command } "
          send(game_server, { :client_command_request, next_command })
          tl(commands)
        end

        if length(next_commands) == 0 do
          IO.puts "Game for you, client##{client.id}, is finished :D"
          send(game_server, {:client_logout, client.id, self()})
          Process.exit(self(), :finished)
        else
          loop(client, game_server, next_commands)
        end
      message ->
        IO.puts("message received by client server:\n #{ inspect(message) }")
        loop(client, game_server, commands)
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [opts] },
      type: :worker,
      restart: :permanent,
      shutdown: 3000
    }
  end

end
