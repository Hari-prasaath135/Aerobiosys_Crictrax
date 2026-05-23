# Second Innings Screen Rebuild Flow

## Overview
When the second innings starts, the app automatically navigates to a **new instance** of `CricketScorerScreen` which triggers a complete screen rebuild and fresh data fetching.

---

## Complete Flow Diagram

```
First Innings Complete
    ↓
_endInnings() called
    ↓
_showVictoryDialog() displayed
    ↓
User clicks "Start Second Innings"
    ↓
_startSecondInnings() async
    ├─ Mark first innings as completed
    ├─ Create new Innings object (second innings)
    └─ Create Score object for second innings
    ↓
_showSelectOpeningBatsmenDialog()
    ├─ Show striker dropdown (available players)
    ├─ Show non-striker dropdown (available players)
    └─ Show bowler dropdown (bowling team)
    ↓
User selects all three and clicks "Start Second Innings"
    ↓
_finalizeSecondInnings() async [DETAILED STEPS]
    │
    ├─ STEP 1: Create Batsman object for striker
    │   └─ Batsman.create() → Saves to database
    │
    ├─ STEP 2: Create Batsman object for non-striker
    │   └─ Batsman.create() → Saves to database
    │
    ├─ STEP 3: Create Bowler object for bowler
    │   └─ Bowler.create() → Saves to database
    │
    ├─ STEP 4: Verify all players in database
    │   ├─ Batsman.getByBatId(striker.batId) ✓
    │   ├─ Batsman.getByBatId(nonStriker.batId) ✓
    │   ├─ Bowler.getByBowlerId(bowler.bowlerId) ✓
    │   └─ Fetch and verify player names
    │
    ├─ STEP 5: Clear LED display
    │   └─ _clearLEDDisplay() async
    │
    ├─ STEP 6: Wait 500ms for persistence
    │   └─ Future.delayed(500ms)
    │
    └─ STEP 7: Navigate to new CricketScorerScreen
        └─ Navigator.pushReplacement()

NEW SCREEN INSTANCE CREATED
    ↓
CricketScorerScreen.createState() called
    ↓
_CricketScorerScreenState.initState() called
    ├─ _scrollController = ScrollController()
    ├─ _initializeMatch() async [FRESH DATA FETCH]
    │   ├─ Match.getByMatchId(widget.matchId)
    │   ├─ Innings.getByInningsId(widget.inningsId) [NEW SECOND INNINGS]
    │   ├─ Score.getByInningsId(widget.inningsId) [NEW SECOND INNINGS SCORE]
    │   ├─ Batsman.getByBatId(widget.strikeBatsmanId) [STRIKER]
    │   ├─ Batsman.getByBatId(widget.nonStrikeBatsmanId) [NON-STRIKER]
    │   └─ Bowler.getByBowlerId(widget.bowlerId) [BOWLER]
    │
    ├─ Initialize EnvironmentService
    ├─ Start periodic LED time/temp updates (every 60s)
    └─ Call _updateLEDTimeAndTemp() after 3s

STATE INITIALIZED
    ↓
build() method called
    ├─ Display loading spinner while isInitializing = true
    │
    └─ Once isInitializing = false:
        ├─ Batsmen Stats Section
        │   ├─ Striker: ${strikeBatsman.name}
        │   ├─ Non-Striker: ${nonStrikeBatsman.name}
        │   └─ Stats: runs, balls, 4s, 6s, SR
        │
        ├─ Bowler Stats Section
        │   ├─ Bowler: ${bowler.name}
        │   └─ Stats: overs, maidens, runs, wickets, economy
        │
        ├─ Score Card
        │   ├─ Team: ${battingTeamName} (2nd)
        │   ├─ Score: X/Y
        │   ├─ Overs: Z.Z
        │   ├─ CRR: W.WW
        │   └─ Target display (if applicable)
        │
        ├─ Current Over Display
        ├─ Run Buttons (0-6)
        ├─ Action Buttons (Wicket, Swap, Runout, Undo)
        └─ All ready for scoring

LED DISPLAY UPDATED (After 3s)
    ↓
_updateLEDTimeAndTemp()
    ├─ Time display
    └─ Temperature display
```

---

## Key Data Points Fetched

### 1. **Innings Data**
- `inningsId`: New second innings ID
- `battingTeamId`: Team that was bowling in first innings
- `bowlingTeamId`: Team that was batting in first innings
- `targetRuns`: First innings runs + 1
- `hasValidTarget`: true
- `isSecondInnings`: true

### 2. **Batsman Data (Striker)**
```dart
Batsman {
  batId: 'unique-bat-id',
  inningsId: 'second-innings-id',
  playerId: 'selected-striker-id',
  teamId: 'batting-team-id',
  runs: 0,
  ballsFaced: 0,
  fours: 0,
  sixes: 0,
  dotBalls: 0,
  extras: 0,
  isOut: false,
  strikeRate: 0.0
}
```

