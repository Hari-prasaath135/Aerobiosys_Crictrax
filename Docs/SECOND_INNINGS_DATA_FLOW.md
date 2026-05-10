# Second Innings Data Flow - Visual Guide

## Complete Data Journey

```
USER ACTION: Clicks "Start Second Innings" Button
│
├─────────────────────────────────────────────────────────────┐
│ PHASE 1: PLAYER SELECTION                                   │
└─────────────────────────────────────────────────────────────┘
│
├─ _showSelectOpeningBatsmenDialog()
│  ├─ Get batting team players: TeamMember.getByTeamId()
│  ├─ Get bowling team players: TeamMember.getByTeamId()
│  ├─ Get available players (not yet batted in match)
│  └─ Show dropdowns to user
│
└─ User selects:
   ├─ Striker: playerId = "player_005"
   ├─ Non-Striker: playerId = "player_006"
   └─ Bowler: playerId = "player_001"
      │
      └────────────────────────────────────────────────────────┐
        │                                                        │
        │ PHASE 2: DATABASE CREATION                            │
        └────────────────────────────────────────────────────────┘
        │
        ├─ _finalizeSecondInnings() called
        │
        ├─ STEP 1: Create Striker Batsman
        │  │
        │  └─ Batsman.create()
        │     └─ Database INSERT
        │        └─ batsman_table {
        │             batId: "bat_2024_001_2_strike",
        │             inningsId: "innings_2024_001_2",
        │             playerId: "player_005",
        │             teamId: "team_002",
        │             runs: 0,
        │             ballsFaced: 0,
        │             fours: 0,
        │             sixes: 0,
        │             dotBalls: 0,
        │             extras: 0,
        │             isOut: false,
        │             strikeRate: 0.0
        │           }
        │
        ├─ STEP 2: Create Non-Striker Batsman
        │  │
        │  └─ Batsman.create()
        │     └─ Database INSERT
        │        └─ batsman_table {
        │             batId: "bat_2024_001_2_nonstr",
        │             inningsId: "innings_2024_001_2",
        │             playerId: "player_006",
        │             teamId: "team_002",
        │             ... (same fields, all 0)
        │           }
        │
        ├─ STEP 3: Create Bowler
        │  │
        │  └─ Bowler.create()
        │     └─ Database INSERT
        │        └─ bowler_table {
        │             bowlerId: "bowl_2024_001_2_001",
        │             inningsId: "innings_2024_001_2",
        │             playerId: "player_001",
        │             teamId: "team_001",
        │             overs: 0.0,
        │             maidens: 0,
        │             runsConceded: 0,
        │             wickets: 0,
        │             balls: 0,
        │             extras: 0,
        │             economy: 0.0
        │           }
        │
        ├─ STEP 4: Verify All Players in Database
        │  │
        │  ├─ Batsman.getByBatId("bat_2024_001_2_strike") ✓ Found
        │  │  └─ Fetch name: TeamMember.getByPlayerId("player_005")
        │  │     └─ "PLAYER FIVE"
        │  │
        │  ├─ Batsman.getByBatId("bat_2024_001_2_nonstr") ✓ Found
        │  │  └─ Fetch name: TeamMember.getByPlayerId("player_006")
        │  │     └─ "PLAYER SIX"
        │  │
        │  └─ Bowler.getByBowlerId("bowl_2024_001_2_001") ✓ Found
        │     └─ Fetch name: TeamMember.getByPlayerId("player_001")
        │        └─ "PLAYER ONE"
        │
        ├─ STEP 5: Clear LED Display
        │  │
        │  └─ _clearLEDDisplay()
        │     └─ BLE Service: Fill entire display with black
        │
        ├─ STEP 6: Wait for Persistence
        │  │
        │  └─ Future.delayed(500ms)
        │
        └─ STEP 7: Navigate to New Screen
           │
           └────────────────────────────────────────────────────┐
             │                                                    │
             │ PHASE 3: SCREEN REBUILD & FRESH FETCH            │
             └────────────────────────────────────────────────────┘
             │
             ├─ Navigator.pushReplacement()
             │  └─ Creates NEW instance: CricketScorerScreen()
             │
             ├─ createState() → _CricketScorerScreenState()
             │
             ├─ initState() called
             │  ├─ Initialize scrollController
             │  └─ Call _initializeMatch()
             │     │
             │     ├─ FRESH DATABASE FETCH 1: Match
             │     │  │
             │     │  └─ Match.getByMatchId("match_2024_001")
             │     │     └─ Returns Match {
             │     │          matchId: "match_2024_001",
             │     │          teamId1: "team_001",
             │     │          teamId2: "team_002",
             │     │          overs: 20,
             │     │          ...
             │     │        }
             │     │
             │     ├─ FRESH DATABASE FETCH 2: Second Innings
             │     │  │
             │     │  └─ Innings.getByInningsId("innings_2024_001_2")
             │     │     └─ Returns Innings {
             │     │          inningsId: "innings_2024_001_2",
             │     │          matchId: "match_2024_001",
             │     │          battingTeamId: "team_002",  ← NOW BATTING
             │     │          bowlingTeamId: "team_001",  ← NOW BOWLING
             │     │          isSecondInnings: true,
             │     │          targetRuns: 126,
             │     │          hasValidTarget: true,
             │     │          ...
             │     │        }
             │     │
             │     ├─ FRESH DATABASE FETCH 3: Score
             │     │  │
             │     │  └─ Score.getByInningsId("innings_2024_001_2")
             │     │     └─ Returns Score {
             │     │          scoreId: "score_2024_001_2",
             │     │          inningsId: "innings_2024_001_2",
             │     │          totalRuns: 0,
             │     │          wickets: 0,
             │     │          currentBall: 0,
             │     │          overs: 0.0,
             │     │          byes: 0,
             │     │          wides: 0,
             │     │          noBalls: 0,
             │     │          totalExtras: 0,
             │     │          crr: 0.0,
             │     │          strikeBatsmanId: "",
             │     │          nonStrikeBatsmanId: "",
             │     │          currentBowlerId: "",
             │     │          currentOver: [],
             │     │          ...
             │     │        }
             │     │
             │     ├─ FRESH DATABASE FETCH 4: Striker
             │     │  │
             │     │  └─ Batsman.getByBatId("bat_2024_001_2_strike")
             │     │     └─ Returns Batsman {
             │     │          batId: "bat_2024_001_2_strike",
             │     │          playerId: "player_005",
             │     │          runs: 0,
             │     │          ballsFaced: 0,
             │     │          fours: 0,
             │     │          sixes: 0,
             │     │          dotBalls: 0,
             │     │          extras: 0,
             │     │          strikeRate: 0.0,
             │     │          isOut: false,
             │     │          dismissalType: null,
             │     │          ...
             │     │        }
             │     │
             │     ├─ FRESH DATABASE FETCH 5: Non-Striker
             │     │  │
             │     │  └─ Batsman.getByBatId("bat_2024_001_2_nonstr")
             │     │     └─ Returns Batsman { (same structure)
             │     │        }
             │     │
             │     └─ FRESH DATABASE FETCH 6: Bowler
             │        │
             │        └─ Bowler.getByBowlerId("bowl_2024_001_2_001")
             │           └─ Returns Bowler {
             │                bowlerId: "bowl_2024_001_2_001",
             │                playerId: "player_001",
             │                overs: 0.0,
             │                maidens: 0,
             │                runsConceded: 0,
             │                wickets: 0,
             │                balls: 0,
             │                extras: 0,
             │                economy: 0.0,
             │                ...
             │              }
             │
             ├─ setState(() => isInitializing = false)
             │  └─ Triggers rebuild
             │
             └────────────────────────────────────────────────────┐
               │                                                    │
               │ PHASE 4: UI RENDERING                             │
               └────────────────────────────────────────────────────┘
               │
               ├─ build() called
               │
               ├─ Loading check: isInitializing == false ✓
               │
               ├─ Render Score Card
               │  ├─ Team Name: "TEAM 002 (2nd)"
               │  │  (from Team.getById() + innings indicator)
               │  │
               │  ├─ Score: "0/0"
               │  │  (from currentScore!.totalRuns / currentScore!.wickets)
               │  │
               │  ├─ Overs: "0.0"
               │  │  (from currentScore!.overs)
               │  │
               │  ├─ CRR: "0.00"
               │  │  (from currentScore!.crr)
               │  │
               │  └─ Target: "Need 126 runs off 120 balls"
               │     (from currentInnings!.targetRuns and remaining balls)
               │
               ├─ Render Batsmen Stats
               │  ├─ Striker Row
               │  │  ├─ Name: "PLAYER FIVE"
               │  │  │  (from TeamMember.getByPlayerId("player_005"))
               │  │  │
               │  │  ├─ Runs: 0
               │  │  ├─ Balls: 0
               │  │  ├─ 4s: 0
               │  │  ├─ 6s: 0
               │  │  ├─ SR: 0
               │  │  └─ (All from strikeBatsman object)
               │  │
               │  └─ Non-Striker Row
               │     ├─ Name: "PLAYER SIX"
               │     ├─ Runs: 0
               │     ├─ Balls: 0
               │     └─ (etc.)
               │
               ├─ Render Bowler Stats
               │  ├─ Name: "PLAYER ONE"
               │  │  (from TeamMember.getByPlayerId("player_001"))
               │  │
               │  ├─ Overs: "0.0"
               │  ├─ Maidens: 0
               │  ├─ Runs: 0
               │  ├─ Wickets: 0
               │  └─ Economy: "0.0"
               │
               └─ Render Action Buttons
                  ├─ Runs: 0, 1, 2, 3, 4, 5, 6
                  ├─ Wicket (W)
                  ├─ Runout (RO)
                  ├─ Swap
                  ├─ Extras (+)
                  └─ Undo (↶)

FINAL STATE: Screen Ready for Scoring! ✅
```

