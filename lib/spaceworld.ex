defmodule Spaceworld do

  alias Spaceworld.Client
  alias Spaceworld.GameServer
  alias Spaceworld.GameServer.Point
  alias Spaceworld.GameServer.Position

  @fps 1000

  @moduledoc """
  Начальная точка игры. Создает игровой сервер, здесь же создает игроков и коннектит их к серверу (никакого интерактива, лол).
  Тут же создается тик-fps-сервер, которые шлет тики в игровой сервер, который в свою очередь принимает евенты от клиентов, а при тике - обновляет состояние мира.
  """

  @doc """
  Команды, пока, заполняю руками :)
  """
  def start do
    area = %Point{x: 10, y: 10}
    { :ok, game } = GameServer.start_link(area)

    client_a_commands = [ 
      :move,
      :move,
      :turn_left,
      :turn_left,
      :move,
      :move,
      :move,
      :turn_left,
      :move,
      :move,
      :move,
      :move,
      :move,
      :move,
      :move,
      :move,
      :move,
      :move,
      :turn_left,
      :move,
      :move
    ]

    client_b_commands = [ 
      :move,
      :move,
      :turn_left,
      :turn_left,
      :move
    ]

    client_a = %Client{id: 1, position: %Position{x: 1, y: 10, f: :N}}
    client_b = %Client{id: 2, position: %Position{x: 10, y: 10, f: :N}}

    send(game, {:client_login, client_a, client_a_commands})
    send(game, {:client_login, client_b, client_b_commands})

    Spaceworld.TickServer.start_link(@fps, length(client_a_commands) + 10, game)
  end

end
