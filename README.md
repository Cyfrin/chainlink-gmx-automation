# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderHandler`          | `executeOrder`      |
| [`DepositAutomation.sol`](./src/DepositAutomation.sol)    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `DepositHandler` | `executeDeposit`    |
| [`WithdrawalAutomation.sol`](./src/WithdrawalAutomation.sol) | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WathdrawalHandler`     | `executeWithdrawal` |

# Questions

1. What is the relationship between the fields in the Lookup error, and the input to oracleCallback?
   1. valuesArray - is the whole signed OCR3 report
      1. Same length as feedIds emitted from Lookup
      2. Using same `verify` on each item in the values array https://github.com/smartcontractkit/chainlink/blob/d166ad94d817c5b1436b3901965d0db02f21fedf/contracts/src/v0.8/llo-feeds/Verifier.sol#L202
         1. Get reportData field from that - waiting on details of how this is encoded from Chainlink