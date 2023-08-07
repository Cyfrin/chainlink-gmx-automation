// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// //import some GMX interface

// contract GmxCreateOrderAutomation {
//     error OracleLookup(string[] feedIDStrList, string instance, bytes extraData);

//     constructor() {
//         //set datastore
//     }

//     address public dataStore;

//     //checkLog is responsible for listening to log events and passing parsing data. The data is then used to make an oracle request
//     function checkLog(bytes calldata data) external view returns (bool, bytes memory) {
//         /*
//         {
//             address msgSender, // order creator
//             string eventNameHash,
//             string eventName,
//             bytes32 topic1,
//             bytes32 topic2,
//             EventUtils.EventLogData eventData
//         }
//         */

//         /*
//         export enum OrderType {
//             MarketSwap = 0,
//             LimitSwap = 1,
//             MarketIncrease = 2,
//             LimitIncrease = 3,
//             MarketDecrease = 4,
//             LimitDecrease = 5,
//             StopLossDecrease = 6,
//             Liquidation = 7,
//         }
//         */
//         eventData EventData = data.eventData;
//         bytes32 key = eventData.bytes32items.key;

//         if (eventData.UnitItems.OrderType != 2) {
//             revert("Not a MarketIncrease Order");
//         }

//         //for loop for all required markets
//         //    struct Props {
//         //     address marketToken;
//         //     address indexToken;
//         //     address longToken;
//         //     address shortToken;
//         // }
//         (Market.props memory props) = MarketStore.getMarket(dataStore, key);

//         address feedId = chainlinkFeedIds[props.marketToken]; // TODO: need to create this mapping

//         feedLabel = "feedIDHex"; // feedLabel can be "feedIDStr" "feedIDHex"
//         feeds = [feedId];
//         queryLabel = "BlockNumber"; //queryLabel can be "BlockNumber" or "Timestamp"
//         query = block.number; // Log.blockNumber
//         data = abi.encode(key, (bytes32));
//         revert DataStreamsLookup(feedLabel, feeds, queryLabel, query, data);
//     }

//     //the oracle data is passed into this oracleCallback function. if this function returns true, it will send the performUpkeep transaction
//     function oracleCallback(bytes[] values, bytes extraData) external view returns (bool, bytes memory) {
//         bytes memory performData = abi.encode(values, extraData);
//         return (true, performData);
//     }

//     //this is the transaction that is sent on chain, which contains the chainlinkBlobs and key
//     function performUpkeep(bytes calldata performData) external {
//         (bytes[] chainlinkBlobs, bytes extraData) = abi.decode(performData, (bytes[], bytes));
//         bytes32 _key = abi.decode(extraData, (bytes32));
//         executeOrder(_key, "", chainlinkBlobs);
//     }
// }
