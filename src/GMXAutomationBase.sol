// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// openzeppelin
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {IERC20, SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
// gmx-synthetics
import {Market} from "gmx-synthetics/market/Market.sol";
import {Keys} from "gmx-synthetics/data/Keys.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";

contract GMXAutomationBase is Ownable2Step {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeERC20 for IERC20;

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;

    // STORAGE
    // This should be empty after every transaction. It is filled and cleared each time checkLog is called.
    EnumerableSet.Bytes32Set internal s_feedIdSet;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    constructor(DataStore dataStore, Reader reader) {
        i_dataStore = dataStore;
        i_reader = reader;
    }

    ///////////////////////////
    // OWNABLE FUNCTIONS
    ///////////////////////////

    /// @notice Withdraw any ERC20 tokens from the contract
    /// @dev Only callable by the owner
    /// @param token the token to withdraw
    /// @param to the address to withdraw the tokens to
    function withdraw(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    /// @notice Pushes the feedIds for marketProps: indexToken, longToken and shortToken to the feedIdSet
    /// @dev Does not allow for duplicate feedIds or zero address feedIds
    /// @dev Does not push the Props.marketToken feedId to the feedIdSet
    /// @param marketProps the Market Props struct to retrieve the feedIds from
    function _pushPropFeedIdsToSet(Market.Props memory marketProps) internal {
        if (marketProps.indexToken != address(0)) {
            bytes32 indexTokenFeedId = i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.indexToken));
            if (indexTokenFeedId != bytes32(0) && !s_feedIdSet.contains(indexTokenFeedId)) {
                s_feedIdSet.add(indexTokenFeedId);
            }
        }

        if (marketProps.longToken != address(0)) {
            bytes32 longTokenFeedId = i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.longToken));
            if (longTokenFeedId != bytes32(0) && !s_feedIdSet.contains(longTokenFeedId)) {
                s_feedIdSet.add(longTokenFeedId);
            }
        }

        if (marketProps.shortToken != address(0)) {
            bytes32 shortTokenFeedId = i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.shortToken));
            if (shortTokenFeedId != bytes32(0) && !s_feedIdSet.contains(shortTokenFeedId)) {
                s_feedIdSet.add(shortTokenFeedId);
            }
        }
    }

    /// @notice Returns all values from and clears the s_feedIdSet
    /// @dev Iterates over the feedIdSet, and removes each feedId and returns them as an array
    /// @return feedIds the feedIds that were in the feedIdSet
    function _flushFeedIdSet() internal returns (string[] memory feedIds) {
        feedIds = new string[](s_feedIdSet.length());
        uint256 count = 0;
        while (s_feedIdSet.length() > 0) {
            bytes32 value = s_feedIdSet.at(s_feedIdSet.length() - 1);
            s_feedIdSet.remove(value);
            feedIds[count] = string(abi.encode(value));
            count++;
        }
    }
}
