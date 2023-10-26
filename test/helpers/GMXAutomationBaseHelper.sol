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
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    constructor(DataStore dataStore, Reader reader) GMXAutomationBase(dataStore, reader) {}

    function modifierOnlyForwarder() public onlyForwarder {}

    function addPropsToMapping(Market.Props memory marketProps) public {
        _addPropsToMapping(marketProps);
    }

    function flushMapping() public returns (string[] memory, address[] memory) {
        return _flushMapping();
    }

    function toHexString(bytes32 value) public pure returns (string memory) {
        return _toHexString(value);
    }

    function marketTokenToFeedIdMapSet(address addr, uint256 feedId) public {
        s_marketTokenToFeedId.set(addr, feedId);
    }

    function marketTokenToFeedIdMapLength() public view returns (uint256) {
        return s_marketTokenToFeedId.length();
    }

    function marketTokenToFeedIdMapContains(address addr) public view returns (bool) {
        return s_marketTokenToFeedId.contains(addr);
    }

    function marketTokenToFeedIdMapGet(address addr) public view returns (uint) {
        return s_marketTokenToFeedId.get(addr);
    }

    function marketTokenToFeedIdMapAt(uint256 index) public view returns (address, uint256) {
        return s_marketTokenToFeedId.at(index);
    }

    function marketTokenToFeedIdMapKeys() public view returns (address[] memory) {
        return s_marketTokenToFeedId.keys();
    }
}
