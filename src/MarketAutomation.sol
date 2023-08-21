// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILogAutomation} from "./chainlink/ILogAutomation.sol";
import {LibEventLogDecoder} from "./libraries/LibEventLogDecoder.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
import {Keys} from "gmx-synthetics/data/Keys.sol";
import {OracleUtils} from "gmx-synthetics/oracle/OracleUtils.sol";
import {OrderHandler} from "gmx-synthetics/exchange/OrderHandler.sol";
// openzeppelin
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {IERC20, SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

/// @title Market Automation - Handles Market Decrease, Increase and Swap cases
/// @author Alex Roan - Cyfrin (@alexroan)
contract MarketAutomation is ILogAutomation, Ownable2Step {
    using LibEventLogDecoder for ILogAutomation.Log;
    using LibEventLogDecoder for EventUtils.EventLogData;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // ERRORS
    error MarketAutomation_IncorrectEventName(string eventName, string expectedEventName);
    error MarketAutomation_IncorrectOrderType(uint256 orderType);
    // Specific revert for offchain lookup
    error DataStreamsLookup(string feedLabel, bytes32[] feedIds, string queryLabel, uint256 query, bytes data);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    // Market Swap = 0, Market Increase = 2, Market Decrease = 4
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 = 0;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_2 = 2;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_4 = 4;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "BlockNumber";

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;
    OrderHandler public immutable i_orderHandler;

    // STORAGE
    // This should be empty after every transaction. It is filled and cleared each time checkLog is called.
    EnumerableSet.Bytes32Set internal s_feedIdSet;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    constructor(DataStore dataStore, Reader reader, OrderHandler orderHandler) Ownable2Step() {
        i_dataStore = dataStore;
        i_reader = reader;
        i_orderHandler = orderHandler;
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
    // AUTOMATION FUNCTIONS
    ///////////////////////////

    /// @notice Retrieve relevant information from the log and perform a data streams lookup
    /// @dev Reverts with custom errors if the event name is not equal to the expected event name (OrderCreated), or if the orderType is not equal to the expected orderType (4)
    /// @dev In the success case, reverts with DataStreamsLookup error containing relevant information for the data streams lookup
    /// @dev This function is only ever simulated off-chain, and is very gas intensive.
    function checkLog(ILogAutomation.Log calldata log, bytes calldata) external returns (bool, bytes memory) {
        // Decode Event Log 2
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert MarketAutomation_IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath,,) = eventData.decodeEventData();

        // Revert if the orderType is not equal to one of the expected orderTypes
        if (
            orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 && orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_2
                && orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_4
        ) {
            revert MarketAutomation_IncorrectOrderType(orderType);
        }

        // For each address in:
        // - market
        // - swapPath[]
        // retrieve the Props struct from the DataStore. Use Props.marketToken to retrieve the feedId
        // and add to a list of feedIds.

        // Push the market feedId to the set
        Market.Props memory marketProps = i_reader.getMarket(i_dataStore, market);
        _pushPropFeedIdsToSet(marketProps);

        // Push the swapPath feedIds to the set
        for (uint256 i = 0; i < swapPath.length; i++) {
            Market.Props memory swapPathProps = i_reader.getMarket(i_dataStore, swapPath[i]);
            _pushPropFeedIdsToSet(swapPathProps);
        }

        // Clear the feedIdSet
        bytes32[] memory feedIds = _flushFeedIdSet();

        // Construct the data for the data streams lookup error
        revert DataStreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL, feedIds, STRING_DATASTREAMS_QUERYLABEL, log.blockNumber, abi.encode(key)
        );
    }

    // Acts like checkUpkeep in a normal Automation job, probably don't need to do anything.
    // Values: Each value in array has to be validated by a contract that chainlink provides.
    // TODO: We need:
    // - bytes32 key
    // - address[] realtimeFeedTokens;
    // - bytes[] realtimeFeedData;
    // Where does this appear?
    function oracleCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        // TODO: Is this correct?
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external {
        (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
        // TODO: This will receive (key, realtimeFeedTokens and realtimeFeedData), we need to build
        // the SetPricesParams before calling executeOrder
        (bytes32 key, OracleUtils.SetPricesParams memory oracleParams) =
            abi.decode(performData, (bytes32, OracleUtils.SetPricesParams));
        i_orderHandler.executeOrder(key, oracleParams);
    }

    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    /// @notice Pushes the feedIds for marketProps: indexToken, longToken and shortToken to the feedIdSet
    /// @dev Does not allow for duplicate feedIds or zero address feedIds
    /// @param marketProps the Market Props struct to retrieve the feedIds from
    function _pushPropFeedIdsToSet(Market.Props memory marketProps) private {
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
    function _flushFeedIdSet() private returns (bytes32[] memory feedIds) {
        feedIds = new bytes32[](s_feedIdSet.length());
        for (uint256 i = 0; i < s_feedIdSet.length(); i++) {
            bytes32 value = s_feedIdSet.at(i);
            s_feedIdSet.remove(value);
            feedIds[i] = value;
        }
    }
}
