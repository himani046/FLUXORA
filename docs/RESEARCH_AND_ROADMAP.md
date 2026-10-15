# Research framing and roadmap

## Thesis
The market already has mature decentralized perpetual exchanges and onchain order-book projects. Onchain matching, funding payments, margin, oracle integration and settlement are not unique by themselves. Do not claim Fluxora is the first or uniquely novel product in those categories.

A defensible hackathon hypothesis is: **Can a pre-trade, human-readable risk receipt reduce dangerous or misunderstood perpetual trades while keeping execution decisions consistent with onchain validation?** This is a hypothesis to test, not a proven research gap.

## Existing-system limitations to investigate
1. **Risk complexity:** users can find leverage/notional relationships difficult to intuit. Test comprehension instead of assuming all existing UIs fail here.
2. **Oracle dependency:** stale, manipulated, or discontinuous feeds can cause unsafe execution. Define freshness, deviation limits, and circuit-breaker behavior.
3. **Execution uncertainty:** transactions can be delayed, reverted, or reordered. A preview cannot guarantee inclusion price or eliminate MEV.
4. **Liquidation externalities:** volatility and congestion complicate liquidations. Fluxora does not implement liquidation.
5. **Transparency is not usability:** public contract state is not automatically understandable.
6. **Gas and latency:** onchain checks can cost more. Measure testnet gas and p50/p95 latency rather than claiming instant settlement.
7. **Protocol risk:** bugs, oracle failure, governance, and composability risks remain.

## Proposed contribution: Guarded Execution Receipt
Each attempted order gets a compact receipt with direction, collateral, leverage, notional, reference price; pass/fail policy checks; human-readable reason codes; oracle freshness/deviation status; and an explicit local-demo vs confirmed-onchain distinction. Differentiation must be measured through policy transparency and usability, not claimed because a dashboard exists.

## MVP
- Premium responsive React UI with market chart, trade ticket, margin and leverage calculations.
- Explicit demo labels and simulated market data.
- Solidity risk-gate contract for sample price publishing and a recorded preview result.
- Visible failure scenarios for stale price, excess leverage, and exposure cap.

## Required before claiming a complete onchain exchange
- Wallet integration and chain guard; testnet deployment with verified source.
- Shared risk calculations and tests proving frontend/contract decision parity.
- Real oracle adapter with documented decimals, update/fallback semantics and freshness rules.
- Token deposits, secure accounting, matching, position lifecycle, funding math, fees, liquidation, and settlement.
- Pause/circuit breaker, access-control review, monitoring, threat model and independent audit.

## Evaluation plan
### Unit/invariant tests
- Fresh/stale boundary, one second past threshold, and missing observation.
- Price deviation at and beyond threshold, including rounding boundaries.
- Zero collateral/notional, leverage below 1x, configured maximum and one above.
- Notional at/above cap and multiplication/division rounding.
- Fuzz collateral, notional, leverage and prices; accepted must imply all invariants pass.
- Verify only publisher changes prices, only admin changes policy.
- Check frontend and contract decisions against identical generated inputs.

### Formative user study
Compare a standard ticket to the Guarded Execution Receipt with 8–15 participants. Ask them to predict outcomes for high leverage, stale oracle, price deviation, low collateral and a valid trade. Measure decision accuracy, time and confidence. A small sample is formative, not generalizable.

### Report measurable outputs honestly
- false-accept/false-block rate;
- frontend/contract disagreement count (target zero in generated tests);
- preview and policy-update gas on a named testnet;
- p50/p95 confirmation times;
- participant scenario accuracy and decision time;
- behavior under stale feeds and price discontinuity.

## Demo script
1. Show a valid 3x position and explain collateral vs notional.
2. Increase leverage above the policy limit and show the reason for blocking.
3. Mark an oracle observation stale and demonstrate fail-closed behavior.
4. Set a reference price far from oracle and show deviation rejection.
5. Only if deployed integration exists, submit testnet preview and show tx hash/event.

## Scope and safety
The current proof of concept does not settle trades, custody assets, match live orders, calculate funding, or liquidate positions. The Solidity publisher is trusted and centralized for the demo. A preview record is not proof of execution. Do not use real assets or make production claims until full implementation, tests, and independent audit are complete.
