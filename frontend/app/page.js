"use client";

import Image from "next/image";
import ManualHeader from "./Components/ManualHeader";
import { MoralisProvider } from "react-moralis";
import Header from "./Components/Header";
import LotteryEntrance from "./Components/LotteryEntrance";

export default function Home() {
  return (
    <MoralisProvider initializeOnMount={false}>
      <main>
        <div>Hello</div>
        {/* header componentes */}
        <Header />

        {/* lottery entrance */}
        <LotteryEntrance />
      </main>
    </MoralisProvider>
  );
}
