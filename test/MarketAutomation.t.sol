// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketAutomation, DataStore, Reader, OrderHandler, Market} from "../src/MarketAutomation.sol";
import {TestData} from "./TestData.sol";
import {ILogAutomation} from "../src/chainlink/ILogAutomation.sol";
import {LibEventLogDecoder} from "../src/libraries/LibEventLogDecoder.sol";
// forge-std
import {Test, console} from "forge-std/test.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @notice MarketAutomation.withdraw(IERC20 token, address to, uint256 amount);
contract MarketAutomationTest_withdraw is Test {
    ERC20Mock internal s_token;
    MarketAutomation internal s_marketAutomation;

    function setUp() public {
        s_token = new ERC20Mock();
        s_marketAutomation = new MarketAutomation(DataStore(address(1)), Reader(address(2)), OrderHandler(address(3)));
    }

    function test_withdraw() public {
        s_token.mint(address(s_marketAutomation), 100);
        s_marketAutomation.withdraw(s_token, address(this), 100);
        assertEq(s_token.balanceOf(address(this)), 100);
        assertEq(s_token.balanceOf(address(s_marketAutomation)), 0);
    }

    function test_withdraw_nonOwner_reverts() public {
        s_token.mint(address(s_marketAutomation), 100);
        vm.prank(address(12345));
        vm.expectRevert("Ownable: caller is not the owner");
        s_marketAutomation.withdraw(s_token, address(this), 100);
    }

    // TODO: Sad path tests
}

contract MarketAutomationTest_checkLog is Test, TestData {
    uint256 internal s_forkId;

    DataStore internal s_dataStore;
    Reader internal s_reader;
    OrderHandler internal s_orderHandler;
    MarketAutomation internal s_marketAutomation;

    Market.Props[] internal s_marketProps;
    ILogAutomation.Log internal s_log;

    bytes32 internal constant KEY = keccak256(abi.encode("MarketAutomationTest_checkLog"));

    function setUp() public {
        s_forkId = vm.createSelectFork(vm.envString(ARBITRUM_GOERLI_URL_LABEL));
        s_dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        s_reader = Reader(vm.envAddress(READER_LABEL));
        s_orderHandler = OrderHandler(vm.envAddress(ORDER_HANDLER_LABEL));
        s_marketAutomation = new MarketAutomation(s_dataStore, s_reader, s_orderHandler);
        Market.Props[] memory marketProps = s_reader.getMarkets(s_dataStore, 0, 100);
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
            LibEventLogDecoder.EventLog2.selector,
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
        s_marketAutomation.checkLog(s_log, "");
    }
    // TODO

    function test_checkLog_LibEventLogDecoder_IncorrectLogSelector_reverts() public {}
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
        address[] memory shortTokenSwapPath,
        bytes calldata data
    ) public {
        bytes32 logSelector =
            logSelectorIndex ? LibEventLogDecoder.EventLog1.selector : LibEventLogDecoder.EventLog2.selector;
        ILogAutomation.Log memory log = _generateValidLog(
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
        s_marketAutomation.checkLog(log, data);
    }
}
