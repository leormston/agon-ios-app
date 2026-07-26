# Agon Health — MVP Roadmap

## MVP Goal
A working app where users can connect HealthKit, see real health data on their dashboard, create/join challenges with friends, and compete on leaderboards.

---

## Phase 1: Live Health Data (HealthKit) ✅
- [x] 1. Add HealthKit entitlement & capability to project
- [x] 2. Create HealthKitService (request permissions, read data)
- [x] 3. Pull steps, calories, sleep, heart rate from HealthKit
- [x] 4. Create data models (HealthMetric, DailySnapshot)
- [x] 5. Create DashboardViewModel to feed real data to UI
- [x] 6. Replace placeholder dashboard with live HealthKit data
- [x] 7. Add pull-to-refresh on dashboard

## Phase 2: Authentication ✅
- [x] 8. Add Apple Sign In capability
  - AC1: "Sign in with Apple" button visible on sign-in screen ✅
  - AC2: Tapping it triggers the Apple auth sheet ✅
  - AC3: Successful sign-in navigates user to the main app ✅
- [x] 9. Add Google Sign In (via AWS Cognito identity provider)
  - AC1: "Sign in with Google" button visible on sign-in screen ✅
  - AC2: Tapping it opens Google OAuth flow (placeholder — wired in Phase 3)
  - AC3: Successful sign-in navigates user to the main app (Phase 3)
- [x] 10. Create AuthService (supports both Apple & Google)
  - AC1: AuthService exposes a single `signIn(provider:)` method ✅
  - AC2: Auth tokens are stored securely in Keychain ✅
  - AC3: `isAuthenticated` state updates reactively across the app ✅
- [x] 11. Create sign-in screen (Apple + Google buttons)
  - AC1: Sign-in screen shows on first launch (no session) ✅
  - AC2: Both buttons are styled per Apple/Google brand guidelines ✅
  - AC3: Error states shown if sign-in fails ✅
- [x] 12. Create onboarding flow (sign in → HealthKit permission request)
  - AC1: After sign-in, user is prompted to grant HealthKit access ✅
  - AC2: User can skip HealthKit and still use the app ✅
  - AC3: Flow doesn't repeat on subsequent launches ✅
- [x] 13. Store user profile locally
  - AC1: Display name and email persisted after sign-in ✅
  - AC2: Profile data survives app restart ✅
  - AC3: Signing out clears stored profile ✅

## Phase 3: Backend & User Profiles (AWS) ✅
- [x] 14. Set up AWS backend (Cognito for auth, DynamoDB, API Gateway, Lambda)
  - AC1: Cognito User Pool created with Apple + Google as identity providers ✅
  - AC2: API Gateway endpoint returns 200 on health check ✅
  - AC3: DynamoDB tables created (Users, HealthSnapshots) ✅
- [x] 15. Connect Apple/Google Sign In to AWS Cognito
  - AC1: iOS app exchanges Apple/Google token for Cognito session ✅
  - AC2: User record created in Cognito on first sign-in ✅
  - AC3: Subsequent sign-ins return existing user ✅
- [x] 16. Sync user profile to backend
  - AC1: Profile (name, avatar, join date) syncs to DynamoDB after sign-in ✅
  - AC2: Profile updates on device reflect in backend within 5 seconds ✅
- [x] 17. Sync daily health snapshots to backend
  - AC1: Today's health data sent to API on each app open ✅
  - AC2: Data stored in DynamoDB with user ID and date as keys ✅
  - AC3: Duplicate submissions for same day are idempotent (upsert) ✅
- [x] 18. Fetch other users' data for leaderboards
  - AC1: API returns list of users + scores for a given challenge ✅
  - AC2: Response time under 1 second for up to 50 participants ✅
  - AC3: Current user's rank is highlighted in the response ✅

## Phase 4: Challenges & Competition ✅
- [x] 19. Create Challenge model (type, timeframe, participants, scoring)
  - AC1: Challenge has a metric type, start/end date, and participant list ✅
  - AC2: Scoring formula defined (e.g. % improvement or absolute value) ✅
  - AC3: Challenge states: pending, active, completed ✅
