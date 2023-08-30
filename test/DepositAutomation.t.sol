// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DepositAutomation} from "../src/DepositAutomation.sol";
import {TestData} from "./TestData.sol";
import {LibGMXEventLogDecoder} from "../src/libraries/LibGMXEventLogDecoder.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {DepositHandler} from "gmx-synthetics/exchange/DepositHandler.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
import {OracleUtils} from "gmx-synthetics/oracle/OracleUtils.sol";
// chainlink
import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";
import {FeedLookupCompatibleInterface} from "chainlink/dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol";
// forge-std
import {Test, console} from "forge-std/Test.sol";

contract DepositAutomation_End2End is Test, TestData {
    uint256 internal s_forkId;

    DataStore internal s_dataStore;
    Reader internal s_reader;
    DepositHandler internal s_depositHandler;
    DepositAutomation internal s_depositAutomation;

    Market.Props[] internal s_marketProps;
    Log internal s_log;

    bytes32 internal constant KEY = keccak256(abi.encode("DepositAutomationTest_checkLog"));

    function setUp() public {
        s_forkId = vm.createSelectFork(vm.envString(ARBITRUM_GOERLI_URL_LABEL));
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_depositHandler = DepositHandler(vm.envAddress(DEPOSIT_HANDLER_LABEL));
        s_depositAutomation = new DepositAutomation(s_dataStore, s_reader, s_depositHandler);
        Market.Props[] memory marketProps = s_reader.getMarkets(s_dataStore, 0, 1);
        for (uint256 i = 0; i < marketProps.length; i++) {
            s_marketProps.push(marketProps[i]);
        }

        address market = s_marketProps[0].marketToken;
        address[] memory swapPath = new address[](s_marketProps.length);
        for (uint256 i = 0; i < s_marketProps.length; i++) {
            swapPath[i] = s_marketProps[i].marketToken;
        }
        s_log = _generateValidLog(
            address(this),
            block.number,
            LibGMXEventLogDecoder.EventLog1.selector,
            "DepositCreated",
            market,
            swapPath,
            KEY,
            2,
            swapPath,
            swapPath
        );
    }

    function test_DepositAutomation_End2End_success() public {
        string[] memory expectedFeedIds = new string[](2);
        expectedFeedIds[0] = vm.envString("MARKET_FORK_TEST_FEED_ID_0");
        expectedFeedIds[1] = vm.envString("MARKET_FORK_TEST_FEED_ID_1");
        address[] memory expectedMarketAddresses = new address[](2);
        expectedMarketAddresses[0] = vm.envAddress("MARKET_ADDRESS_0");
        expectedMarketAddresses[1] = vm.envAddress("MARKET_ADDRESS_1");
        // Expected revert
        bytes memory encodedRevert = abi.encodeWithSelector(
            FeedLookupCompatibleInterface.FeedLookup.selector,
            "feedIdHex",
            expectedFeedIds,
            "blockNumber",
            block.number,
            abi.encode(KEY, expectedMarketAddresses)
        );
        vm.expectRevert(encodedRevert);
        s_depositAutomation.checkLog(s_log, EMPTY_BYTES);

        // Off-chain, decode revert and construct callback data
        bytes[] memory values = new bytes[](2);
        values[0] = abi.encode(expectedFeedIds[0]);
        values[1] = abi.encode(expectedFeedIds[1]);
        (bool result, bytes memory performData) =
            s_depositAutomation.checkCallback(values, abi.encode(KEY, expectedMarketAddresses));
        assertTrue(result);
        assertEq(performData, abi.encode(values, abi.encode(KEY, expectedMarketAddresses)));

        // Pass performData into performUpkeep
        OracleUtils.SetPricesParams memory expectedParams;
        expectedParams.realtimeFeedTokens = expectedMarketAddresses;
        expectedParams.realtimeFeedData = values;
        vm.mockCall(
            address(s_depositHandler),
            abi.encodeWithSelector(DepositHandler.executeDeposit.selector, KEY, expectedParams),
            abi.encode("")
        );
        s_depositAutomation.performUpkeep(performData);
    }
}

