// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

error RandomNumberGeneratorBusy();

/**@title A simple random number generator
 *@author Fraol Bereket
 *@notice This is a simple random number generator between 1 - 10, the VRF feedback(fulfillRandomWords) can be slower
 *@dev This implements Chainlink VRF v2
 */

contract RandomNumberGenerator is VRFConsumerBaseV2 {
    //types
    enum GeneratorState {
        OPEN,
        CALCULATING
    }
    //variables
    uint64 private immutable i_subscriptionId;
    bytes32 private constant KEYHASH =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private constant CALLBACKGASLIMIT = 100000;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 2;
    VRFCoordinatorV2Interface COORDINATOR;

    //s variables
    GeneratorState s_generatorState;
    uint256 s_pickedNumber;

    //events
    event RequestedRandomNumber(address indexed player);
    event RandomNumberSelected(uint256 indexed num);

    constructor(
        uint64 subscriptionId
    ) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        i_subscriptionId = subscriptionId;
        s_generatorState = GeneratorState.OPEN;
    }

    function generateRandomNumber() external returns (uint256 requestId) {
        if (s_generatorState == GeneratorState.CALCULATING) {
            revert RandomNumberGeneratorBusy();
        }
        s_generatorState = GeneratorState.CALCULATING;
        requestId = COORDINATOR.requestRandomWords(
            KEYHASH,
            i_subscriptionId,
            REQUESTCONFIRMATIONS,
            CALLBACKGASLIMIT,
            NUMWORDS
        );
        emit RequestedRandomNumber(msg.sender);
        return requestId;
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory _randomNum
    ) internal override {
        s_generatorState = GeneratorState.OPEN;
        uint256 pickedNum = _randomNum[0] % 10;
        emit RandomNumberSelected(pickedNum);
        s_pickedNumber = pickedNum;
    }

    function viewPickedNumber() public view returns (uint256) {
        return s_pickedNumber;
    }
}
