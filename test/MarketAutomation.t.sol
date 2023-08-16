// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketAutomation, DataStore, Reader, OrderHandler} from "../src/MarketAutomation.sol";
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
    MarketAutomation internal s_marketAutomation;

    function setUp() public {
        s_marketAutomation = new MarketAutomation(DataStore(address(1)), Reader(address(2)), OrderHandler(address(3)));
    }

    //////////////
    // UNIT TESTS
    //////////////

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

    // TODO
    function test_checkLog_success() public {}
    // TODO
    function test_checkLog_LibEventLogDecoder_IncorrectLogSelector_reverts() public {}
    // TODO
    function test_checkLog_MarketAutomation_IncorrectEventName_reverts() public {}
    // TODO
    function test_checkLog_MarketAutomation_IncorrectOrderType_reverts() public {}
}
