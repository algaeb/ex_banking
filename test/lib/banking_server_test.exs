defmodule BankingServerTest do
  use ExUnit.Case

  alias ExBanking
  alias ExBanking.BankingServer.{State}
  alias ExBanking.{User, Balance}

  describe "Banking Server" do
    test "[VALID] create User" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
    end

    test "[INVALID] create User/ user_already exists" do
      banking_user = %User{name: "Zubair"}
      current_state = %State{users: [banking_user]}
      ExBanking.BankingServer.start_link(current_state)
      :user_already_exists = ExBanking.create_user("Zubair")
    end

    test "[VALID] Deposit amount/ first deposit" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
      {:ok, 10} = ExBanking.deposit("Zubair", 10, "$")
    end

    test "[INVALID] Deposit amount/ user does not exist" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zub")
      :user_does_not_exist = ExBanking.deposit("Zubair", 10, "$")
    end

    test "[VALID] Deposit amount/ 2nd deposit" do
      banking_user1 = %User{balances: [%Balance{amount: 10, currency: "$"}], name: "Zubair"}

      banking_user2 = %User{
        balances: [%Balance{amount: 100, currency: "$"}, %Balance{amount: 50, currency: "@"}],
        name: "Zack"
      }

      current_state = %State{users: [banking_user1, banking_user2]}
      ExBanking.BankingServer.start_link(current_state)
      {:ok, 110} = ExBanking.deposit("Zack", 10, "$")
    end

    test "[VALID] Withdraw money" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
      {:ok, 10} = ExBanking.deposit("Zubair", 10, "$")
      {:ok, 5} = ExBanking.withdraw("Zubair", 5, "$")
    end

    test "[VALID] Withdraw money gives not_enough_money" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
      {:ok, 10} = ExBanking.deposit("Zubair", 10, "$")
      :not_enough_money = ExBanking.withdraw("Zubair", 15, "$")
    end

    test "[VALID] GetUser amount" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
      {:ok, 10} = ExBanking.deposit("Zubair", 10, "$")
      {:ok, 10} = ExBanking.get_balance("Zubair", "$")
    end

    test "[INVALID] GetUser amount/ user doesnt exist" do
      ExBanking.BankingServer.start_link(%State{})
      :ok = ExBanking.create_user("Zubair")
      {:ok, 10} = ExBanking.deposit("Zubair", 10, "$")
      {:ok, 10} != ExBanking.get_balance("alpha", "$")
      :user_does_not_exist = ExBanking.get_balance("alpha", "$")
    end
  end
end
