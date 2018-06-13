defmodule ExBanking.BankingServer do
  use GenServer

  alias ExBanking.{User, Balance}

  @processname :banking

  defmodule State do
    defstruct users: [], currencies: []
  end

  # Client interface
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @processname)
  end

  def create_user(name) when is_bitstring(name) do
    case lookup_user(name) do
      [] ->
        user = %User{name: name}
        GenServer.call(@processname, {:create_user, user})

      list ->
        :user_already_exists
    end
  end
  def create_user(_), do: :wrong_arguments

  def deposit(name, amount, currency) when is_bitstring(name) and  is_number(amount) and is_bitstring(currency) do
    case lookup_user(name) do
      [] -> :user_does_not_exist
      [user] -> GenServer.call(@processname, {:deposit, {user, amount, currency}})
    end
  end
  def deposit(_, _, _), do: :wrong_arguments

  def withdraw(name, amount, currency) when is_bitstring(name) and  is_number(amount) and is_bitstring(currency) do
    case lookup_user(name) do
      [] ->
        :user_does_not_exist

      [user] ->
        GenServer.call(@processname, {:withdraw, {user, amount, currency}})
    end
  end
  def withdraw(_, _, _), do: :wrong_arguments

  def send_money(from_name, to_name, amount, currency) when is_bitstring(from_name) and is_bitstring(to_name) and is_number(amount) and is_bitstring(currency) do
    case lookup_user(from_name) do
      [] ->
        :sender_does_not_exist

      [from_user] ->
        case lookup_user(to_name) do
          [] ->
            :receiver_does_not_exist

          [to_user] ->
            with {:ok, from_amount} <-
                   GenServer.call(@processname, {:withdraw, {from_user, amount, currency}}),
                 {:ok, to_amount} <-
                   GenServer.call(@processname, {:deposit, {to_user, amount, currency}}) do
              {:ok, from_amount, to_amount}
            end
        end
    end
  end
  def send(_, _, _, _), do: :wrong_arguments

  def get_balance(name, currency) when is_bitstring(name) and is_bitstring(currency) do
    case lookup_user(name) do
      [] ->
        :user_does_not_exist

      [user] ->
        GenServer.call(@processname, {:get_user, {user, currency}})
    end
  end
  def get_balance(_, _), do: :wrong_arguments

  def lookup_user(username) do
    GenServer.call(@processname, {:lookup_user, username})
  end

  # Server interface
  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_user, user}, _from, state) do
    new_state = %{state | users: state.users ++ [user]}
    {:reply, :ok, new_state}
  end

  def handle_call({:deposit, {user, amount, currency}}, _from, state) do
    {amount, new_state} =
      case Enum.filter(user.balances, fn n ->
             n.currency == currency
           end) do
        [] ->
          new_user = %{
            user
            | balances: user.balances ++ [%Balance{amount: amount, currency: currency}]
          }

          old_state = %{state | users: state.users -- [user]}
          new_state = %{old_state | users: old_state.users ++ [new_user]}
          {amount, new_state}

        [result] ->
          total_amount = result.amount + amount
          new_balance = %{result | amount: total_amount}
          rm_bal = %{user | balances: user.balances -- [result]}
          upd_user = %{rm_bal | balances: rm_bal.balances ++ [new_balance]}

          old_state = %{state | users: state.users -- [user]}
          new_state = %{old_state | users: old_state.users ++ [upd_user]}
          {total_amount, new_state}
      end

    {:reply, {:ok, amount}, new_state}
  end

  def handle_call({:withdraw, {user, amount, currency}}, _from, state) do
    case Enum.filter(user.balances, fn n ->
           n.currency == currency
         end) do
      [] ->
        {:reply, :not_enough_money, state}

      [result] ->
        total_amount = result.amount - amount

        cond do
          total_amount < 0 ->
            {:reply, :not_enough_money, state}

          true ->
            new_balance = %{result | amount: total_amount}
            rm_bal = %{user | balances: user.balances -- [result]}
            upd_user = %{rm_bal | balances: rm_bal.balances ++ [new_balance]}

            old_state = %{state | users: state.users -- [user]}
            new_state = %{old_state | users: old_state.users ++ [upd_user]}
            {:reply, {:ok, total_amount}, new_state}
        end
    end
  end

  def handle_call({:get_user, {user, currency}}, _from, state) do
    case Enum.filter(user.balances, fn n ->
           n.currency == currency
         end) do
      [] -> {:reply, {:ok, 0}, state}
      [result] -> {:reply, {:ok, result.amount}, state}
    end
  end

  def handle_call({:lookup_user, username}, _from, state) do
    list =
      Enum.filter(state.users, fn n ->
        n.name == username
      end)

    {:reply, list, state}
  end
end
