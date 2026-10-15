# FLUXORA — Guarded Onchain Perpetuals

**Every trade earns its trust.** FLUXORA pairs a human-readable Guarded Execution Receipt with an experimental EVM perpetuals sandbox.

## What is in this repository

- `apps/web/`: React/Vite trading terminal with public Binance USDⓈ-M Futures reference data, market selector, risk scenario lab, local receipt history, wallet connect, and optional contract actions when configured.
- `contracts/FluxoraPerps.sol`: experimental isolated-margin contract with ERC-20 collateral deposits, publisher-fed mark prices, onchain leverage/margin/notional/oracle-age/deviation checks, persistent accepted/rejected receipts, open/close lifecycle, simple funding index, and a liquidation entry point.
- `contracts/MockCollateral.sol`: faucet token for local/testnet demos only.
- `test/FluxoraPerps.js`: initial contract tests.
- `docs/RESEARCH_AND_ROADMAP.md`: research framing, limitations, and evaluation plan.

## Status — read before demoing

This is a **testnet/local hackathon prototype, not a production exchange**. The code has been committed, but this repository update has not itself deployed contracts, run the tests, completed a browser build, or verified a transaction on an explorer. Do not claim those checks passed until you run them and capture the evidence.

The dashboard uses Binance public API data for its live reference market feed. That feed is offchain. The contract price is separately published by a configured trusted publisher; it is **not** a decentralized oracle. The mock collateral has no real value.

The contract is not audited. It is a demonstration of risk-gated transaction flow, not a complete or economically safe perpetuals exchange: it has no matching engine, external counterparty/insurance pool, robust oracle, robust funding economics, fee model, or production-grade liquidation incentives. PnL accounting and liquidation economics need independent review before any real-asset use. Never use mainnet funds.

## Run the frontend

Requires Node.js 20+.

```powershell
cd apps/web
npm install
# Optional: configure these in apps/web/.env.local after deployment
# VITE_FLUXORA_CHAIN_ID=11155111
# VITE_FLUXORA_CONTRACT_ADDRESS=0x...
# VITE_FLUXORA_COLLATERAL_ADDRESS=0x...
npm run dev
```

Without contract addresses, the UI remains in simulation mode. A connected wallet alone does not turn a simulated receipt into an onchain receipt.

## Compile and test the contracts

From the repository root:

```powershell
npm install
npm run contracts:compile
npm run contracts:test
```

The contract suite is an initial smoke-test suite, not a security audit.

## Deploy to Sepolia (testnet only)

1. Install dependencies at the repository root.
2. Copy `.env.example` to `.env`.
3. Set `SEPOLIA_RPC_URL` and `DEPLOYER_PRIVATE_KEY`. Use a dedicated test wallet with no valuable assets; never commit `.env`.
4. Fund that wallet with Sepolia test ETH.
5. Run:

```powershell
npm run contracts:deploy:sepolia
```

6. Save the printed `MockCollateral` and `FluxoraPerps` addresses. Set the corresponding `VITE_FLUXORA_...` values in `apps/web/.env.local`, then restart Vite.
7. Connect the deployer/publisher wallet, choose a market, and click **Publish mark price**. This action explicitly trusts that wallet to publish the reference price. Repeat when the price becomes stale.
8. Click **Deposit 1,000 test tokens**, approve the token in the wallet if requested, and then submit a small test order. The first contract deployment is not automatically published to a block explorer by this repository; use the transaction hash and the Sepolia explorer to verify it.

The deployment script deploys the mock token and exchange contract only. It does not fund the wallet, verify source code, run the frontend, or make the trusted publisher decentralized.

## Product thesis

The hypothesis is that a pre-trade receipt with explicit reasons for a pass or block may make leverage, collateral, oracle freshness, and price deviation easier to understand. This is a hypothesis to evaluate, not a proven novelty claim. Measure task completion, risk comprehension, and agreement between the UI preview and contract outcomes against a baseline.

## Safety

Perpetual futures are high risk. This software is for engineering experimentation and is not financial advice. Use only test tokens on a test network. Do not deploy this prototype with real assets.
