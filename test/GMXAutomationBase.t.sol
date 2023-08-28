// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {GMXAutomationBase} from "../src/GMXAutomationBase.sol";
import {GMXAutomationBaseHelper} from "./helpers/GMXAutomationBaseHelper.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
// forge-std
import {Test, console} from "forge-std/Test.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

contract GMXAutomationBaseTest_withdraw is Test {
    ERC20Mock internal s_token;
    GMXAutomationBase internal s_gmxAutomation;

    function setUp() public {
        s_token = new ERC20Mock();
        s_gmxAutomation = new GMXAutomationBase(DataStore(address(1)), Reader(address(2)));
    }

    function test_withdraw() public {
        s_token.mint(address(s_gmxAutomation), 100);
        s_gmxAutomation.withdraw(s_token, address(this), 100);
        assertEq(s_token.balanceOf(address(this)), 100);
        assertEq(s_token.balanceOf(address(s_gmxAutomation)), 0);
    }

    function test_withdraw_nonOwner_reverts() public {
        s_token.mint(address(s_gmxAutomation), 100);
        vm.prank(address(12345));
        vm.expectRevert("Ownable: caller is not the owner");
        s_gmxAutomation.withdraw(s_token, address(this), 100);
    }

    // TODO: Sad path tests

    function test_bytes32ToString() public {
        bytes32 feedId = bytes32("1234566");
        console.logBytes32(feedId);
        console.log(string(abi.encode(feedId)));
    }
}

contract GMXAutomationBaseTest__pushPropFeedIdsToSet is Test {
// TODO every branch
}

contract GMXAutomationBaseTest__flushFeedIdsAndAddresses is Test {
    GMXAutomationBaseHelper internal s_gmxAutomation;

    mapping(string => address) internal s_feedIdToAddress;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(address(1)), Reader(address(2)));
    }

    function test__flushFeedIdsAndAddresses_shouldReturnAllFeedIdsAndAddresses() public {
        bytes32[] memory feedIds = new bytes32[](3);
        feedIds[0] = 0x14e044f932bb959cc2aa8dc1ba110c09224e639aae00264c1ffc2a0830904a3c;
        feedIds[1] = 0x4ce52cf28e49f4673198074968aeea280f13b5f897c687eb713bcfc1eeab89ba;
        feedIds[2] = 0x12be1859ee43f46bab53750915f20855f54e891f88ddd524f26a72d6f4deed1d;
        address[] memory addresses = new address[](3);
        addresses[0] = address(1);
        addresses[1] = address(2);
        addresses[2] = address(3);
        for (uint256 i = 0; i < feedIds.length; i++) {
            s_gmxAutomation.feedIdToMarketTokenMapSet(uint256(feedIds[i]), addresses[i]);
        }
        s_feedIdToAddress["0x14e044f932bb959cc2aa8dc1ba110c09224e639aae00264c1ffc2a0830904a3c"] = addresses[0];
        s_feedIdToAddress["0x4ce52cf28e49f4673198074968aeea280f13b5f897c687eb713bcfc1eeab89ba"] = addresses[1];
        s_feedIdToAddress["0x12be1859ee43f46bab53750915f20855f54e891f88ddd524f26a72d6f4deed1d"] = addresses[2];
        (string[] memory flushedFeedIds, address[] memory flushedAddresses) = s_gmxAutomation.flushFeedIdsAndAddresses();
        assertEq(flushedFeedIds.length, feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            assertEq(s_feedIdToAddress[flushedFeedIds[i]], flushedAddresses[i]);
        }
    }

    function test__flushFeedIdsAndAddresses_shouldBeEmptyAfter(address[] memory addresses) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) continue;
            s_gmxAutomation.feedIdToMarketTokenMapSet(uint256(keccak256(abi.encode(addresses[i]))), addresses[i]);
        }
        s_gmxAutomation.flushFeedIdsAndAddresses();
        assertEq(s_gmxAutomation.feedIdToMarketTokenMapLength(), 0);
    }
}

contract GMXAutomationBaseTest__toHexString is Test {
    GMXAutomationBaseHelper internal s_gmxAutomation;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(address(1)), Reader(address(2)));
    }

    function test__toHexString_shouldReturnCorrectString() public {
        bytes32 feedId = 0x14e044f932bb959cc2aa8dc1ba110c09224e639aae00264c1ffc2a0830904a3c;
        string memory expectedFeedIdString = "0x14e044f932bb959cc2aa8dc1ba110c09224e639aae00264c1ffc2a0830904a3c";
        string memory feedIdString = s_gmxAutomation.toHexString(feedId);
        assertEq(feedIdString, expectedFeedIdString);
        feedId = 0x0000000000000000000000000000000000000000000000000000000000000000;
        expectedFeedIdString = "0x0000000000000000000000000000000000000000000000000000000000000000";
        feedIdString = s_gmxAutomation.toHexString(feedId);
        assertEq(feedIdString, expectedFeedIdString);
        feedId = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        expectedFeedIdString = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        feedIdString = s_gmxAutomation.toHexString(feedId);
        assertEq(feedIdString, expectedFeedIdString);
    }
}
