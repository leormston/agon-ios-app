# Testing Guide - Challenges v2

## Pre-requisites
1. Merge the PR and wait for pipeline to deploy
2. Rebuild app on phone (Cmd+R)
3. Make sure you've synced health data (Dashboard > Sync Now)

---

## Feature 1: Public Challenges + Trophies

### Test Public Challenges
1. Go to **Challenges** tab
2. Look for a **"Public Challenges"** button/link
3. Tap it - should see 15 challenges in 5 categories:
   - Walking (Bronze 5K, Silver 10K, Gold 15K steps/day)
   - Distance (Bronze 3km, Silver 5km, Gold 8km/day)
   - Sleep (Bronze 7hrs, Silver 8hrs, Gold 9hrs/day)
   - Running (Bronze 2km, Silver 4km, Gold 6km/day)
   - Sun (Bronze 30min, Silver 60min, Gold 120min/day)
4. Tap **Join** on Bronze Walker
5. Should confirm you've joined
6. Check it appears in your Active challenges

### Test Trophies
1. Go to **Profile** (tap top-right avatar)
2. Look for a **"Trophies"** section/link
3. Tap it - should see a grid of all 15 trophies
4. Earned ones should be coloured (bronze/silver/gold)
5. Unearned ones should be greyed out
6. If you've been averaging 5K+ steps for 7 days, Bronze Walker should be coloured

---

## Feature 2: Live Progress Bar

1. Go to **Challenges** tab
2. Look at an **Active Challenge** card (one with participants)
3. Should see a race-track style progress bar
4. Your position shown relative to others
5. Tap into the challenge detail - should also see progress bar there with all participants

---

## Feature 3: Profile Flair

### Test Editing
1. Go to **Profile** (tap top-right avatar)
2. Look for **Bio**, **Cool Fact**, **Description** fields
3. Tap to edit each one, type something
4. Save/close the profile
5. Reopen profile - your text should still be there

### Test Viewing on Others
1. Go to **Friends** tab
2. Tap a friend's name to view their profile
3. If they've added flair, you should see their bio/cool fact/description
4. If they haven't, those fields should be hidden or show nothing

---

## Feature 4: Challenge Categories

1. Go to **Challenges** tab
2. Look for tab pills at the top: **Active | Completed | Won | Lost**
3. Tap **Active** - shows current challenges
4. Tap **Completed** - shows finished challenges
5. Tap **Won** - shows challenges you came first in
6. Tap **Lost** - shows challenges you didn't win
7. Each should have an appropriate empty state if no challenges match

---

## Feature 5: Social Feed

### Test Feed
1. Tap the **Feed** tab (second from left)
2. Should show posts from friends (no more "Coming Soon")
3. If no friends have activity, should show empty state
4. Pull down to refresh

### Test Likes
1. Find a post in the feed
2. Tap the **heart/like** button
3. Like count should increment
4. Tap again to unlike (if supported)

### Test Comments
1. Find a post in the feed
2. Tap the **comment** button
3. Comment sheet should open
4. Type a comment and submit
5. Comment should appear in the list
6. Close and reopen - comment should persist

---

## Feature 6: Rivals

### Test Adding a Rival
1. Go to **Friends** tab
2. Look for a **"Rivals"** link/button
3. Tap it - should see rivals list (empty initially)
4. Tap **Add Rival**
5. Select a friend from the list
6. They should appear in your rivals list

### Test Rival Stats
1. In the Rivals view, you should see their recent stats compared to yours
2. Should show key metrics side by side

### Test Chart Overlay
1. Go to **Dashboard** > **This Week** > tap a metric (e.g. Steps)
2. In the chart detail view, look for a **rival toggle** or option
3. Enable it - should show a purple line overlaying your chart with your rival's data
4. Toggle off - purple line disappears

### Test Removing a Rival
1. Go to Rivals view
2. Find a rival
3. Swipe to delete or tap a remove button
4. They should be removed from the list

---

## Known Limitations
- Public challenge trophies only check last 7 days - you need 7 days of consistent data
- Feed will be empty until friends complete challenges or hit milestones
- Rival chart overlay requires both you and your rival to have synced data
- Won/Lost categories only populate after challenges end
