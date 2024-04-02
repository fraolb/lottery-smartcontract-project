// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///import files for random number generator
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
//import for the time based checker
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

//errors
error Lottery__LowerEntranceFeeEntered();
error Lottery__NoPlayersEnteredLottery();
error Lottery__TransactionFailed();
error Lottery__StateBusy();
error Lottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**@title A simple Lottery Contract
 * @author Fraol Bereket
 * @notice The contract is for creating an untamperable decentralized smart contract that pickes winners based on a certain time interval
 * @dev This implements Chainlink VRF v2 and Chainlink Automation
 */

contract SimpleLotterySystem is
    VRFConsumerBaseV2,
    AutomationCompatibleInterface
{
    //types
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    //variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 private immutable i_subscriptionId;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_updateInterval;
    bytes32 private constant KEYHASH =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private constant CALLBACKGASLIMIT = 100000;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 1;

    //s variables
    address payable[] private s_players;
    address payable private s_recentWinner;
    LotteryState private s_LotteryState;
    uint256 private s_lastTimeStamp;

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
        uint256 _entranceFee,
        uint256 _updateInterval
    ) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        i_subscriptionId = _subscriptionId;
        i_entranceFee = _entranceFee;
        i_updateInterval = _updateInterval;
        s_LotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
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

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool timePassed = (block.timestamp - s_lastTimeStamp) >
            i_updateInterval;
        bool isOpen = s_LotteryState == LotteryState.OPEN;

        upkeepNeeded = (hasBalance && hasPlayers && timePassed && isOpen);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // if(s_players.length <= 0){
        //     revert Lottery__NoPlayersEnteredLottery();
        // }
        // Will revert if subscription is not set and funded.

        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_LotteryState)
            );
        }

        uint256 requestId = COORDINATOR.requestRandomWords(
            KEYHASH,
            i_subscriptionId,
            REQUESTCONFIRMATIONS,
            CALLBACKGASLIMIT,
            NUMWORDS
        );
        s_LotteryState = LotteryState.CALCULATING;
        emit LotteryRequestSent(requestId, NUMWORDS);
        //return requestId;
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

    function checkPrizePool() public view returns (uint256) {
        return address(this).balance;
    }

    function lotteryState() public view returns (uint256) {
        return uint256(s_LotteryState);
    }
}
