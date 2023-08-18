# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderUtils`          | `executeOrder`      |
| `DepositAutomation.sol`    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `ExecuteDepositUtils` | `executeDeposit`    |
| `WithdrawalAutomation.sol` | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WithdrawalUtils`     | `executeWithdrawal` |
