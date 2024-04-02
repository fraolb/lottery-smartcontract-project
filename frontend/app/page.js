import Image from "next/image";
import Header from "./Components/Header";

export const metadata = {
  title: "Smart Contract Lottery",
  description:
    "This is a simple smart contract lottery system that is autmated and function all by it self",
};

export default function Home() {
  return (
    <main>
      <div>Hello</div>
      {/* header componentes */}
      <Header />
    </main>
  );
}
