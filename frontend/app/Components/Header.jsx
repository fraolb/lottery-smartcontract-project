import { ConnectButton } from "@web3uikit/web3";

const Header = () => {
  return (
    <div className="flex justify-between px-8 py-4 border-b-2">
      <div className="text-4xl text-violet-500 font-bold">
        Smart Contract Lottery
      </div>
      <ConnectButton moralisAuth={false} />
    </div>
  );
};

export default Header;
