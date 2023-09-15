// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestData} from "./TestData.sol";
// gmx-synthetics
import {GMXAutomationBase} from "../src/GMXAutomationBase.sol";
import {GMXAutomationBaseHelper} from "./helpers/GMXAutomationBaseHelper.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
import {Keys} from "gmx-synthetics/data/Keys.sol";
// forge-std
import {Test, console} from "forge-std/Test.sol";
// openzeppelin
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

contract GMXAutomationBaseTest_modifierOnlyForwarder is Test, TestData {
    GMXAutomationBaseHelper internal s_gmxAutomation;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(address(1)), Reader(address(2)));
        s_gmxAutomation.setForwarderAddress(FORWARDER);
    }

    function test_modifierOnlyForwarder_success() public {
        vm.prank(FORWARDER);
        s_gmxAutomation.modifierOnlyForwarder();
    }

    function test_modifierOnlyForwarder_nonForwarder_reverts() public {
        vm.expectRevert(GMXAutomationBase.GMXAutomationBase_OnlyForwarder.selector);
        s_gmxAutomation.modifierOnlyForwarder();
    }
}

contract GMXAutomationBaseTest_setForwarderAddress is Test {
    GMXAutomationBase internal s_gmxAutomation;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBase(DataStore(address(1)), Reader(address(2)));
    }

    function test_setForwarderAddress() public {
        s_gmxAutomation.setForwarderAddress(address(12345));
        assertEq(s_gmxAutomation.s_forwarderAddress(), address(12345));
    }

    function test_setForwarderAddress_nonOwner_reverts() public {
        vm.prank(address(12345));
        vm.expectRevert("Ownable: caller is not the owner");
        s_gmxAutomation.setForwarderAddress(address(12345));
    }
}

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

contract GMXAutomationBaseTest__addPropsToMapping is Test {
    GMXAutomationBaseHelper internal s_gmxAutomation;

    address internal constant DATA_STORE_ADDRESS = address(1);

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(DATA_STORE_ADDRESS), Reader(address(2)));
    }

    function test__addPropsToMapping_success() public {
        Market.Props memory marketProps;
        marketProps.indexToken = address(1);
        marketProps.longToken = address(2);
        marketProps.shortToken = address(3);

        bytes32 indexTokenFeedId = bytes32("99");
        bytes32 longTokenFeedId = bytes32("100");
        bytes32 shortTokenFeedId = bytes32("101");
        vm.mockCall(
            DATA_STORE_ADDRESS,
            abi.encodeWithSelector(DataStore.getBytes32.selector, Keys.realtimeFeedIdKey(marketProps.indexToken)),
            abi.encode(indexTokenFeedId)
        );
        vm.mockCall(
            DATA_STORE_ADDRESS,
            abi.encodeWithSelector(DataStore.getBytes32.selector, Keys.realtimeFeedIdKey(marketProps.longToken)),
            abi.encode(longTokenFeedId)
        );
        vm.mockCall(
            DATA_STORE_ADDRESS,
            abi.encodeWithSelector(DataStore.getBytes32.selector, Keys.realtimeFeedIdKey(marketProps.shortToken)),
            abi.encode(shortTokenFeedId)
        );
        s_gmxAutomation.addPropsToMapping(marketProps);

        assertEq(s_gmxAutomation.feedIdToMarketTokenMapLength(), 3);
        assertEq(s_gmxAutomation.feedIdToMarketTokenMapGet(uint256(indexTokenFeedId)), marketProps.indexToken);
        assertEq(s_gmxAutomation.feedIdToMarketTokenMapGet(uint256(longTokenFeedId)), marketProps.longToken);
        assertEq(s_gmxAutomation.feedIdToMarketTokenMapGet(uint256(shortTokenFeedId)), marketProps.shortToken);
    }
}

contract GMXAutomationBaseTest__flushMapping is Test {
    GMXAutomationBaseHelper internal s_gmxAutomation;

    mapping(string => address) internal s_feedIdToAddress;

    function setUp() public {
        s_gmxAutomation = new GMXAutomationBaseHelper(DataStore(address(1)), Reader(address(2)));
    }

    function test__flushMapping_shouldReturnAllFeedIdsAndAddresses() public {
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
        (string[] memory flushedFeedIds, address[] memory flushedAddresses) = s_gmxAutomation.flushMapping();
        assertEq(flushedFeedIds.length, feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            assertEq(s_feedIdToAddress[flushedFeedIds[i]], flushedAddresses[i]);
        }
    }

    function test__flushMapping_shouldBeEmptyAfter(address[] memory addresses) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) continue;
            s_gmxAutomation.feedIdToMarketTokenMapSet(uint256(keccak256(abi.encode(addresses[i]))), addresses[i]);
        }
        s_gmxAutomation.flushMapping();
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
