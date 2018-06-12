defmodule ExBanking.BankingServer do
  use GenServer

  @processname :banking

  defmodule State do
    defstruct users: [], currencies: []
  end

  #Client interface
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @processname)
  end

  def create_user(name) do
    case lookup_user(name) do
      :ok ->
        GenServer.call(@processname, {:create_user, name})
      :error -> :user_already_exists  
    end
  end

  def lookup_user(username) do
    GenServer.call(@processname, {:lookup_user, username})
  end

  #Server interface
  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_user, user}, _from, state) do
    new_state = %{state | users: [user]}
    {:reply, :ok, new_state}
  end

  def handle_call({:lookup_user, username}, _from, state) do
     list = Enum.filter(state.users, fn n -> 
          n.name == username
    end)
      case list  do
        [] -> {:reply, :ok, state}
        list -> {:reply, :error, state}
      end        
  end
end
