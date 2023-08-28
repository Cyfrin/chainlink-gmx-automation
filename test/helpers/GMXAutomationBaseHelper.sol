// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {GMXAutomationBase} from "../../src/GMXAutomationBase.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";

// openzeppelin
import {EnumerableMap} from "openzeppelin/utils/structs/EnumerableMap.sol";

contract GMXAutomationBaseHelper is GMXAutomationBase {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    constructor(DataStore dataStore, Reader reader) GMXAutomationBase(dataStore, reader) {}

    function pushPropFeedIdsToSet(Market.Props memory marketProps) public {
        _pushPropFeedIdsToSet(marketProps);
    }

    function flushFeedIdsAndAddresses() public returns (string[] memory, address[] memory) {
        return _flushFeedIdsAndAddresses();
    }

    function toHexString(bytes32 value) public pure returns (string memory) {
        return _toHexString(value);
    }

    function feedIdToMarketTokenMapSet(uint256 feedId, address addr) public {
        s_feedIdToMarketTokenMap.set(feedId, addr);
    }

    function feedIdToMarketTokenMapLength() public view returns (uint256) {
        return s_feedIdToMarketTokenMap.length();
    }

    function feedIdToMarketTokenMapContains(uint256 feedId) public view returns (bool) {
        return s_feedIdToMarketTokenMap.contains(feedId);
    }

    function feedIdToMarketTokenMapAt(uint256 index) public view returns (uint256, address) {
        return s_feedIdToMarketTokenMap.at(index);
    }

    function feedIdToMarketTokenMapKeys() public view returns (uint256[] memory) {
        return s_feedIdToMarketTokenMap.keys();
    }
}
