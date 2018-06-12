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

        test "[INVALID] create User" do
            banking_user = %User{name: "Zubair"}
            current_state = %State{users: [banking_user]}
            ExBanking.BankingServer.start_link(current_state)
            :user_already_exists = ExBanking.create_user("Zubair")
        end
    end

end
