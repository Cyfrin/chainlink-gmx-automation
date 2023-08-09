// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketDecrease, DataStore, Reader} from "../src/MarketDecrease.sol";
// forge-std
import {Test, console} from "forge-std/test.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract MarketDecreaseTest_withdrawTokens is Test {
    ERC20Mock internal s_token;
    MarketDecrease internal s_marketDecrease;

    function setUp() public {
        s_token = new ERC20Mock();
        s_marketDecrease = new MarketDecrease(DataStore(address(1)), Reader(address(2)));
    }

    function test_withdrawTokens() public {
        s_token.mint(address(s_marketDecrease), 100);
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = s_token;
        s_marketDecrease.withdrawTokens(tokens, address(this));
        assertEq(s_token.balanceOf(address(this)), 100);
        assertEq(s_token.balanceOf(address(s_marketDecrease)), 0);
    }

    // TODO: Sad path tests
}
