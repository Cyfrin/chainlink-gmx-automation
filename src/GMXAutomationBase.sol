// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// openzeppelin
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {EnumerableMap} from "openzeppelin/utils/structs/EnumerableMap.sol";
import {IERC20, SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
// gmx-synthetics
import {Market} from "gmx-synthetics/market/Market.sol";
import {Keys} from "gmx-synthetics/data/Keys.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";

/// @title Base Automation Contract for GMX Automation Contracts
/// @author Alex Roan - Cyfrin (@alexroan)
contract GMXAutomationBase is Ownable2Step {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using SafeERC20 for IERC20;

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;

    // STORAGE
    // This should be empty after every transaction. It is filled and cleared each time checkLog is called.
    // mapping (uint256(feedId) => tokenAddress)
    EnumerableMap.UintToAddressMap internal s_feedIdToMarketTokenMap;

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

    /// @notice Pushes the feedIds for marketProps: indexToken, longToken and shortToken to the feedIdToMarketTokenMap
    /// @dev Does not allow for duplicate feedIds or zero address feedIds
    /// @dev Does not push the Props.marketToken feedId to the feedIdToMarketTokenMap
    /// @param marketProps the Market Props struct to retrieve the feedIds from
    function _addPropsToMapping(Market.Props memory marketProps) internal {
        if (marketProps.indexToken != address(0)) {
            uint256 indexTokenFeedId = uint256(i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.indexToken)));
            if (indexTokenFeedId != 0 && !s_feedIdToMarketTokenMap.contains(indexTokenFeedId)) {
                s_feedIdToMarketTokenMap.set(indexTokenFeedId, marketProps.indexToken);
            }
        }

        if (marketProps.longToken != address(0)) {
            uint256 longTokenFeedId = uint256(i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.longToken)));
            if (longTokenFeedId != 0 && !s_feedIdToMarketTokenMap.contains(longTokenFeedId)) {
                s_feedIdToMarketTokenMap.set(longTokenFeedId, marketProps.longToken);
            }
        }

        if (marketProps.shortToken != address(0)) {
            uint256 shortTokenFeedId = uint256(i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.shortToken)));
            if (shortTokenFeedId != 0 && !s_feedIdToMarketTokenMap.contains(shortTokenFeedId)) {
                s_feedIdToMarketTokenMap.set(shortTokenFeedId, marketProps.shortToken);
            }
        }
    }

    /// @notice Returns all values from and clears the s_feedIdToMarketTokenMap
    /// @dev Iterates over the feedIdToMarketTokenMap, and removes each feedId and returns them as an array
    /// @return feedIds the feedIds that were in the feedIdToMarketTokenMap
    function _flushMapping() internal returns (string[] memory feedIds, address[] memory addresses) {
        uint256 length = s_feedIdToMarketTokenMap.length();
        feedIds = new string[](length);
        addresses = new address[](length);
        uint256 count = 0;
        while (s_feedIdToMarketTokenMap.length() > 0) {
            (uint256 uintKey, address value) = s_feedIdToMarketTokenMap.at(s_feedIdToMarketTokenMap.length() - 1);
            s_feedIdToMarketTokenMap.remove(uintKey);
            feedIds[count] = _toHexString(bytes32(uintKey));
            addresses[count] = value;
            count++;
        }
    }

    /// @notice Converts a bytes buffer to a hexadecimal string
    /// @param value the bytes32 value to convert
    /// @return the hexadecimal string
    function _toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory buffer = abi.encodePacked(value);
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}
