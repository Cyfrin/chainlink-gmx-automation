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
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using SafeERC20 for IERC20;

    // ERRORS
    error GMXAutomationBase_OnlyForwarder();
    error GMXAutomationBase_ZeroIndexTokenFeedId();
    error GMXAutomationBase_ZeroLongTokenFeedId();
    error GMXAutomationBase_ZeroShortTokenFeedId();

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;

    // STORAGE
    // The address that `performUpkeep` is called from
    address public s_forwarderAddress;

    // This should be empty after every transaction. It is filled and cleared each time checkLog is called.
    // mapping (tokenAddress => uint256(feedId))
    EnumerableMap.AddressToUintMap internal s_marketTokenToFeedId;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    constructor(DataStore dataStore, Reader reader) {
        i_dataStore = dataStore;
        i_reader = reader;
    }

    ///////////////////////////
    // MODIFIERS
    ///////////////////////////

    /// @notice Check that the msg.sender is the forwarder address
    modifier onlyForwarder() {
        if (msg.sender != s_forwarderAddress) revert GMXAutomationBase_OnlyForwarder();
        _;
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

    /// @notice Set the address that `performUpkeep` is called from
    /// @dev Only callable by the owner
    /// @param forwarderAddress the address to set
    function setForwarderAddress(address forwarderAddress) external onlyOwner {
        s_forwarderAddress = forwarderAddress;
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
            if (indexTokenFeedId == 0) revert GMXAutomationBase_ZeroIndexTokenFeedId();
            if (!s_marketTokenToFeedId.contains(marketProps.indexToken)) {
                s_marketTokenToFeedId.set(marketProps.indexToken, indexTokenFeedId);
            }
        }

        if (marketProps.longToken != address(0)) {
            uint256 longTokenFeedId = uint256(i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.longToken)));
            if (longTokenFeedId == 0) revert GMXAutomationBase_ZeroLongTokenFeedId();
            if (!s_marketTokenToFeedId.contains(marketProps.longToken)) {
                s_marketTokenToFeedId.set(marketProps.longToken, longTokenFeedId);
            }
        }

        if (marketProps.shortToken != address(0)) {
            uint256 shortTokenFeedId = uint256(i_dataStore.getBytes32(Keys.realtimeFeedIdKey(marketProps.shortToken)));
            if (shortTokenFeedId == 0) revert GMXAutomationBase_ZeroShortTokenFeedId();
            if (!s_marketTokenToFeedId.contains(marketProps.shortToken)) {
                s_marketTokenToFeedId.set(marketProps.shortToken, shortTokenFeedId);
            }
        }
    }

    /// @notice Returns all values from and clears the s_marketTokenToFeedId
    /// @dev Iterates over the addressToMarketTokenMap, and removes each address and returns them as an array along with the corresponding feedIds
    /// @return feedIds the feedIds that were in the addressToMarketTokenMap mapped with respective token addresses
    /// @return addresses the addresses that were in the addressToMarketTokenMap mapped with respective feedIds
    function _flushMapping() internal returns (string[] memory feedIds, address[] memory addresses) {
        uint256 length = s_marketTokenToFeedId.length();
        feedIds = new string[](length);
        addresses = new address[](length);
        uint256 count = 0;
        while (s_marketTokenToFeedId.length() > 0) {
            (address addressKey, uint256 uintValue) = s_marketTokenToFeedId.at(s_marketTokenToFeedId.length() - 1);
            s_marketTokenToFeedId.remove(addressKey);
            feedIds[count] = _toHexString(bytes32(uintValue));
            addresses[count] = addressKey;
            count++;
        }
    }

    /// @notice Converts a bytes buffer to a hexadecimal string
    /// @param value the bytes32 value to convert
    /// @return the hexadecimal string
    function _toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory buffer = abi.encodePacked(value);
        // Fixed buffer size for hexadecimal conversion
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}
