// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketAutomation} from "../src/MarketAutomation.sol";
import {TestData} from "./TestData.sol";
import {LibGMXEventLogDecoder} from "../src/libraries/LibGMXEventLogDecoder.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {OrderHandler} from "gmx-synthetics/exchange/OrderHandler.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
// chainlink
import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";
import {FeedLookupCompatibleInterface} from "chainlink/dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol";
// forge-std
import {Test, console} from "forge-std/test.sol";

contract MarketAutomationTest_checkLog is Test, TestData {
    uint256 internal s_forkId;

    DataStore internal s_dataStore;
    Reader internal s_reader;
    OrderHandler internal s_orderHandler;
    MarketAutomation internal s_marketAutomation;

    Market.Props[] internal s_marketProps;
    Log internal s_log;

    bytes32 internal constant KEY = keccak256(abi.encode("MarketAutomationTest_checkLog"));

    function setUp() public {
        s_forkId = vm.createSelectFork(vm.envString(ARBITRUM_GOERLI_URL_LABEL));
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_orderHandler = OrderHandler(vm.envAddress(ORDER_HANDLER_LABEL));
        s_marketAutomation = new MarketAutomation(s_dataStore, s_reader, s_orderHandler);
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
            LibGMXEventLogDecoder.EventLog2.selector,
            "OrderCreated",
            market,
            swapPath,
            KEY,
            2,
            swapPath,
            swapPath
        );
    }

    //////////////
    // UNIT TESTS
    //////////////

    // TODO
    function test_checkLog_success() public {
        string[] memory expectedFeedIds = new string[](2);
        expectedFeedIds[0] = vm.envString("MARKET_FORK_TEST_FEED_ID_0");
        expectedFeedIds[1] = vm.envString("MARKET_FORK_TEST_FEED_ID_1");
        vm.expectRevert(
            abi.encodeWithSelector(
                FeedLookupCompatibleInterface.FeedLookup.selector,
                "feedIDHex",
                expectedFeedIds,
                "BlockNumber",
                block.number,
                abi.encode(KEY)
            )
        );
        s_marketAutomation.checkLog(s_log);
    }
    // TODO

    function test_checkLog_LibGMXEventLogDecoder_IncorrectLogSelector_reverts() public {}
    // TODO
    function test_checkLog_MarketAutomation_IncorrectEventName_reverts() public {}
    // TODO
    function test_checkLog_MarketAutomation_IncorrectOrderType_reverts() public {}

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
        s_marketAutomation.checkLog(log);
    }
}
