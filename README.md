# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderUtils`          | `executeOrder`      |
| `DepositAutomation.sol`    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `ExecuteDepositUtils` | `executeDeposit`    |
| `WithdrawalAutomation.sol` | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WithdrawalUtils`     | `executeWithdrawal` |


## Open Questions

1. (GMX) `LibEventDecoder` currently retrieves the following fields from the EventData. Are there any missing?
   - bytes32 key,
   - address market,
   - uint256 orderType,
   - address[] memory swapPath,
   - address[] memory longTokenSwapPath,
   - address[] memory shortTokenSwapPath
2. (GMX) Currently, the `MarketAutomation` contract only uses the following fields from the EventData, does it need to account for all?
   - key
   - market
   - orderType
   - swapPath
3. (GMX) Are there any cases where the `Reader.getMarket` returns a zero address?
4. (GMX) Are there any cases where the `DataStore.getBytes32` returns a zero address?
5. (GMX) Once the addresses are retrieved from the event, is this the correct feedId retrieval: `i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketToken));`?
6. (Chainlink) The DataStreamsLookup error definition has changed to account for `bytes32[] feedIds` instead of `address[] feeds`. Are there any ramifications to that on your end?
7. (GMX) What exactly is called in `performUpkeep`? (Contract and function)
8. (Chainlink) Is the data passed into `oracleCallback` encoded off-chain, ready to be passed into whatever function is called in `performUpkeep`?