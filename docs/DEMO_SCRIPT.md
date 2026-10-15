# Fluxora hackathon demo script

## 60-second pitch

Perpetual trading interfaces show users a direction and leverage, but the risk rules behind that action are easy to overlook. Fluxora explores a different interaction: before execution, the trader receives a Guarded Execution Receipt that states exposure, collateral assumptions, oracle freshness, policy results, and clear rejection reasons. The aim is to make the decision explainable and to test whether users make better decisions. This is a prototype and a research hypothesis, not a claim that current exchanges lack risk controls.

## 3-minute walkthrough

1. Open BTC-PERP and state clearly that prices and market metrics are simulated.
2. Set margin to $2,500 at 3×. Explain that demo notional is $7,500 and preview fees are only illustrative.
3. Open **Preview guarded order**. Walk through each policy result and say that the local receipt is not an onchain transaction.
4. Set leverage above the configured 5× interface policy. The interface should flag the policy failure. Note that a contract policy must be independently enforced, not trusted to the frontend.
5. In the code/architecture explanation, show the Solidity contract's trusted price publisher, freshness window, deviation threshold, leverage cap, notional ceiling, preview event, and reason codes.
6. Explain the next milestone: deploy to a testnet, connect the wallet, publish oracle data using a proper oracle adapter, call the contract preview, and show the confirmed transaction hash.

## Judge questions to prepare for

**What is novel?** We are not claiming perpetual futures are novel. The testable contribution is a pre-trade, human-readable risk receipt plus measurable frontend/onchain decision parity and a formative usability evaluation.

**What does it solve?** It aims to make leverage, notional, oracle freshness, and block reasons visible before signing. We need user-study results to show whether this improves comprehension.

**Is this fully onchain?** Not yet. The current web app is a simulation; the Solidity file records pre-trade previews but is not a complete exchange. State this honestly.

**How do you prove it works?** Unit and fuzz tests for every boundary, zero disagreement between frontend and contract results over generated inputs, and testnet measurements for gas and p50/p95 latency.

**What are the risks?** The sample contract uses a trusted publisher, and there is no custody, matching, funding, settlement, liquidation, production oracle, or audit.
