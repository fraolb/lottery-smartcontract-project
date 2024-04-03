"use client";

import Image from "next/image";
import ManualHeader from "./Components/ManualHeader";
import { MoralisProvider } from "react-moralis";
import Header from "./Components/Header";
import LotteryEntrance from "./Components/LotteryEntrance";
import { NotificationProvider } from "@web3uikit/core";

export default function Home() {
  return (
    <MoralisProvider initializeOnMount={false}>
      <NotificationProvider>
        <main>
          {/* header componentes */}
          <Header />

          {/* lottery entrance */}
          <LotteryEntrance />
        </main>
      </NotificationProvider>
    </MoralisProvider>
  );
}
