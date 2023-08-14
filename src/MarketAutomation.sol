// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILogAutomation} from "./chainlink/ILogAutomation.sol";
import {LibEventLogDecoder} from "./libraries/LibEventLogDecoder.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
// openzeppelin
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {IERC20, SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @title Market Automation - Handles Market Decrease, Increase and Swap cases
/// @author Alex Roan - Cyfrin (@alexroan)
contract MarketAutomation is ILogAutomation, Ownable2Step {
    using LibEventLogDecoder for ILogAutomation.Log;
    using LibEventLogDecoder for EventUtils.EventLogData;
    using SafeERC20 for IERC20;

    // ERRORS
    error MarketAutomation_IncorrectEventName(string eventName, string expectedEventName);
    error MarketAutomation_IncorrectOrderType(uint256 orderType);
    // Specific revert for offchain lookup
    error DataStreamsLookup(string feedLabel, address[] feeds, string queryLabel, uint256 query, bytes data);

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

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    constructor(DataStore dataStore, Reader reader) Ownable2Step() {
        i_dataStore = dataStore;
        i_reader = reader;
    }

    /// @notice Withdraw any ERC20 tokens from the contract
    /// @dev Only callable by the owner
    /// @param tokens the tokens to withdraw
    /// @param to the address to withdraw the tokens to
    function withdrawTokens(IERC20[] memory tokens, address to) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeTransfer(to, tokens[i].balanceOf(address(this)));
        }
    }

    /// @notice Retrieve relevant information from the log and perform a data streams lookup
    /// @dev Reverts with custom errors if the event name is not equal to the expected event name (OrderCreated), or if the orderType is not equal to the expected orderType (4)
    /// @dev In the success case, reverts with DataStreamsLookup error containing relevant information for the data streams lookup
    function checkLog(ILogAutomation.Log calldata log, bytes calldata) external view returns (bool, bytes memory) {
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
        address[] memory feedIds = new address[](swapPath.length + 1);
        for (uint256 i = 0; i < feedIds.length; i++) {
            address marketToken;
            if (i == 0) {
                marketToken = i_reader.getMarket(i_dataStore, market).marketToken;
            } else {
                marketToken = i_reader.getMarket(i_dataStore, swapPath[i - 1]).marketToken;
            }
            // TODO: Get FeedId from somewhere using marketToken
            feedIds[i] = marketToken; // TODO: placeholder for now
        }

        // Construct the data for the data streams lookup error
        revert DataStreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL, feedIds, STRING_DATASTREAMS_QUERYLABEL, log.blockNumber, abi.encode(key)
        );
    }

    // Acts like checkUpkeep in a normal Automation job, probably don't need to do anything.
    // Values: Each value in array has to be validated by a contract that chainlink provides.
    function oracleCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external {
        // TODO: waiting on exact execution functions.
        // This will handle all 3 Market Automations
    }
}
