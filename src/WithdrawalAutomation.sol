// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibGMXEventLogDecoder} from "./libraries/LibGMXEventLogDecoder.sol";
import {GMXAutomationBase} from "./GMXAutomationBase.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
import {OracleUtils} from "gmx-synthetics/oracle/OracleUtils.sol";
import {WithdrawalHandler} from "gmx-synthetics/exchange/WithdrawalHandler.sol";
// chainlink
import {FeedLookupCompatibleInterface} from "chainlink/dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol";
import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";

contract WithdrawalAutomation is ILogAutomation, FeedLookupCompatibleInterface, GMXAutomationBase {
    using LibGMXEventLogDecoder for Log;
    using LibGMXEventLogDecoder for EventUtils.EventLogData;

    // ERRORS
    error WithdrawalAutomation_IncorrectEventName(string eventName, string expectedEventName);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "WithdrawalCreated";
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "BlockNumber";

    // IMMUTABLES
    WithdrawalHandler public immutable i_withdrawalHandler;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    /// @param withdrawalHandler the WithdrawalHandler contract address - immutable
    constructor(DataStore dataStore, Reader reader, WithdrawalHandler withdrawalHandler)
        GMXAutomationBase(dataStore, reader)
    {
        i_withdrawalHandler = withdrawalHandler;
    }

    ///////////////////////////
    // AUTOMATION FUNCTIONS
    ///////////////////////////

    function checkLog(Log calldata log) external returns (bool, bytes memory) {
        // Decode Event Log 1
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert WithdrawalAutomation_IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market,,,,) = eventData.decodeEventData();

        // Push the market feedId to the set
        Market.Props memory marketProps = i_reader.getMarket(i_dataStore, market);
        _pushPropFeedIdsToSet(marketProps);

        // Clear the feedIdSet
        string[] memory feedIds = _flushFeedIdSet();

        // Construct the data streams lookup error
        revert FeedLookup(
            STRING_DATASTREAMS_FEEDLABEL, feedIds, STRING_DATASTREAMS_QUERYLABEL, log.blockNumber, abi.encode(key)
        );
    }

    /// @notice Check the callback
    /// @dev Encode the values and extra data into performData and return true
    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    /// @notice Perform the upkeep
    /// @param performData the data returned from checkCallback. Encoded:
    ///     - bytes[] values. Each value contains a signed report by the DON, and must be decoded:
    ///         - bytes32[3] memory reportContext,
    ///         - bytes memory reportData, <- This is where we can access the token and price
    ///         - bytes32[] memory rs,
    ///         - bytes32[] memory ss,
    ///         - bytes32 rawVs
    ///     - bytes extraData <- This is where the key is
    /// @dev Decode the performData and call executeOrder
    function performUpkeep(bytes calldata performData) external {
        (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
        bytes32 key = abi.decode(extraData, (bytes32));
        OracleUtils.SetPricesParams memory oracleParams;
        oracleParams.realtimeFeedData = values;
        i_withdrawalHandler.executeWithdrawal(key, oracleParams);
    }
}
