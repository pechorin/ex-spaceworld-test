defmodule Spaceworld.NasaSupervisor do
  use Supervisor

  @moduledoc """
  Супервизор серверов клиентов.
  TODO: использовать DynamicSupervisor
  """

  alias Spaceworld.ClientServer

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def start_client(supervisor, game_server, client)
  when is_pid(supervisor) and is_pid(game_server) and is_map(client) do
    Supervisor.start_child(supervisor, [client, game_server])
  end

  def init(:ok) do
    tree = [
      Supervisor.Spec.worker(ClientServer, [])
    ]

    Supervisor.init(tree, strategy: :simple_one_for_one)
  end

end
