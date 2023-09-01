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
import {DepositHandler} from "gmx-synthetics/exchange/DepositHandler.sol";
// chainlink
import {StreamsLookupCompatibleInterface} from
    "chainlink/dev/automation/2_1/interfaces/StreamsLookupCompatibleInterface.sol";
import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";

/// @title Deposit Automation
/// @author Alex Roan - Cyfrin (@alexroan)
contract DepositAutomation is ILogAutomation, StreamsLookupCompatibleInterface, GMXAutomationBase {
    using LibGMXEventLogDecoder for Log;
    using LibGMXEventLogDecoder for EventUtils.EventLogData;

    // ERRORS
    error DepositAutomation_IncorrectEventName(string eventName, string expectedEventName);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "DepositCreated";
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIdHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "blockNumber";

    // IMMUTABLES
    DepositHandler public immutable i_depositHandler;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    /// @param depositHandler the DepositHandler contract address - immutable
    constructor(DataStore dataStore, Reader reader, DepositHandler depositHandler)
        GMXAutomationBase(dataStore, reader)
    {
        i_depositHandler = depositHandler;
    }

    ///////////////////////////
    // AUTOMATION FUNCTIONS
    ///////////////////////////

    /// @notice Retrieve relevant information from the log and perform a feed lookup
    /// @dev Reverts with custom errors if the event name is not equal to the expected event name (DepositCreated).
    /// @dev In the success case, reverts with StreamsLookup error containing relevant information for the feed lookup
    /// @dev This function is only ever simulated off-chain, so gas is not a concern.
    function checkLog(Log calldata log, bytes memory) external returns (bool, bytes memory) {
        // Decode Event Log 1
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert DepositAutomation_IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market,,, address[] memory longTokenSwapPath, address[] memory shortTokenSwapPath) =
            eventData.decodeEventData();

        // For each address in:
        // - market
        // - longTokenSwapPath[]
        // - shortTokenSwapPath[]
        // retrieve the Props struct from the DataStore. Use Props.marketToken to retrieve the feedId
        // and add to a list of feedIds.

        // Push the market feedId to the set
        Market.Props memory marketProps = i_reader.getMarket(i_dataStore, market);
        _addPropsToMapping(marketProps);

        // Push the longTokenSwapPath feedIds to the set
        for (uint256 i = 0; i < longTokenSwapPath.length; i++) {
            Market.Props memory longTokenSwapPathProps = i_reader.getMarket(i_dataStore, longTokenSwapPath[i]);
            _addPropsToMapping(longTokenSwapPathProps);
        }

        // Push the shortTokenSwapPath feedIds to the set
        for (uint256 i = 0; i < shortTokenSwapPath.length; i++) {
            Market.Props memory shortTokenSwapPathProps = i_reader.getMarket(i_dataStore, shortTokenSwapPath[i]);
            _addPropsToMapping(shortTokenSwapPathProps);
        }

        // Clear the feedIdSet
        (string[] memory feedIds, address[] memory addresses) = _flushMapping();

        // Construct the feed lookup error
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedIds,
            STRING_DATASTREAMS_QUERYLABEL,
            log.blockNumber,
            abi.encode(key, addresses)
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
    ///         - bytes memory reportData,
    ///         - bytes32[] memory rs,
    ///         - bytes32[] memory ss,
    ///         - bytes32 rawVs
    ///     - bytes extraData <- This is where the key and addresses array are stored
    /// @dev Decode the performData and call executeDeposit
    function performUpkeep(bytes calldata performData) external {
        (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
        (bytes32 key, address[] memory addresses) = abi.decode(extraData, (bytes32, address[]));
        OracleUtils.SetPricesParams memory oracleParams;
        oracleParams.realtimeFeedTokens = addresses;
        oracleParams.realtimeFeedData = values;
        i_depositHandler.executeDeposit(key, oracleParams);
    }
}
