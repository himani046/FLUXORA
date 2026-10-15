# FLUXORA — Guarded Onchain Perpetuals

Where every trade earns its trust.

Fluxora is a hackathon prototype for a safer, more legible onchain perpetual-futures workflow. Its proposed differentiator is a human-readable **Guarded Execution Receipt**: preview collateral, leverage, notional exposure, oracle freshness, price deviation, and explicit reasons an order would be blocked.

> Prototype status: the web UI uses simulated market data and does not submit trades. The Solidity contract is educational and unaudited. Do not use real funds or deploy to mainnet.

## Why this angle?

Onchain order books, perpetual futures, funding, margin, oracle feeds, and settlement already exist in the ecosystem. Fluxora should not claim these features alone are novel. The hackathon hypothesis is narrower: **Can a pre-trade receipt that explains risk decisions reduce misunderstood trades while staying consistent with onchain validation?** This should be tested rather than presented as a proven research gap.

## Existing-system limitations to address
- Risk outcomes can be hard for traders to understand before signing.
- Stale or discontinuous oracle data creates unsafe execution conditions.
- Leverage can hide notional exposure and price-move sensitivity.
- Transactions may be delayed, reverted, reordered, or exposed to MEV; settlement is not automatically instant.
- Permissionless code is not automatically safe; contract, oracle, governance, and composability risks remain.

Fluxora surfaces those trade-offs with explicit fail reasons rather than claiming to eliminate them.

## Repository
- `apps/web/`: responsive React + Vite market/trade dashboard
- `contracts/FluxoraGuard.sol`: educational Solidity pre-trade risk gate
- `docs/RESEARCH_AND_ROADMAP.md`: thesis, limitations, evaluation and roadmap

## Run the UI
Requires Node.js 20+.

```bash
cd apps/web
npm install
npm run dev
```

All market values and the receipt are demo-only. Wallet and live chain integration are not yet enabled.

## Contract scope
This is not a full perpetuals exchange. It does not custody tokens, match orders, calculate funding, open positions, liquidate positions, or settle trades. The price publisher is trusted and centralized for the prototype. Tests, robust oracle integration, frontend/contract parity, and an independent audit are required before deployment.

## Safety
Perpetual futures are high risk. This is software experimentation, not financial advice. Never use real assets with this prototype.
