"use client";

import { useEffect, useState } from "react";
import { useWeb3Contract } from "react-moralis";
import { useMoralis } from "react-moralis";
import { ethers } from "ethers";
import { abi } from "../constants/abi";
import { contractAddress } from "../constants/contractAddress";
import { formatEther } from "ethers/lib/utils";
import { useNotification } from "@web3uikit/core";

const LotteryEntrance = () => {
  const { chainId: chainIdHex, isWeb3Enabled } = useMoralis();
  const chainId = parseInt(chainIdHex);
  const [entranceFee, setEntranceFee] = useState("0");
  const [numPlayers, setNumPlayers] = useState("0");
  const [recentWinner, setRecentWinner] = useState("0");
  const [prizePool, setPrizePool] = useState("0");
  const [lotteryState, setLotteryState] = useState("0");

  const dispatch = useNotification();

  const {
    runContractFunction: enterLottery,
    isFetching,
    isLoading,
  } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "enterLottery",
    params: {},
    msgValue: entranceFee,
  });

  const { runContractFunction: getEntranceFee } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "entranceFee",
    params: {},
  });

  const { runContractFunction: getNumPlayers } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "numberOfPlayers",
    params: {},
  });

  const { runContractFunction: getRecentWinner } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "getRecentWinner",
    params: {},
  });

  const { runContractFunction: getPrizePool } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "checkPrizePool",
    params: {},
  });

  const { runContractFunction: getLotteryState } = useWeb3Contract({
    abi: abi,
    contractAddress: contractAddress,
    functionName: "lotteryState",
    params: {},
  });

  async function updateUI() {
    const entranceFeeFromCall = (await getEntranceFee()).toString();
    const numPlayersFromCall = (await getNumPlayers()).toString();
    const recentWinnerFromCall = (await getRecentWinner()).toString();
    const prizePoolFromCall = (await getPrizePool()).toString();
    const lotteryStateFromCall = (await getLotteryState()).toString();
    setEntranceFee(entranceFeeFromCall);
    setNumPlayers(numPlayersFromCall);
    setRecentWinner(recentWinnerFromCall);
    setPrizePool(prizePoolFromCall);
    setLotteryState(lotteryStateFromCall);
  }

  useEffect(() => {
    if (isWeb3Enabled) {
      updateUI();
    }
  }, [isWeb3Enabled]);

  const handleSucess = async (tx) => {
    await tx.wait(1);

    handleNewNotification(tx);
    updateUI();
  };

  const handleNewNotification = () => {
    dispatch({
      type: "info",
      message: "Transaction Complete!",
      title: "Tx Notification",
      position: "topR",
    });
  };

  return (
    <div className="p-4 text-xl">
      <div className="flex justify-around m-4">
        <div className="text-center shadow-md p-4 rounded-md border border-indigo-500/100 w-1/3 m-4">
          <div className="text-6xl text-indigo-700 font-bold italic">
            {formatEther(entranceFee)}
          </div>
          <div className="text-3xl font-light text-indigo-700">
            entrance fee
          </div>
        </div>
        <div className="text-center shadow-md p-4 rounded-md border border-indigo-500/100 w-1/3 m-4">
          <div className="text-6xl text-indigo-700 font-bold italic">
            {formatEther(prizePool)}
          </div>
          <div className="text-3xl font-light text-indigo-700">prize pool</div>
        </div>
        <div className="text-center shadow-md p-4 rounded-md border border-indigo-500/100 w-1/3 m-4">
          <div className="text-6xl text-indigo-700 font-bold italic">
            {numPlayers}
          </div>
          <div className="text-3xl font-light text-indigo-700">
            number of Players
          </div>
        </div>
      </div>

      <div>
        <div className="flex justify-around text-indigo-700">
          {recentWinner}
        </div>
        <div className="flex justify-around text-indigo-700 italic">
          recent winner
        </div>
      </div>

      <div className="flex justify-around m-4 text-indigo-700">
        The Lottery State is: {lotteryState == "0" ? "On" : "Off"}{" "}
      </div>
      <div className="p-4 flex justify-center">
        <button
          onClick={async () => {
            await enterLottery({
              onSuccess: handleSucess,
              onError: (error) => console.log(error),
            });
          }}
          disabled={isFetching || isLoading}
          className="bg-violet-500 hover:bg-violet-700 text-white p-4 rounded-md"
        >
          {isLoading || isFetching ? (
            <div className="flex">
              <div className="animate-spin spinner-border h-6 w-6 border-b-2 rounded-full"></div>
              &nbsp; Processing ...
            </div>
          ) : (
            <div>Enter Lottery</div>
          )}
        </button>
      </div>
    </div>
  );
};

export default LotteryEntrance;
