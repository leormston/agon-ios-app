# Agon Health — Handoff Document

## Last Updated: 25 July 2026

---

## Current State

The app has a working UI (Dashboard, Challenges, Friends tabs), Apple Sign In authentication, and a live AWS backend deployed via Terraform + GitHub Actions.

### What's Live
- **iOS App**: SwiftUI app with HealthKit integration, Apple Sign In, onboarding flow
- **AWS Backend** (eu-west-2):
  - Cognito User Pool: `eu-west-2_SqjPkClKx` (Apple + Google providers)
  - Cognito Client ID: `1p8ijeoldmpe4j068e6g71qimm`
  - API Gateway: `https://dby9d5g95b.execute-api.eu-west-2.amazonaws.com`
  - Lambda: `agon-dev-api` (Node.js 20, arm64)
  - DynamoDB: `agon-dev-users`, `agon-dev-health-snapshots`
  - Terraform state bucket: `agon-terraform-state-8066a6e1`

### Branches
- `main` — all merged and up to date
- All feature branches merged: `feature/healthkit-integration`, `feature/authentication`, `feature/aws-backend`, `feature/complete-backend-integration`

---

## What's Done (Phases 1–3 partial)

| # | Task | Status |
|---|------|--------|
| 1–7 | Phase 1: HealthKit | ✅ Complete |
| 8–13 | Phase 2: Authentication | ✅ Complete |
| 14 | AWS Backend setup | ✅ Complete |
| 15 | Connect iOS to Cognito | ✅ Complete |
| 16 | Sync user profile to backend | ⬜ Next |
| 17 | Sync daily health snapshots | ⬜ Next |
| 18 | Fetch other users' data for leaderboards | ⬜ Next |

---

## What's Next (Resume Here)

### Quick Fix: Google Sign In redirect
- Google sign-in opens Cognito Hosted UI but doesn't redirect back to the app
- Need to: register `agon` URL scheme in Info.plist + handle the callback in AgonApp.swift to exchange the auth code for tokens
- ~15 min task

### Requirement 16: Sync user profile to backend
- The `APIService.updateProfile()` method exists but needs to be called reliably on app launch (not just sign-in)
- AC: Profile (name, avatar, join date) syncs to DynamoDB, updates reflect within 5 seconds

### Requirement 17: Sync daily health snapshots to backend
- `APIService.syncHealthData()` exists but isn't called from the DashboardViewModel yet
- Need to call it after HealthKit data is fetched, sending today's metrics to `POST /health/sync`
- AC: Data sent on each app open, stored with userId + date, idempotent upserts

### Requirement 18: Fetch other users' data for leaderboards
- Lambda `/leaderboard/{challengeId}` route exists but returns empty placeholder
- Need to query DynamoDB for challenge participants' health snapshots
- AC: Returns ranked list of users + scores, current user highlighted, <1s response

### After that: Phase 4 (Challenges & Competition)

---

## Key Files

| File | Purpose |
|------|---------|
| `Agon/Services/AuthService.swift` | Sign in/out, Keychain, triggers Cognito |
| `Agon/Services/CognitoService.swift` | Token exchange with Cognito |
| `Agon/Services/APIService.swift` | Authenticated HTTP calls to backend |
| `Agon/Services/HealthKitService.swift` | Reads Apple Health data |
| `Agon/ViewModels/DashboardViewModel.swift` | Feeds HealthKit data to dashboard |
| `lambda/src/index.js` | Lambda API handler (all routes) |
| `infra/` | Terraform modules (Cognito, DynamoDB, API GW, Lambda) |
| `.github/workflows/deploy-infra.yml` | CI/CD pipeline |
| `TODO.md` | Full MVP roadmap with acceptance criteria |
| `RULES.md` | Project rules (Terraform, GitHub Actions, no ClickOps) |

---

## Commands to Resume

```bash
cd /Users/louie/Documents/r/agon-ios-app
git checkout main
git pull
git checkout -b feature/data-sync  # or whatever the next task is
```

---

## GitHub Secrets (already configured)
- AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
- APPLE_SERVICES_ID / APPLE_TEAM_ID / APPLE_KEY_ID / APPLE_PRIVATE_KEY
- GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET
