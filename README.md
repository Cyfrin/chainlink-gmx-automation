# Chainlink <> GMX Automation

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderUtils`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderUtils`          | `executeOrder`      |
| `DepositAutomation.sol`    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `ExecuteDepositUtils` | `executeDeposit`    |
| `WithdrawalAutomation.sol` | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WithdrawalUtils`     | `executeWithdrawal` |

# Questions

1. What should the Lookup revert error be? (name and structure)
   1. FeedLookup
   2. 
2. What should the functions be called? Is `checkLog`, `oracleCallback` and `performUpkeep` correct?
3. Is there a specific interface I should use for the above?
   1. Interface FeedLookupCompatible
   2. AutomationCompatibleInterface

4. What is the relationship between the fields in the Lookup error, and the input to oracleCallback?
   1. valuesArray - is the whole signed OCR3 report
      1. Same length as feedIds emitted from Lookup
      2. Using same `verify` on each item in the values array https://github.com/smartcontractkit/chainlink/blob/d166ad94d817c5b1436b3901965d0db02f21fedf/contracts/src/v0.8/llo-feeds/Verifier.sol#L202
         1. Get reportData field from that
      3. 
5. The data we need in `performData` is:
   1. `key` : emitted in `checkLog`
   2. `realtimeFeedTokens` : emitted in `checkLog`
   3. `realtimeFeedData` : Where does this come from, and where to access it?