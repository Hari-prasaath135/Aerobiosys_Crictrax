# QUICK REFERENCE - MODEL CHANGES

## Match Model Changes

### BEFORE (Current)
```dart
@Entity()
class Match {
  @Id()
  int id;
  
  @Unique()
  String matchId;
  
  String teamId1;
  String teamId2;
  String tossWonBy;
  int batBowlFlag;
  int noballFlag;
  int wideFlag;
  int overs;
  
  @Property(type: PropertyType.date)
  DateTime? matchStartTime;
}
```

### AFTER (Required Changes)
```dart
@Entity()
class Match {
  @Id()
  int id;
  
  @Unique()
  String matchId;
  
  String teamId1;
  String teamId2;
  String tossWonBy;
  int batBowlFlag;
  int noballFlag;
  int wideFlag;
  int overs;
  
  @Property(type: PropertyType.date)
  DateTime? matchStartTime;
  
  // ✅ ADD THESE THREE FIELDS:
  String tournamentId;           // NEW - Link to tournament
  String createdBy;              // NEW - User UID
  @Property(type: PropertyType.date)
  DateTime? createdAt;           // NEW - Creation timestamp
}
```

---

## Team Model Changes

### BEFORE (Current)
```dart
@Entity()
class Team {
  @Id()
  int id;
  
  @Unique()
  String teamId;
  
  String teamName;
  int teamCount;
}
```

### AFTER (Optional Changes)
```dart
@Entity()
class Team {
  @Id()
  int id;
  
  @Unique()
  String teamId;
  
  String teamName;
  int teamCount;
  
  // ✅ ADD THIS FIELD (Optional):
  String? tournamentId;  // NEW - Optional link to tournament
}
```

---

## Innings Model Changes

### BEFORE (Current)
```dart
@Entity()
class Innings {
  @Id()
  int id;
  
  @Unique()
  String inningsId;
  
  String matchId;
  String battingTeamId;
  String bowlingTeamId;
  int inningsNumber;
  int targetRuns;
  bool isCompleted;
}
```

### AFTER (Optional Changes for Cloud Sync)
```dart
@Entity()
class Innings {
  @Id()
  int id;
  
  @Unique()
  String inningsId;
  
  String matchId;
  String battingTeamId;
  String bowlingTeamId;
  int inningsNumber;
  int targetRuns;
  bool isCompleted;
  
  // ✅ ADD THESE FIELDS (Optional):
  String? tournamentId;  // NEW - Track tournament
  String? createdBy;     // NEW - Track creator
}
```

---

## Constructor Updates - Match.create()

### BEFORE
```dart
static Match create({
  required String teamId1,
  required String teamId2,
  required String tossWonBy,
  required int batBowlFlag,
  required int noballFlag,
  required int wideFlag,
  required int overs,
}) {
  // validation...
  
  final matchId = _generateNextMatchId();
  return Match(
    matchId: matchId,
    teamId1: teamId1.trim(),
    teamId2: teamId2.trim(),
    tossWonBy: tossWonBy.trim(),
    batBowlFlag: batBowlFlag,
    noballFlag: noballFlag,
    wideFlag: wideFlag,
    overs: overs,
    matchStartTime: DateTime.now(),
  );
}
```

### AFTER
```dart
static Match create({
  required String teamId1,
  required String teamId2,
  required String tossWonBy,
  required int batBowlFlag,
  required int noballFlag,
  required int wideFlag,
  required int overs,
  required String tournamentId,    // ✅ ADD
  required String createdBy,       // ✅ ADD
}) {
  // Existing validation...
  
  // ✅ ADD VALIDATION:
  if (tournamentId.trim().isEmpty) {
    throw Exception('Tournament ID cannot be empty');
  }
  
  if (createdBy.trim().isEmpty) {
    throw Exception('Creator ID cannot be empty');
  }
  
  final matchId = _generateNextMatchId();
  return Match(
    matchId: matchId,
    teamId1: teamId1.trim(),
    teamId2: teamId2.trim(),
    tossWonBy: tossWonBy.trim(),
    batBowlFlag: batBowlFlag,
    noballFlag: noballFlag,
    wideFlag: wideFlag,
    overs: overs,
    matchStartTime: DateTime.now(),
    tournamentId: tournamentId.trim(),    // ✅ ADD
    createdBy: createdBy.trim(),          // ✅ ADD
    createdAt: DateTime.now(),            // ✅ ADD
  );
}
```

---

## Constructor Updates - Team.create()

### BEFORE
```dart
static Team create(String teamName) {
  final trimmedName = teamName.trim();
  
  // validation...
  
  final team = Team(
    teamId: _uuid.v4(),
    teamName: trimmedName,
    teamCount: 0,
  );
  ObjectBoxHelper.teamBox.put(team);
  return team;
}
```

### AFTER
```dart
static Team create(
  String teamName,
  {String? tournamentId}  // ✅ ADD
) {
  final trimmedName = teamName.trim();
  
  // validation...
  
  final team = Team(
    teamId: _uuid.v4(),
    teamName: trimmedName,
    teamCount: 0,
    tournamentId: tournamentId,  // ✅ ADD
  );
  ObjectBoxHelper.teamBox.put(team);
  return team;
}
```

---

## New Query Methods - Team Model

