// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {GMXAutomationBase} from "../src/GMXAutomationBase.sol";
import {GMXAutomationBaseHelper} from "./helpers/GMXAutomationBaseHelper.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
// forge-std
import {Test, console} from "forge-std/test.sol";
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

contract GMXAutomationBaseTest__flushFeedIdSet is Test {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    GMXAutomationBaseHelper internal s_gmxAutomation;
    EnumerableSet.Bytes32Set internal s_testSet;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(address(1)), Reader(address(2)));
    }

    function test__flushFeedIdSet_shouldReturnAllFeedIds() public {
        bytes32[] memory feedIds = new bytes32[](3);
        feedIds[0] = bytes32("1234566");
        feedIds[1] = bytes32("1234567");
        feedIds[2] = bytes32("1234568");
        for (uint256 i = 0; i < feedIds.length; i++) {
            s_testSet.add(feedIds[i]);
            s_gmxAutomation.feedIdSetAdd(feedIds[i]);
        }
        string[] memory flushedFeedIds = s_gmxAutomation.flushFeedIdSet();
        assertEq(flushedFeedIds.length, feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            bytes memory flushedFeedIdBytes = bytes(flushedFeedIds[i]);
            bytes32 flushedFeedId = abi.decode(flushedFeedIdBytes, (bytes32));
            assertTrue(s_testSet.contains(flushedFeedId));
        }
    }

    function test__flushFeedIdSet_shouldBeEmptyAfter(bytes32[] memory feedIds) public {
        for (uint256 i = 0; i < feedIds.length; i++) {
            if (feedIds[i] == bytes32(0)) continue;
            s_gmxAutomation.feedIdSetAdd(feedIds[i]);
        }
        string[] memory flushedFeedIds = s_gmxAutomation.flushFeedIdSet();
        assertEq(s_gmxAutomation.feedIdSetLength(), 0);
    }
}
