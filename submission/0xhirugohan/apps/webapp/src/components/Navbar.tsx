import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { useQueryClient } from '@tanstack/react-query'
import { usePrivy, useWallets, type ConnectedWallet } from '@privy-io/react-auth'
import {
    useAccount,
    useBalance,
    useChains,
    useDisconnect
} from 'wagmi'
import { type Address, formatUnits } from 'viem'

import ReactLogo from '../assets/react.svg'

const Navbar = () => {
    const queryClient = useQueryClient();
    const { ready, connectOrCreateWallet, logout, user } = usePrivy();
    const { wallets } = useWallets();
    const chains = useChains();
    const { address } = useAccount();
    const { disconnect } = useDisconnect();
    const [selectedWallet, setSelectedWallet] = useState<ConnectedWallet>();
    const { data: userBalance, queryKey: userBalanceQueryKey } = useBalance({
        address: selectedWallet?.address as Address,
        chainId: parseInt(selectedWallet?.chainId?.split(':')[1] ?? '0'),
    });

    useEffect(() => {
        if (wallets.length > 0) {
            setSelectedWallet(wallets[0]);
            return;
        }

        setSelectedWallet(undefined);
    }, [wallets]);

    const handleLogout = () => {
        if (user) {
            logout();
            return
        }

        disconnect();
    }

    const handleChainChange = async (event: React.ChangeEvent<HTMLSelectElement>) => {
        const newChainId = event.target.value.split(':')[1];
        await selectedWallet?.switchChain(parseInt(newChainId));
        await queryClient.invalidateQueries({ queryKey: userBalanceQueryKey });
    }

    return <div className="bg-zinc-100/90 border-b border-zinc-600 fixed top-0 left-0 right-0 z-50 p-3 flex justify-between">
        <div className="flex gap-x-8 items-center">
            <div className="flex gap-x-4">
                <img
                    className="w-8"
                    src={ReactLogo}
                    alt="react logo"
                />
                <div>
                    <p className="font-bold">Create-Web3</p>
                    <p className="text-xs">EVM boilerplate</p>
                </div>
            </div>
            <Link
                className="hidden md:block cursor-pointer"
                to="/"
            >
                Home
            </Link>
        </div>
        <div className="flex items-center gap-x-4">
            { ready && wallets.length > 0 && <p>
                { parseFloat(formatUnits(userBalance?.value ?? BigInt(0), userBalance?.decimals ?? 0)).toFixed(4) } {` `}
                { userBalance?.symbol }
            </p> }

            { ready && wallets.length > 0 && <select
                className="border-2 border-zinc-600 px-2 py-1 rounded-md cursor-pointer"
                onChange={handleChainChange}
                value={selectedWallet?.chainId}
            >
                { chains.map((chain) => <option
                    key={chain.id}
                    value={`eip155:${chain.id}`}
                >
                    {chain.name}
                </option>)}
            </select>}

            { ready && !address && !user && <button
                onClick={connectOrCreateWallet}
                className="text-sm border-2 border-zinc-600 rounded-md px-4 py-2 hover:shadow-md cursor-pointer"
            >
                <span className="hidden md:block">Connect Wallet</span>
                <span className="block md:hidden">Connect</span>
            </button> }
            { ready && wallets.length > 0 && <button
                onClick={handleLogout}
                className="text-sm border-2 border-zinc-600 rounded-md px-4 py-2 hover:shadow-md cursor-pointer"
            >
                {wallets[0].address.slice(0, 4)}...{wallets[0].address.slice(-4)}
            </button>}
        </div>
    </div>
}

export default Navbar;