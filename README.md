# Chainlink <> GMX Automation

High-Frequency GMX Automation.

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| `MarketAutomation.sol`     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderUtils`          | `executeOrder`      |
| `DepositAutomation.sol`    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `ExecuteDepositUtils` | `executeDeposit`    |
| `WithdrawalAutomation.sol` | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WithdrawalUtils`     | `executeWithdrawal` |


## Open Questions

1. `LibEventDecoder` currently retrieves the following fields from the EventData. Are there any missing?
   - bytes32 key,
   - address market,
   - uint256 orderType,
   - address[] memory swapPath,
   - address[] memory longTokenSwapPath,
   - address[] memory shortTokenSwapPath
2. Once the addresses are retrieved from the event, where and how can the feedIds be retrieved?
4. What exactly is called in `performUpkeep`? (Contract and function)
5. Is the data passed into `oracleCallback` encoded off-chain, ready for whatever function is called in `performUpkeep`?