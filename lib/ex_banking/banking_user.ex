defmodule ExBanking.User do
  defstruct name: nil, balances: []
end

defmodule ExBanking.Balance do
  defstruct currency: nil, amount: 0
end
