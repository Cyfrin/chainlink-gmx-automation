# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderHandler`          | `executeOrder`      |
| [`DepositAutomation.sol`](./src/DepositAutomation.sol)    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `DepositHandler` | `executeDeposit`    |
| [`WithdrawalAutomation.sol`](./src/WithdrawalAutomation.sol) | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WathdrawalHandler`     | `executeWithdrawal` |

# Questions

1. (GMX) Do you need realtimeFeedTokens? Or is the data inside realtimeFeedData enough?