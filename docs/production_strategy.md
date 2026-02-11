# Production Strategy - Play Store Ready

## Scope
This document captures the agreed production strategy for a Play Store release:
- Backend-only Gemini calls (no API key in the app).
- Firebase Auth + server-side verification.
- Monthly credits subscription model.
- 5-credit trial (one per device).
- Play Billing only (no in-app alternative payment).
- Device-only storage for generated images.
- Global pricing (USD base, Play handles conversion).

## Final Decisions
### Pricing Tiers (Monthly Credits)
- Starter: 40 credits / $11.99
- Pro: 100 credits / $24.99
- Studio: 200 credits / $49.99

### Trial
- 5 credits once per device.

### Rollover
- Unused credits roll over with a cap of 1 month of credits.
  - Example: Pro plan has 100 credits/month -> max balance 200.

### Storage
- Generated images are stored locally on device only.
- Backend stores only metadata and usage logs.

## Cost and Margin Model
Assumptions:
- Cost per image: $0.10
- Google Play subscription fee: 15%
- Margin formula: (Net after Play fee - API cost) / Net after Play fee

| Plan | Credits | Price | Net After 15% | API Cost | Gross Profit | Margin |
|---|---:|---:|---:|---:|---:|---:|
| Starter | 40 | $11.99 | $10.19 | $4.00 | $6.19 | 60.8% |
| Pro | 100 | $24.99 | $21.24 | $10.00 | $11.24 | 52.9% |
| Studio | 200 | $49.99 | $42.49 | $20.00 | $22.49 | 52.9% |

Notes:
- Does not include infra, support, refunds, or taxes.
- Rollover cap limits liability.

## Architecture Overview
### Mobile App
- Uses Firebase Auth for sign-in.
- Calls backend for generation.
- Displays paywall based on entitlements.
- Saves images locally on device.

### Backend (Cloud Run)
- Verifies Firebase ID tokens.
- Checks subscription entitlement + credits.
- Enforces trial, rollover cap, and rate limits.
- Calls Gemini with a single server-side API key.
- Returns images to client.

### Data (Firestore)
- Users: uid, plan, credit balance, rollover balance, trial_used, device_fingerprint(s).
- Usage: generation logs, counters per period.

## Backend Endpoints (Minimal)
- `POST /v1/generate`
  - Auth: Firebase ID token.
  - Checks: entitlement, credits, rate limits.
  - Deducts credits and returns images.
- `GET /v1/entitlements`
  - Returns plan, credit balance, rollover balance, next reset date.
- `POST /v1/billing/verify`
  - Verifies Play Billing purchase token.
  - Grants monthly credits.
- `POST /v1/billing/rtdn`
  - Receives Play RTDN updates for renewals/cancellations.

## Abuse Prevention (Minimum)
- Firebase App Check (Play Integrity).
- Rate limits per user and per IP.
- Trial enforced per device + per account.

## Play Store Compliance
- All in-app digital purchases must use Play Billing.
- Alternative payment methods can only be used outside the app unless explicitly allowed by Play policy.

## Open Items
- Confirm which metrics/logging platform (Crashlytics, Sentry).
- Confirm exact limits for rate limiting (per day / per hour).
