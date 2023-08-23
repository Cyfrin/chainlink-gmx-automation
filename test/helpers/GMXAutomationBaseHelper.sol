// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {GMXAutomationBase} from "../../src/GMXAutomationBase.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";

// openzeppelin
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

contract GMXAutomationBaseHelper is GMXAutomationBase {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    constructor(DataStore dataStore, Reader reader) GMXAutomationBase(dataStore, reader) {}

    function pushPropFeedIdsToSet(Market.Props memory marketProps) public {
        _pushPropFeedIdsToSet(marketProps);
    }

    function flushFeedIdSet() public returns (string[] memory) {
        return _flushFeedIdSet();
    }

    function feedIdSetAdd(bytes32 feedId) public {
        s_feedIdSet.add(feedId);
    }

    function feedIdSetLength() public view returns (uint256) {
        return s_feedIdSet.length();
    }

    function feedIdSetContains(bytes32 feedId) public view returns (bool) {
        return s_feedIdSet.contains(feedId);
    }

    function feedIdSetAt(uint256 index) public view returns (bytes32) {
        return s_feedIdSet.at(index);
    }

    function feedIdSetValues() public view returns (bytes32[] memory) {
        return s_feedIdSet.values();
    }
}
