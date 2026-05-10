# Second Innings Screen Rebuild - Quick Reference

## TL;DR
When second innings starts, the app creates a **brand new screen instance** that automatically fetches all batsman and bowler details from the database.

---

## The 7-Step Process

### Step 1: Create Striker Batsman
```dart
final striker = Batsman.create(
  inningsId: secondInnings.inningsId,
  teamId: secondInnings.battingTeamId,
  playerId: strikerId,  // User selected
);
```

### Step 2: Create Non-Striker Batsman
```dart
final nonStriker = Batsman.create(
  inningsId: secondInnings.inningsId,
  teamId: secondInnings.battingTeamId,
  playerId: nonStrikerId,  // User selected
);
```

### Step 3: Create Bowler
```dart
final bowler = Bowler.create(
  inningsId: secondInnings.inningsId,
  teamId: secondInnings.bowlingTeamId,
  playerId: bowlerId,  // User selected
);
```

### Step 4: Verify All Players in Database
```dart
// Confirms all data was saved correctly
Batsman.getByBatId(striker.batId)      ✓
Batsman.getByBatId(nonStriker.batId)   ✓
Bowler.getByBowlerId(bowler.bowlerId)  ✓

// Fetch player names for logging
TeamMember.getByPlayerId(strikerId).teamName
TeamMember.getByPlayerId(nonStrikerId).teamName
TeamMember.getByPlayerId(bowlerId).teamName
```

### Step 5: Clear LED Display
```dart
await _clearLEDDisplay();  // Reset before switching screens
```

### Step 6: Wait for Persistence
```dart
await Future.delayed(const Duration(milliseconds: 500));
```

### Step 7: Navigate to New Screen
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => CricketScorerScreen(
      matchId: widget.matchId,
      inningsId: secondInnings.inningsId,
      strikeBatsmanId: striker.batId,
      nonStrikeBatsmanId: nonStriker.batId,
      bowlerId: bowler.bowlerId,
    ),
  ),
);
```

---

## Screen Auto-Rebuild

### New Instance Created
- Fresh `CricketScorerScreen()` widget instantiated
- `createState()` creates new `_CricketScorerScreenState`

### initState() Runs
```dart
void initState() {
  super.initState();
  _scrollController = ScrollController();
  _initializeMatch();  // ← FRESH DATA FETCH!
  // ... LED updates ...
}
```

### _initializeMatch() Fetches All Data
```dart
// Fresh fetch for second innings
currentMatch = Match.getByMatchId(widget.matchId);
currentInnings = Innings.getByInningsId(widget.inningsId);  // 2nd innings
currentScore = Score.getByInningsId(widget.inningsId);      // 2nd innings
strikeBatsman = Batsman.getByBatId(widget.strikeBatsmanId);
nonStrikeBatsman = Batsman.getByBatId(widget.nonStrikeBatsmanId);
currentBowler = Bowler.getByBowlerId(widget.bowlerId);
```

### UI Builds with Fresh Data
```
✅ Team Name: Batting Team (2nd)
✅ Striker: SELECTED PLAYER - Runs: 0, Balls: 0
✅ Non-Striker: SELECTED PLAYER - Runs: 0, Balls: 0
✅ Bowler: SELECTED PLAYER - Overs: 0.0, Runs: 0
✅ Score: 0/0 (0.0)
✅ Target: X runs
✅ Ready to score!
```

---

## State Variables Reset

| Variable | Value |
|----------|-------|
| `isInitializing` | `true` → `false` (after data fetch) |
| `isMatchComplete` | `false` |
| `isRunout` | `false` |
| `showExtrasOptions` | `false` |
| `isNoBall` | `false` |
| `isWide` | `false` |
| `isByes` | `false` |
| `runsInCurrentOver` | `0` |
| `actionHistory` | `[]` (empty) |
| All animations | `false` |

---

## LED Display Timeline

| Time | Action |
|------|--------|
| 0ms | Navigate to new screen |
| 0-500ms | Screen building, initState running |
| 500ms | Player data verified, LED cleared |
| 3s | `_updateLEDTimeAndTemp()` called |
| 3.1s | LED shows time + temperature |
| Every 60s | Periodic LED update |
| On every ball | Score update batch sent |

---

## Debug Output to Watch

```
🏏 [SECOND INNINGS] Finalizing...
✅ Batsmen created: striker, non-striker
✅ Bowler created: bowler
✅ All players verified in database
🚀 Navigating to second innings screen...
✅ [COMPLETE] Second innings screen loaded
```

Then on new screen:

```
🚀 CricketScorerScreen: Initializing EnvironmentService...
🎬 CricketScorerScreen: Initial LED update
```

---

## Data Persistence Guarantee

✅ **Database**: All players saved via `.create()` methods
✅ **Verification**: Fresh fetches confirm data exists
✅ **Screen**: New instance receives verified IDs
✅ **Fresh Fetch**: `_initializeMatch()` re-fetches everything
✅ **UI Display**: Shows populated player names and stats

---

## Common Questions

**Q: What if player creation fails?**
A: Exception is caught in try-catch, error dialog shown, returns early.

**Q: What if database fetch returns null?**
A: Caught in Step 4 verification, throws exception before navigation.

**Q: Does the old screen stay in memory?**
A: No, `pushReplacement()` removes old instance from stack.

**Q: When is player name first displayed?**
A: In `build()` method, fetched via `TeamMember.getByPlayerId()`.

**Q: Can I manually test this?**
A: Yes, follow these steps:
1. Start first innings, score some runs
2. Complete first innings (reach overs limit)
3. Click "Start Second Innings"
4. Select striker, non-striker, bowler from dropdowns
5. Click "Start Second Innings" button
6. Watch debug output and UI refresh
7. Verify player names appear in UI

---

## File References

| File | Method | Purpose |
|------|--------|---------|
| `cricket_scorer_screen.dart` | `_startSecondInnings()` | Initiate second innings |
| `cricket_scorer_screen.dart` | `_showSelectOpeningBatsmenDialog()` | Show player selection |
| `cricket_scorer_screen.dart` | `_finalizeSecondInnings()` | Create players & navigate |
| `cricket_scorer_screen.dart` | `_initializeMatch()` | Fetch all data on rebuild |
| `cricket_scorer_screen.dart` | `build()` | Display all player details |

---

**Last Updated**: 2026-02-10
**Status**: ✅ Production Ready
