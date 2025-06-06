import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route } from 'react-router'
import { PrivyProvider, type PrivyClientConfig } from '@privy-io/react-auth'
import { WagmiProvider, http, createConfig, deserialize, serialize } from 'wagmi'
import { monadTestnet, baseSepolia } from 'wagmi/chains'
import { QueryClient } from '@tanstack/react-query'
import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister'
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client'
import './index.css'

import {
  HomePage,
  NotFoundPage,
} from './pages'
import Layout from './layout'

const IS_PROD = import.meta.env.PROD;
const PRIVY_APP_ID = import.meta.env.VITE_PRIVY_APP_ID;
const PRIVY_CLIENT_ID = import.meta.env.VITE_PRIVY_CLIENT_ID;

const walletConfig = createConfig({
  chains: [
    baseSepolia,
    monadTestnet,
  ],
  transports: {
    [baseSepolia.id]: http(),
    [monadTestnet.id]: http(),
  }
})

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      gcTime: 1_000 * 60 * 60 * 24, // 24 hours
    }
  }
})

const persister = createSyncStoragePersister({
  serialize,
  storage: window.localStorage,
  deserialize,
})

const privyConfig = {
  embeddedWallets: {
    ethereum: {
      createOnLogin: 'users-without-wallets',
    }
  },
  defaultChain: monadTestnet,
  supportedChains: [monadTestnet, baseSepolia],
} as PrivyClientConfig;

const Content = () => {
  return (
    <PrivyProvider
      appId={PRIVY_APP_ID}
      clientId={PRIVY_CLIENT_ID}
      config={privyConfig}
    >
      <WagmiProvider config={walletConfig}>
        <PersistQueryClientProvider
          client={queryClient}
          persistOptions={{ persister }}
        >
          <BrowserRouter>
            <Routes>
              <Route element={<Layout />}>
                <Route index element={<HomePage />} />
                <Route path="*" element={<NotFoundPage />} />
              </Route>
            </Routes>
          </BrowserRouter>
        </PersistQueryClientProvider>
      </WagmiProvider>
    </PrivyProvider>
  );
};

if (IS_PROD) {
  createRoot(document.getElementById('root')!).render(
    <Content />,
  )
} else {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <Content />
    </StrictMode>,
  )
}