### 3. **Batsman Data (Non-Striker)**
```dart
Batsman {
  batId: 'unique-bat-id',
  inningsId: 'second-innings-id',
  playerId: 'selected-non-striker-id',
  teamId: 'batting-team-id',
  runs: 0,
  ballsFaced: 0,
  // ... rest same as striker
}
```

### 4. **Bowler Data**
```dart
Bowler {
  bowlerId: 'unique-bowler-id',
  inningsId: 'second-innings-id',
  playerId: 'selected-bowler-id',
  teamId: 'bowling-team-id',
  overs: 0.0,
  maidens: 0,
  runsConceded: 0,
  wickets: 0,
  balls: 0,
  extras: 0,
  economy: 0.0
}
```

### 5. **Score Data**
```dart
Score {
  scoreId: 'unique-score-id',
  inningsId: 'second-innings-id',
  totalRuns: 0,
  wickets: 0,
  currentBall: 0,
  overs: 0.0,
  byes: 0,
  wides: 0,
  noBalls: 0,
  totalExtras: 0,
  crr: 0.0,
  strikeBatsmanId: 'striker-bat-id',
  nonStrikeBatsmanId: 'non-striker-bat-id',
  currentBowlerId: 'bowler-id',
  currentOver: []
}
```

---

## Database Verification Steps

The updated `_finalizeSecondInnings()` method includes explicit verification:

```
✅ Create Striker → Batsman.create() → Save to DB
✅ Create Non-Striker → Batsman.create() → Save to DB
✅ Create Bowler → Bowler.create() → Save to DB
✅ Verify Striker → Batsman.getByBatId() [confirms in DB]
✅ Verify Non-Striker → Batsman.getByBatId() [confirms in DB]
✅ Verify Bowler → Bowler.getByBowlerId() [confirms in DB]
✅ Fetch player names → TeamMember.getByPlayerId()
✅ Navigate → CricketScorerScreen instantiation
✅ Fresh fetch → _initializeMatch() [all data re-fetched]
```

---

## Debug Output

When second innings starts, you'll see:

```
🏏 [SECOND INNINGS] Finalizing...
📊 Innings ID: innings_2024_001_2
🏏 Batting Team: team_002
🎳 Bowling Team: team_001
👤 [STEP 1] Creating batsmen...
✅ Batsmen created:
   Striker: bat_2024_001_2_strike (Player: player_005)
   Non-Striker: bat_2024_001_2_nonstr (Player: player_006)
🎳 [STEP 2] Creating bowler...
✅ Bowler created: bowl_2024_001_2_001 (Player: player_001)
🔍 [STEP 3] Verifying player data in database...
✅ All players verified in database
   Striker Name: PLAYER FIVE
   Non-Striker Name: PLAYER SIX
   Bowler Name: PLAYER ONE
🧹 [STEP 4] Clearing LED display...
✅ LED display cleared
⏳ [STEP 5] Waiting for data persistence...
🚀 [STEP 6] Navigating to second innings screen...
✅ [COMPLETE] Second innings screen loaded
   Screen will call _initializeMatch() → Fetches all fresh player data
🚀 CricketScorerScreen: Initializing EnvironmentService...
🎬 CricketScorerScreen: Initial LED update
```

---

## LED Display Updates

After screen rebuild:

1. **First Update (3 seconds after load)**
   - Time: HH:MM
   - Temperature: XX°C

2. **Continuous Updates (every 60 seconds)**
   - Time refresh
   - Temperature refresh

3. **Score Updates**
   - Triggered on every run/wicket
   - Fast batch update (critical data)
   - Smooth name scroll (background)

---

## Important Notes

✅ **Screen Rebuild**: Complete new instance with `initState()` call
✅ **Data Fetch**: `_initializeMatch()` fetches fresh data for second innings
✅ **Player Details**: Striker, non-striker, and bowler all properly loaded
✅ **Database Verified**: All players confirmed in database before navigation
✅ **LED Cleared**: Display reset before transition
✅ **Animation Free**: No competing animations during transition
✅ **State Fresh**: All variables reset to initial state
✅ **Target Display**: Shows remaining runs and balls for second innings

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Player names showing "Unknown" | Check TeamMember.getByPlayerId() returns correct data |
| Score shows 0/0 | Score.create() was successful; fresh start is expected |
| LED not updating | Check BleManagerService.isConnected after transition |
| Batsman stats empty | Verify Batsman.getByBatId() returns non-null object |
| Screen stays loading | Check _initializeMatch() isn't throwing exception |

---

**Last Updated**: 2026-02-10
**Version**: 2.0 (Optimized Second Innings Rebuild)