---

## Data at Each Phase

### Phase 1: After Player Selection
```
LOCAL VARIABLES:
selectedStriker = "player_005"
selectedNonStriker = "player_006"
selectedBowler = "player_001"
```

### Phase 2: After Database Creation
```
DATABASE ROWS CREATED:
batsman_table: 2 new rows (striker + non-striker)
bowler_table: 1 new row (bowler)

LOCAL VARIABLES:
striker.batId = "bat_2024_001_2_strike"
nonStriker.batId = "bat_2024_001_2_nonstr"
bowler.bowlerId = "bowl_2024_001_2_001"
```

### Phase 3: After Fresh Fetch
```
STATE VARIABLES:
currentMatch = Match { ... }
currentInnings = Innings { ... (second innings) }
currentScore = Score { totalRuns: 0, wickets: 0, ... }
strikeBatsman = Batsman { playerId: "player_005", runs: 0, ... }
nonStrikeBatsman = Batsman { playerId: "player_006", runs: 0, ... }
currentBowler = Bowler { playerId: "player_001", overs: 0.0, ... }
isInitializing = false ✓
```

### Phase 4: UI Display
```
DISPLAYED DATA:
Score Card: "0-0 (0.0)"
Striker: "PLAYER FIVE - 0(0)"
Non-Striker: "PLAYER SIX - 0(0)"
Bowler: "PLAYER ONE - 0/0 (0.0)"
Target: "Need 126 runs off 120 balls"
All Interactive: Ready for scoring ✓
```

