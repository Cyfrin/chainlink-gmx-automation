# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderUtils`          | `executeOrder`      |
| `DepositAutomation.sol`    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `ExecuteDepositUtils` | `executeDeposit`    |
| `WithdrawalAutomation.sol` | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WithdrawalUtils`     | `executeWithdrawal` |


## Open Questions

1. (Chainlink) The DataStreamsLookup error definition has changed to account for `bytes32[] feedIds` instead of `address[] feeds`. Are there any ramifications to that on your end?
2. (Chainlink) Is the data passed into `oracleCallback` encoded off-chain, ready to be passed into whatever function is called in `performUpkeep`?
3.  (Chainlink) What is the Verifier contract?