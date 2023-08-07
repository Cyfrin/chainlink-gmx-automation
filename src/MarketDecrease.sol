// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {EventLogDecoder} from "./EventLogDecoder.sol";
import {ILogAutomation} from "./ILogAutomation.sol";

/// @notice Market Decrease Automation
contract MarketDecrease is ILogAutomation, EventLogDecoder {

    error IncorrectEventName(string eventName, string expectedEventName);
    error IncorrectOrderType(uint256 orderType, uint256 expectedOrderType);

    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE = 4;

    function checkLog(ILogAutomation.Log calldata log, bytes calldata) external returns (bool, bytes memory) {
        // Decode Event Log 2
        (
            address msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = _decodeEventLog2(log);

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath
        ) = _decodeEventData(eventData);
        
        if (orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE) {
            revert IncorrectOrderType(orderType, EXPECTED_LOG_EVENTDATA_ORDERTYPE);
        }

        // reader.getMarket(dataStore, key) // where the key is each one of the decodedEventData feilds
        // This returns Market.props, which is a struct with the following fields:
        // - address marketToken;
        // - address indexToken;
        // - address longToken;
        // - address shortToken;

        // Use each marketToken to get the feedId from where? (somewhere external)
        // add it to a list of feedIds

        // Construct something and revert
    }

    function oracleCallback(bytes[] calldata values, bytes calldata extraData)
        external
        view
        returns (bool, bytes memory)
    {}

    function performUpkeep(bytes calldata performData) external {}
}