---

## Data Consistency Checks

✅ **Database Persistence**: INSERT → SELECT confirms writes
✅ **Type Safety**: All objects non-null after fresh fetch
✅ **Player Names**: Resolved from TeamMember table
✅ **Team Info**: Fetched for display labels
✅ **Score Board**: All counters initialized to 0
✅ **UI Readiness**: `isInitializing = false` gates display

---

## Memory Flow

```
BEFORE Navigation:
├─ Old CricketScorerScreen instance (memory)
├─ Old state variables
└─ Old UI widgets

DURING Navigation:
├─ New CricketScorerScreen created
├─ initState() runs
├─ _initializeMatch() fetches fresh data
└─ Old instance ready for garbage collection

AFTER Navigation:
├─ New CricketScorerScreen active (memory)
├─ Fresh state variables
├─ Fresh UI widgets with player data
└─ Old instance garbage collected
```

---

## Timing Breakdown

| Operation | Time | Notes |
|-----------|------|-------|
| Player selection dialog | User input | Interactive |
| Batsman creation (striker) | <10ms | DB insert |
| Batsman creation (non-striker) | <10ms | DB insert |
| Bowler creation | <10ms | DB insert |
| Database verification (3x GET) | <30ms | All 3 queries |
| LED clear | <100ms | BLE service |
| Persistence wait | 500ms | Safety margin |
| Screen rebuild | <100ms | initState, build |
| **Total Time** | **~750ms** | **Fast UX** ✓ |

---

**Last Updated**: 2026-02-10
**Type**: Data Flow Diagram + Timing Analysis