contract DepositAutomationTest_checkLog is Test, TestData {
    uint256 internal s_forkId;

    DataStore internal s_dataStore;
    Reader internal s_reader;
    DepositHandler internal s_depositHandler;
    DepositAutomation internal s_depositAutomation;

    Market.Props[] internal s_marketProps;
    Log internal s_log;

    bytes32 internal constant KEY = keccak256(abi.encode("DepositAutomationTest_checkLog"));

    function setUp() public {
        s_forkId = vm.createSelectFork(vm.envString(ARBITRUM_GOERLI_URL_LABEL));
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_depositHandler = DepositHandler(vm.envAddress(DEPOSIT_HANDLER_LABEL));
        s_depositAutomation = new DepositAutomation(s_dataStore, s_reader, s_depositHandler);
        Market.Props[] memory marketProps = s_reader.getMarkets(s_dataStore, 0, 1);
        for (uint256 i = 0; i < marketProps.length; i++) {
            s_marketProps.push(marketProps[i]);
        }

        address market = s_marketProps[0].marketToken;
        address[] memory swapPath = new address[](s_marketProps.length);
        for (uint256 i = 0; i < s_marketProps.length; i++) {
            swapPath[i] = s_marketProps[i].marketToken;
        }
        s_log = _generateValidLog(
            address(this),
            block.number,
            LibGMXEventLogDecoder.EventLog1.selector,
            "DepositCreated",
            market,
            swapPath,
            KEY,
            2,
            swapPath,
            swapPath
        );
    }

    ///////////////////////////
    // UNIT TESTS
    ///////////////////////////

    function test_checkLog_success() public {
        string[] memory expectedFeedIds = new string[](2);
        expectedFeedIds[0] = vm.envString("MARKET_FORK_TEST_FEED_ID_0");
        expectedFeedIds[1] = vm.envString("MARKET_FORK_TEST_FEED_ID_1");
        address[] memory expectedMarketAddresses = new address[](2);
        expectedMarketAddresses[0] = vm.envAddress("MARKET_ADDRESS_0");
        expectedMarketAddresses[1] = vm.envAddress("MARKET_ADDRESS_1");
        vm.expectRevert(
            abi.encodeWithSelector(
                FeedLookupCompatibleInterface.FeedLookup.selector,
                "feedIdHex",
                expectedFeedIds,
                "blockNumber",
                block.number,
                abi.encode(KEY, expectedMarketAddresses)
            )
        );
        s_depositAutomation.checkLog(s_log, EMPTY_BYTES);
    }

    function test_checkLog_IncorrectEventName() public {
        string memory incorrectLogName = "WithdrawalCreated";
        address[] memory swapPath;
        s_log = _generateValidLog(
            address(this),
            block.number,
            LibGMXEventLogDecoder.EventLog1.selector,
            incorrectLogName,
            s_marketProps[0].marketToken,
            swapPath,
            KEY,
            2,
            swapPath,
            swapPath
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                DepositAutomation.DepositAutomation_IncorrectEventName.selector, incorrectLogName, "DepositCreated"
            )
        );
        s_depositAutomation.checkLog(s_log, EMPTY_BYTES);
    }

    ///////////////////////////
    // FUZZ TESTS
    ///////////////////////////

    function test_fuzz_checkLog_revertsInEveryCase(
        address msgSender,
        uint256 blockNumber,
        bool logSelectorIndex,
        string memory eventName,
        address market,
        address[] memory swapPath,
        bytes32 key,
        uint256 orderType,
        address[] memory longTokenSwapPath,
        address[] memory shortTokenSwapPath
    ) public {
        bytes32 logSelector =
            logSelectorIndex ? LibGMXEventLogDecoder.EventLog1.selector : LibGMXEventLogDecoder.EventLog2.selector;
        Log memory log = _generateValidLog(
            msgSender,
            blockNumber,
            logSelector,
            eventName,
            market,
            swapPath,
            key,
            orderType,
            longTokenSwapPath,
            shortTokenSwapPath
        );
        vm.expectRevert();
        s_depositAutomation.checkLog(log, EMPTY_BYTES);
    }
}

contract DepositAutomationTest_checkCallback is Test, TestData {
    DataStore internal s_dataStore;
    Reader internal s_reader;
    DepositHandler internal s_depositHandler;
    DepositAutomation internal s_depositAutomation;

    function setUp() public {
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_depositHandler = DepositHandler(vm.envAddress(ORDER_HANDLER_LABEL));
        s_depositAutomation = new DepositAutomation(s_dataStore, s_reader, s_depositHandler);
    }

    function test_checkCallback_success(bytes[] calldata values, bytes calldata extraData) public {
        (bool result, bytes memory data) = s_depositAutomation.checkCallback(values, extraData);
        assertTrue(result);
        assertEq(data, abi.encode(values, extraData));
    }
}

contract DepositAutomationTest_performUpkeep is Test, TestData {
    DataStore internal s_dataStore;
    Reader internal s_reader;
    DepositHandler internal s_depositHandler;
    DepositAutomation internal s_depositAutomation;

    function setUp() public {
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_depositHandler = DepositHandler(vm.envAddress(ORDER_HANDLER_LABEL));
        s_depositAutomation = new DepositAutomation(s_dataStore, s_reader, s_depositHandler);
    }

    function test_performUpkeep_success(bytes[] memory values, bytes32 key, address[] memory marketAddresses) public {
        bytes memory extraData = abi.encode(key, marketAddresses);
        bytes memory performData = abi.encode(values, extraData);
        OracleUtils.SetPricesParams memory expectedParams;
        expectedParams.realtimeFeedTokens = marketAddresses;
        expectedParams.realtimeFeedData = values;
        vm.mockCall(
            address(s_depositHandler),
            abi.encodeWithSelector(DepositHandler.executeDeposit.selector, key, expectedParams),
            abi.encode("")
        );
        s_depositAutomation.performUpkeep(performData);
    }
}