- [x] 20. Create challenge flow (pick metric, set duration, invite friends)
  - AC1: User can select from available health metrics ✅
  - AC2: User can set duration (1 day, 1 week, 1 month) ✅
  - AC3: User can invite friends before starting ✅
  - AC4: Challenge created in backend on confirmation ✅
- [x] 21. Join challenge flow
  - AC1: User sees available challenges they've been invited to ✅
  - AC2: Tapping "Join" adds them as a participant ✅
  - AC3: Challenge appears in their Active Challenges list ✅
- [x] 22. Scoring logic (compare progress within timeframe)
  - AC1: Scores update daily based on health data ✅
  - AC2: Ranking reflects current standings accurately ✅
  - AC3: Tied scores handled gracefully ✅
- [x] 23. Live leaderboard with real data
  - AC1: Leaderboard shows all participants ranked by score ✅
  - AC2: Current user highlighted ✅
  - AC3: Leaderboard refreshes on pull-to-refresh ✅
- [x] 24. Challenge completion & winner announcement
  - AC1: Challenge auto-completes when end date is reached ✅
  - AC2: Winner shown on a results screen (via challenge details)
  - AC3: Push notification sent to all participants (Phase 5)

## Phase 5: Social
- [ ] 25. Add friends (invite link or search)
  - AC1: User can search by username or name
  - AC2: User can share an invite link
  - AC3: Friend request sent and visible to recipient
- [ ] 26. Friends list
  - AC1: Shows all accepted friends
  - AC2: Shows pending requests (sent and received)
  - AC3: Can remove a friend
- [ ] 27. Activity feed (real friend activity from backend)
  - AC1: Feed shows friends' recent completions and milestones
  - AC2: Feed updates on pull-to-refresh
  - AC3: Empty state shown when no friends have activity
- [ ] 28. Push notifications (challenge invites, results, milestones)
  - AC1: User receives notification when invited to a challenge
  - AC2: User receives notification when a challenge ends
  - AC3: Tapping notification navigates to relevant screen

## Phase 6: Polish & Launch
- [ ] 29. Onboarding flow (welcome screens, permissions, goal setting)
  - AC1: 2-3 welcome screens explaining the app
  - AC2: Smooth transitions between steps
  - AC3: Only shown on first launch
- [ ] 30. Loading states & error handling
  - AC1: All network calls show loading indicators
  - AC2: Errors show user-friendly messages with retry option
  - AC3: Offline state handled gracefully
- [ ] 31. App Store listing (screenshots, description, privacy policy)
  - AC1: 5 screenshots covering main features
  - AC2: Privacy policy URL live and linked
  - AC3: App description written and reviewed
- [ ] 32. TestFlight beta
  - AC1: Build uploaded to App Store Connect
  - AC2: At least 3 external testers invited
  - AC3: Feedback collected and critical bugs fixed
- [ ] 33. App Store submission
  - AC1: App passes App Store review
  - AC2: Live on the App Store and downloadable

---

## ✅ Done
- [x] Xcode project setup
- [x] Tab navigation (Dashboard, Challenges, Friends)
- [x] Top nav bar (logo left, profile right)
- [x] Dashboard UI with placeholder metrics
- [x] Challenges UI
- [x] Friends/leaderboard UI
- [x] Profile sheet
- [x] Colour scheme applied
- [x] Logo + App icon
- [x] Running on physical iPhone
- [x] .gitignore added
- [x] HealthKit entitlement & service created
- [x] Health data models (HealthMetric, DailySnapshot)
- [x] DashboardViewModel created

---

## Notes
- iOS 17+ / SwiftUI / MVVM
- Backend: AWS (Cognito, DynamoDB, API Gateway, Lambda)
- HealthKit only works on real device (not simulator)
- Auth: Apple Sign In + Google Sign In via Cognito
