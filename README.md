# Chainlink <> GMX Automation

## Prerequisites
1. Git
2. [Foundry](https://book.getfoundry.sh/)
3. [Yarn](https://yarnpkg.com/)
4. Arbitrum Goerli RPC URL

## Installation

1. Clone the repo:
   ```
   git clone git@github.com:Cyfrin/chainlink-gmx-automation.git
   ```
2. Install dependencies:
   ```
   cd chainlink-gmx-automation
   forge install
   ```
3. Install GMX dependencies:
   ```
   cd lib/gmx-synthetics
   yarn
   cd ../..
   ```
4. Build:
   ```
   forge build
   ```
5. Setup environment:
   ```
   cp .env.example .env
   ```
   Enter your RPC URL into the `ARBITRUM_GOERLI_URL` in .env
6. Run the tests:
   ```
   forge test
   ```

## Deployment

1. Ensure that your `.env` file is fully populated, and the address for you PRIVATE_KEY variable is funded with Arbitrum Goerli ETH
2. To deploy the `DepositAutomation` contract, run the following script in the terminal:
   ```
   forge script script/DeployDepositAutomation.s.sol --rpc-url $ARBITRUM_GOERLI_URL --broadcast
   ```

   Other available scripts are `script/DeployMarketAutomation.s.sol` and `script/DeployWithdrawalAutomation.s.sol`

## Automation Contracts

| Automation Contract      | Event           | Log Type      | Log Name          | OrderType Enum | Execution Contract  | Execute Function  |
|--------------------------|-----------------|---------------|-------------------|------|---------------------|-------------------|
| [`MarketAutomation.sol`](./src/MarketAutomation.sol)     | Market Swap     | `emitEventLog2` | `OrderCreated`      |   0  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Increase | `emitEventLog2` | `OrderCreated`      |   2  | `OrderHandler`          | `executeOrder`      |
| -                        | Market Decrease | `emitEventLog2` | `OrderCreated`      |   4  | `OrderHandler`          | `executeOrder`      |
| [`DepositAutomation.sol`](./src/DepositAutomation.sol)    | Deposit         | `emitEventLog1` | `DepositCreated`    |   -  | `DepositHandler` | `executeDeposit`    |
| [`WithdrawalAutomation.sol`](./src/WithdrawalAutomation.sol) | Withdrawal      | `emitEventLog1` | `WithdrawalCreated` |   -  | `WathdrawalHandler`     | `executeWithdrawal` |