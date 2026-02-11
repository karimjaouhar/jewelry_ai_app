# Production Milestones (Play Store Ready)

This document tracks the development milestones required to reach a production-ready Play Store release. After completing each milestone, update this file to mark it complete and note any deviations.

## Status Legend
- Pending: Not started yet.
- In Progress: Actively being worked on.
- Complete: Finished and verified.

## Milestone 0 - Production Foundations (Pending)
**Goal**
- Create Firebase + Google Cloud projects.
- Create Play Console app + subscription products.
- Set up CI basics (build + lint).

**Acceptance Criteria**
- Projects exist and credentials are stored securely.
- App builds cleanly in CI.

**Deviations**
- None yet.

## Milestone 1 - Backend Skeleton (Pending)
**Goal**
- Cloud Run service with health check.
- Config + secrets via Secret Manager.
- Auth middleware for Firebase ID tokens.

**Acceptance Criteria**
- `GET /health` works.
- `POST /v1/generate` rejects unauthenticated calls.

**Deviations**
- None yet.

## Milestone 2 - Auth + Device Identity (Pending)
**Goal**
- Firebase Auth in app.
- App Check (Play Integrity).
- Device fingerprint stored server-side for trial enforcement.

**Acceptance Criteria**
- Backend verifies Firebase tokens.
- Device fingerprint recorded for trial enforcement.

**Deviations**
- None yet.

## Milestone 3 - Credits Ledger (Pending)
**Goal**
- Firestore schema for users, credits, usage logs.
- Trial: 5 credits once per device.
- Rollover: cap at 1 month of credits.
- Monthly reset job (Cloud Scheduler + Cloud Run).

**Acceptance Criteria**
- Credits balance updates correctly through a simulated billing cycle.

**Deviations**
- None yet.

## Milestone 4 - Play Billing Integration (Pending)
**Goal**
- In-app subscriptions wired (Starter/Pro/Studio).
- Backend purchase verification (Google Play Developer API).
- RTDN webhook for renewals/cancellations.

**Acceptance Criteria**
- Purchase grants credits.
- Renewals apply monthly credits.
- Cancellations stop future credits.

**Deviations**
- None yet.

## Milestone 5 - Generation Pipeline (Backend) (Pending)
**Goal**
- Backend validates request and checks credits.
- Calls Gemini with server-side API key.
- Returns images to client.
- Logs usage and deducts credits.

**Acceptance Criteria**
- End-to-end generate works without the app holding the API key.

**Deviations**
- None yet.

## Milestone 6 - App Integration (Pending)
**Goal**
- Remove API key settings screen.
- Replace generation calls with backend.
- Add paywall + credit balance display.
- Handle “no credits” flows gracefully.

**Acceptance Criteria**
- Users can subscribe, see credits, and generate images.

**Deviations**
- None yet.

## Milestone 7 - Abuse Protection + Observability (Pending)
**Goal**
- Rate limits per user + IP.
- Logs, error reporting, basic metrics.
- Alerting on failures and high error rates.

**Acceptance Criteria**
- System tolerates spikes and is diagnosable in production.

**Deviations**
- None yet.

## Milestone 8 - Compliance & Store Readiness (Pending)
**Goal**
- Privacy policy + data safety forms.
- In-app disclosures and support links.
- Play Store listing assets.

**Acceptance Criteria**
- Play Console review checklist is clean.

**Deviations**
- None yet.

## Milestone 9 - QA + Launch (Pending)
**Goal**
- Internal testing track rollout.
- Crash-free baseline and performance checks.
- Final release build signed.

**Acceptance Criteria**
- App passes internal testing and is ready for production rollout.

**Deviations**
- None yet.
