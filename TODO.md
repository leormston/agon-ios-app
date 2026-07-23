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

## Phase 2: Authentication
- [ ] 8. Add Apple Sign In capability
- [ ] 9. Add Google Sign In (via AWS Cognito identity provider)
- [ ] 10. Create AuthService (supports both Apple & Google)
- [ ] 11. Create sign-in screen (Apple + Google buttons)
- [ ] 12. Create onboarding flow (sign in → HealthKit permission request)
- [ ] 13. Store user profile locally

## Phase 3: Backend & User Profiles (AWS)
- [ ] 14. Set up AWS backend (Cognito for auth, DynamoDB, API Gateway, Lambda)
- [ ] 15. Connect Apple/Google Sign In to AWS Cognito
- [ ] 16. Sync user profile to backend
- [ ] 17. Sync daily health snapshots to backend
- [ ] 18. Fetch other users' data for leaderboards

## Phase 4: Challenges & Competition
- [ ] 16. Create Challenge model (type, timeframe, participants, scoring)
- [ ] 17. Create challenge flow (pick metric, set duration, invite friends)
- [ ] 18. Join challenge flow
- [ ] 19. Scoring logic (compare progress within timeframe)
- [ ] 20. Live leaderboard with real data
- [ ] 21. Challenge completion & winner announcement

## Phase 5: Social
- [ ] 22. Add friends (invite link or search)
- [ ] 23. Friends list
- [ ] 24. Activity feed (real friend activity from backend)
- [ ] 25. Push notifications (challenge invites, results, milestones)

## Phase 6: Polish & Launch
- [ ] 26. Onboarding flow (welcome screens, permissions, goal setting)
- [ ] 27. Loading states & error handling
- [ ] 28. App Store listing (screenshots, description, privacy policy)
- [ ] 29. TestFlight beta
- [ ] 30. App Store submission

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
- Start Phase 1 next