### ADD THESE METHODS:
```dart
/// Get teams by tournament ID
static List<Team> getByTournamentId(String tournamentId) {
  final query = ObjectBoxHelper.teamBox
      .query(Team_.tournamentId.equals(tournamentId))
      .build();
  final teams = query.find();
  query.close();
  return teams;
}

/// Get teams for match creation (both teams from same tournament)
static List<Team> getTeamsForMatch(String tournamentId) {
  return getByTournamentId(tournamentId);
}

/// Validate both teams belong to tournament
static bool validateTeamsForTournament({
  required String teamId1,
  required String teamId2,
  required String tournamentId,
}) {
  final team1 = getById(teamId1);
  final team2 = getById(teamId2);
  
  return team1?.tournamentId == tournamentId && 
         team2?.tournamentId == tournamentId;
}
```

---

## Firestore Collection Hierarchy

### BEFORE (Flat Structure)
```
/users/{uid}
/tournaments/{tournamentId}
```

### AFTER (Hierarchical Structure)
```
/users/{uid}
  - uid
  - displayName
  - email
  - phone
  
/tournaments/{tournamentId}
  - name, city, ground
  - organizerName
  - createdBy (user uid)
  - createdAt
  
  /teams/{teamId}
    - teamName
    - teamCount
    - tournamentId
    
    /members/{playerId}
      - playerName
      - role (batsman/bowler/all-rounder)
  
  /matches/{matchId}
    - teamId1, teamId2
    - tossWonBy
    - overs, batBowlFlag, etc.
    - tournamentId (redundant reference)
    - createdBy (user uid)
    - createdAt
    - matchStartTime
    - completed, winner
    
    /innings/{inningsId}
      - matchId, inningsNumber
      - battingTeamId, bowlingTeamId
      - targetRuns
      - isCompleted
      
      /scores/{scoreId}
        - playerId
        - runs, wickets, overs
        - boundaries, sixes
```

---

## Validation Rules to Add

### Match Creation Validation
```dart
// Check 1: Tournament exists and user has access
final tournament = await Tournament.get(tournamentId);
if (tournament == null) {
  throw Exception('Tournament not found');
}

// Check 2: Teams exist and belong to tournament
final team1 = Team.getById(teamId1);
final team2 = Team.getById(teamId2);

if (team1 == null || team2 == null) {
  throw Exception('One or both teams not found');
}

if (team1.tournamentId != tournamentId || 
    team2.tournamentId != tournamentId) {
  throw Exception('Teams must belong to the same tournament');
}

// Check 3: User is authenticated
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) {
  throw Exception('User must be authenticated');
}

// Check 4: Create match with all required fields
final match = Match.create(
  teamId1: teamId1,
  teamId2: teamId2,
  tossWonBy: tossWonBy,
  batBowlFlag: batBowlFlag,
  noballFlag: noballFlag,
  wideFlag: wideFlag,
  overs: overs,
  tournamentId: tournamentId,  ✅
  createdBy: uid,               ✅
);
```

---

## UI Updates Needed

### Match Creation Screen - BEFORE
```
┌─ Create Match ──────────┐
│ Team 1: [All Teams ▼]   │
│ Team 2: [All Teams ▼]   │
│ Toss Won: [Team ▼]      │
│ Overs: [____]           │
│         [Create]        │
└─────────────────────────┘
```

### Match Creation Screen - AFTER
```
┌─ Create Match ──────────────────┐
│ Tournament: [Selected ▼] (RO)   │  ← NEW: Read-only
│                                 │
│ Team 1: [Tournament Teams ▼]    │  ← CHANGED: Filtered
│ Team 2: [Tournament Teams ▼]    │  ← CHANGED: Filtered
│ Toss Won: [Team ▼]              │
│ Overs: [____]                   │
│         [Create]                │
└─────────────────────────────────┘

Auto-filled on Create:
  ✅ tournamentId = selected tournament
  ✅ createdBy = current user UID
  ✅ createdAt = DateTime.now()
```

---

## Migration Path for Existing Data

### Step 1: Backup
- Export current ObjectBox data
- Export current Firestore tournaments
- Create safety backup

### Step 2: Update Models
- Add new fields to Match, Team, Innings models
- Regenerate ObjectBox: `flutter pub run build_runner build`

### Step 3: Migrate Data
```dart
// For existing matches without tournamentId
// Option A: Create "Legacy" tournament
// Option B: Ask user to select tournament
// Option C: Set to empty string (with validation)

for (final match in allExistingMatches) {
  if (match.tournamentId.isEmpty) {
    match.tournamentId = 'legacy_tournament_id';
    match.createdBy = 'system_user_id';
    match.createdAt = DateTime.now();
    ObjectBoxHelper.matchBox.put(match);
  }
}
```

### Step 4: Validate & Test
- Verify all matches have tournamentId
- Verify all matches have createdBy
- Test match creation workflow
- Test Firebase sync

---

## Summary of Work

| File | Changes | Priority |
|------|---------|----------|
| match.dart | Add tournamentId, createdBy, createdAt | ✅ CRITICAL |
| team.dart | Add tournamentId (optional), query methods | 🟡 MEDIUM |
| innings.dart | Add tournamentId, createdBy (optional) | 🟡 MEDIUM |
| Match service | Update validation & creation | ✅ CRITICAL |
| Team service | Add filtering methods | 🟡 MEDIUM |
| UI screens | Update match creation flow | ✅ CRITICAL |
| Firestore rules | Add access control checks | 🟡 MEDIUM |

