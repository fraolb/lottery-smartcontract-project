// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///import files for random number generator
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
//import for the time based checker

//errors
error Lottery__LowerEntranceFeeEntered();
error Lottery__NoPlayersEnteredLottery();
error Lottery__TransactionFailed();
error Lottery__StateBusy();

contract SimpleLotterySystem is VRFConsumerBaseV2 {
    //types
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    //variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 private immutable i_subscriptionId;
    uint256 private immutable i_entranceFee;
    bytes32 private constant KEYHASH =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private constant CALLBACKGASLIMIT = 100000;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 1;

    //s variables
    address payable[] private s_players;
    address payable private s_recentWinner;
    LotteryState private s_LotteryState;

    //events
    event PlayerEnteredLottery(address indexed player);
    event LotteryRequestSent(
        uint256 indexed requestId,
        uint32 indexed numWords
    );
    event LotteryRequestFulfilled(
        uint256 indexed _requestId,
        address indexed recentWinner,
        uint256 indexed winnerIndex
    );

    constructor(
        uint64 _subscriptionId,
        uint256 _entranceFee
    ) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        i_subscriptionId = _subscriptionId;
        i_entranceFee = _entranceFee;
        s_LotteryState = LotteryState.OPEN;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__LowerEntranceFeeEntered();
        }
        if (s_LotteryState == LotteryState.CALCULATING) {
            revert Lottery__StateBusy();
        }

        s_players.push(payable(msg.sender));
        emit PlayerEnteredLottery(msg.sender);
    }

    function requestRandomWords() external returns (uint256 requestId) {
        if (s_players.length <= 0) {
            revert Lottery__NoPlayersEnteredLottery();
        }
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            KEYHASH,
            i_subscriptionId,
            REQUESTCONFIRMATIONS,
            CALLBACKGASLIMIT,
            NUMWORDS
        );
        s_LotteryState = LotteryState.CALCULATING;
        emit LotteryRequestSent(requestId, NUMWORDS);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_LotteryState = LotteryState.OPEN;
        (bool succuss, ) = recentWinner.call{value: address(this).balance}("");
        if (!succuss) {
            revert Lottery__TransactionFailed();
        }
        emit LotteryRequestFulfilled(_requestId, recentWinner, winnerIndex);
    }

    ///view pure functions
    function entranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function numberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
