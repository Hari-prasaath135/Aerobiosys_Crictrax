# TURF TOWN - AUTHENTICATION & TOURNAMENT INTEGRATION GUIDE

## EXECUTIVE SUMMARY

This guide explains how to fully connect:
- ✅ **Authentication** (Firebase Auth) → 
- ✅ **Tournament Management** (Firestore) → 
- ✅ **Match Creation** (ObjectBox + Firestore) → 
- ✅ **Teams & Team Members** (ObjectBox)

---

## CURRENT ARCHITECTURE ISSUES

### Issue 1: Match Model Has NO Tournament Reference
```dart
// CURRENT (Match.dart)
class Match {
  String matchId;
  String teamId1;
  String teamId2;
  String tossWonBy;
  // ❌ MISSING: tournamentId
  // ❌ MISSING: createdBy (user UID)
  // ❌ MISSING: createdAt timestamp
}
```

**Impact**: 
- Cannot link matches to tournaments
- Cannot track which user created a match
- Cannot implement tournament-level access control
- Cannot organize matches by tournament

---

### Issue 2: Team Model Has NO Tournament Reference
```dart
// CURRENT (Team.dart)
class Team {
  String teamId;
  String teamName;
  int teamCount;
  // ❌ MISSING: tournamentId (optional)
}
```

**Impact**:
- Cannot associate teams with tournaments
- Cannot validate team selection within tournament
- Cannot prevent creating matches between teams from different tournaments

---

### Issue 3: Disconnected Storage Systems
```
FIREBASE (Cloud)              ObjectBox (Local)
/users/{uid}          ❌      No sync
/tournaments/{tId}    ❌      No sync
```

**Impact**:
- No cloud backup for match data
- Cannot share tournament/match data between devices
- No real-time multi-user collaboration

---

## COMPLETE INTEGRATION FLOW

### Phase 1: User Authentication (EXISTING ✅)
```
User Login
  ↓
FirebaseAuth.signInWithGoogle() or signInWithOTP()
  ↓
Create /users/{uid} in Firestore
  ↓
AuthService.currentUser returns User object
```

### Phase 2: Create Tournament (EXISTING ✅)
```
User creates tournament
  ↓
Tournament.save()
  ↓
Firestore: /tournaments/{tournamentId}
  - tournamentId
  - name, city, ground
  - organizerName, organizerPhone
  - startDate, endDate
  - categories, tags
  - createdBy: AUTH_USER_UID  ← User UID
  - createdAt
```

### Phase 3: Create Teams for Tournament (NEEDS MODIFICATION)
```
User opens tournament
  ↓
User creates team
  ↓
Team saved locally (ObjectBox) WITH tournamentId
  ↓
Firebase: /tournaments/{tournamentId}/teams/{teamId}
  - teamId
  - teamName
  - teamCount
  - tournamentId  ← Link to tournament
  - createdAt
  
User adds team members
  ↓
TeamMember saved locally (ObjectBox)
  ↓
Firebase: /tournaments/{tournamentId}/teams/{teamId}/members/{playerId}
  - playerId
  - teamName
  - teamId  ← Link to team
```

### Phase 4: Create Match for Tournament (NEEDS MODIFICATION)
```
User selects tournament
  ↓
User creates match
  ↓
VALIDATE:
  ✓ tournamentId provided
  ✓ teamId1 belongs to tournament
  ✓ teamId2 belongs to tournament
  ✓ teamId1 ≠ teamId2
  ↓
Match saved locally (ObjectBox) WITH:
  - matchId
  - teamId1, teamId2
  - tournamentId  ← NEW
  - createdBy: AUTH_USER_UID  ← NEW
  - createdAt  ← NEW
  - Other fields (tossWonBy, overs, etc.)
  ↓
Firebase: /tournaments/{tournamentId}/matches/{matchId}
  - All match fields (local + new fields)
  ↓
Create Innings:
  /tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}
  - inningsId
  - matchId
  - tournamentId  ← Track tournament
  - battingTeamId, bowlingTeamId
```

### Phase 5: Score Match (EXISTING ✅)
```
Match scoring (local ObjectBox):
  ├─ Real-time local updates
  ├─ BLE sync to LED display
  └─ User pauses/resumes

Score saved:
  ├─ ObjectBox (immediate)
  └─ Firestore (periodic/on-demand)
      /tournaments/{tournamentId}/matches/{matchId}/current_score
```

### Phase 6: Complete Match (NEEDS MODIFICATION)
```
Match ends
  ↓
Calculate final scores
  ↓
Save to local ObjectBox
  ↓
Firebase: /tournaments/{tournamentId}/matches/{matchId}
  - Mark as completed
  - Final scores
  - Winner
  
Archive:
  /tournaments/{tournamentId}/match_history/{matchId}
```

---

## DATABASE CHANGES REQUIRED

### 1. Match Model Changes
```dart
// FILE: lib/src/models/match.dart

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
  
  // ==================== NEW FIELDS ====================
  @Property(type: PropertyType.date)
  DateTime matchStartTime;
  
  String tournamentId;           // ✅ NEW: Link to tournament
  String createdBy;              // ✅ NEW: User UID
  @Property(type: PropertyType.date)
  DateTime? createdAt;           // ✅ NEW: Creation timestamp
  // ===================================================
  
  Match({
    this.id = 0,
    required this.matchId,
    required this.teamId1,
    required this.teamId2,
    required this.tossWonBy,
    required this.batBowlFlag,
    required this.noballFlag,
    required this.wideFlag,
    required this.overs,
    required this.tournamentId,  // ✅ NEW: Required
    required this.createdBy,     // ✅ NEW: Required
    this.matchStartTime,
    this.createdAt,
  });
  
  static Match create({
    required String teamId1,
    required String teamId2,
    required String tossWonBy,
    required int batBowlFlag,
    required int noballFlag,
    required int wideFlag,
    required int overs,
    required String tournamentId,    // ✅ NEW: Must provide
    required String createdBy,       // ✅ NEW: Must provide (from Auth)
  }) {
    // Existing validation...
    
    // ✅ NEW: Validate tournament ID not empty
    if (tournamentId.trim().isEmpty) {
      throw Exception('Tournament ID cannot be empty');
    }
    
    // ✅ NEW: Validate creator ID not empty
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
      tournamentId: tournamentId.trim(),      // ✅ NEW
      createdBy: createdBy.trim(),             // ✅ NEW
      matchStartTime: DateTime.now(),
      createdAt: DateTime.now(),               // ✅ NEW
    );
  }
}
```

### 2. Team Model Changes (Optional)
```dart
// FILE: lib/src/models/team.dart

@Entity()
class Team {
  @Id()
  int id;
  
  @Unique()
  String teamId;
  
  String teamName;
  int teamCount;
  
  // ==================== NEW FIELD ====================
  String? tournamentId;  // ✅ NEW: Optional link to tournament
  // =================================================
  
  Team({
    this.id = 0,
    required this.teamId,
    required this.teamName,
    this.teamCount = 0,
    this.tournamentId,  // ✅ NEW: Optional
  });
  
  static Team create({
    required String teamName,
    String? tournamentId,  // ✅ NEW: Optional parameter
  }) {
    final trimmedName = teamName.trim();
    
    // Existing validation...
    
    final team = Team(
      teamId: _uuid.v4(),
      teamName: trimmedName,
      teamCount: 0,
      tournamentId: tournamentId,  // ✅ NEW: Set if provided
    );
    ObjectBoxHelper.teamBox.put(team);
    return team;
  }
  
  // ✅ NEW: Get teams by tournament
  static List<Team> getByTournamentId(String tournamentId) {
    final query = ObjectBoxHelper.teamBox
        .query(Team_.tournamentId.equals(tournamentId))
        .build();
    final teams = query.find();
    query.close();
    return teams;
  }
}
```

### 3. Innings Model Changes (For Cloud Sync)
```dart
// FILE: lib/src/models/innings.dart

@Entity()
class Innings {
  // ... existing fields ...
  
  // ==================== NEW FIELDS ====================
  String? tournamentId;  // ✅ NEW: Track which tournament
  String? createdBy;     // ✅ NEW: Track who created
  // =================================================
  
  // Constructor update...
  // createFirstInnings() update...
  // createSecondInnings() update...
}
```

---

## FIRESTORE COLLECTION STRUCTURE

### Collection Hierarchy
```
/users/{uid}
  - Standard user info

/tournaments/{tournamentId}
  - Basic tournament details
  - createdBy: uid
  
/tournaments/{tournamentId}/teams/{teamId}
  - Team info linked to tournament
  
/tournaments/{tournamentId}/teams/{teamId}/members/{playerId}
  - Team members (players)
  
/tournaments/{tournamentId}/matches/{matchId}
  - Match details
  - tournamentId (for reference)
  - createdBy: uid
  
/tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}
  - Innings data
  
/tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}/scores/{scoreId}
  - Individual batting/bowling scores
```

---

## ACCESS CONTROL LOGIC

### Tournament Level
```dart
// Only tournament creator can:
bool canEditTournament(Tournament t, String uid) {
  return t.createdBy == uid;
}

bool canViewTournament(Tournament t, String uid) {
  return true;  // All authenticated users can view
}
```

### Match Level
```dart
// Only match creator (or tournament creator) can edit:
bool canEditMatch(Match m, Tournament tournament, String uid) {
  return m.createdBy == uid || tournament.createdBy == uid;
}

// Tournament creator can view all matches:
bool canViewMatch(Match m, Tournament tournament, String uid) {
  return m.tournamentId == tournament.tournamentId;
}
```

---

## UI WORKFLOW CHANGES

### Before: Create Match (Current)
```
Create Match Screen
  ├─ Team 1 dropdown (all teams)
  ├─ Team 2 dropdown (all teams)
  ├─ Toss selection
  └─ Create button
```

### After: Create Match (Required)
```
1. Select Tournament (required)
   └─ Dropdown: All tournaments for current user

2. Create Match Screen
   ├─ Tournament: [Selected] (read-only)
   ├─ Team 1 dropdown (filtered by tournament)
   ├─ Team 2 dropdown (filtered by tournament)
   ├─ Validate: Teams belong to tournament
   ├─ Toss selection
   ├─ Overs
   └─ Create button

3. Auto-populated:
   ├─ tournamentId: from selection
   ├─ createdBy: FirebaseAuth.instance.currentUser!.uid
   ├─ createdAt: DateTime.now()
   └─ matchStartTime: DateTime.now()
```

---

## VALIDATION RULES

### Match Creation Validation
1. ✅ Tournament ID must be valid
2. ✅ Team 1 must exist and belong to tournament
3. ✅ Team 2 must exist and belong to tournament
4. ✅ Team 1 ≠ Team 2
5. ✅ User must be authenticated (non-anonymous)
6. ✅ Current user is logged in

### Team Creation Validation
1. ✅ Team name not empty and valid length
2. ✅ If tournamentId provided: tournament must exist
3. ✅ No duplicate team names (optional: per tournament)

---

## IMPLEMENTATION CHECKLIST

### Phase 1: Database Model Updates
- [ ] Update Match model with tournamentId, createdBy, createdAt
- [ ] Update Team model with optional tournamentId
- [ ] Update Innings model with tournamentId, createdBy
- [ ] Regenerate ObjectBox with `flutter pub run build_runner build`

### Phase 2: Create/Update Services
- [ ] Create TournamentService for cloud operations
- [ ] Create MatchService with tournament validation
- [ ] Create TeamService with tournament filtering
- [ ] Add Firestore sync methods

### Phase 3: UI Updates
- [ ] Add Tournament Selection screen before match creation
- [ ] Update CreateMatchPage to require tournament
- [ ] Filter teams by selected tournament
- [ ] Update match history to show tournament context

### Phase 4: Validation & Error Handling
- [ ] Add validation in Match.create()
- [ ] Add validation in Team.create()
- [ ] Handle Firebase save errors
- [ ] Implement retry logic

### Phase 5: Testing & QA
- [ ] Test match creation with tournament
- [ ] Test team filtering by tournament
- [ ] Test Firebase sync
- [ ] Test access control (who can edit)

---

## CODE EXAMPLES

### Create Match with Tournament
```dart
// BEFORE (Wrong)
final match = Match.create(
  teamId1: 'team1',
  teamId2: 'team2',
  // ... no tournament reference
);

// AFTER (Correct)
final match = Match.create(
  teamId1: 'team1',
  teamId2: 'team2',
  tournamentId: selectedTournament.tournamentId,  // ✅ ADD THIS
  createdBy: FirebaseAuth.instance.currentUser!.uid,  // ✅ ADD THIS
  // ... other fields
);
```

### Create Team for Tournament
```dart
// Optional tournament association
final team = Team.create(
  teamName: 'Team A',
  tournamentId: selectedTournament.tournamentId,  // ✅ ADD THIS
);
```

### Filter Teams by Tournament
```dart
// Get only teams from selected tournament
final tournamentTeams = Team.getByTournamentId(
  selectedTournament.tournamentId
);

// Use only these teams for match creation
// Validate that both teamId1 and teamId2 are in tournamentTeams
```

---

## MIGRATION STRATEGY (For Existing Data)

### Step 1: Backup Existing Data
```
- Export ObjectBox data
- Export Firestore tournaments
- Create backup copies
```

### Step 2: Add New Fields to ObjectBox
```
- Update Match model
- Update Team model
- Regenerate ObjectBox schema
- Run migration (provide default values for existing records)
```

### Step 3: Populate Default Values
```dart
// For existing matches without tournamentId
// Provide a "Legacy" or "Default" tournament

// For existing matches without createdBy
// Use a system uid or ask user to re-create

// For existing matches without createdAt
// Use match creation logic or current timestamp
```

### Step 4: Validate & Test
```
- Verify all matches have tournamentId
- Verify all matches have createdBy
- Test match creation with new schema
```

---

## SUMMARY OF CHANGES

| Entity | Current | New | Why |
|--------|---------|-----|-----|
| Match | No tournament link | ✅ +tournamentId | Organize matches by tournament |
| Match | No user tracking | ✅ +createdBy | Track creator & access control |
| Match | No timestamp | ✅ +createdAt | Audit trail & sorting |
| Team | Standalone | ✅ +tournamentId (opt) | Team-tournament association |
| Innings | Local only | ✅ +tournamentId | Cloud sync & tracking |
| Firestore | Top-level tournaments | ✅ Nested structure | Hierarchical organization |
| UI | Direct match creation | ✅ Tournament-first flow | Context-driven creation |

---

## NEXT STEPS

1. **Review this document** with team
2. **Implement Phase 1** (Database models)
3. **Test locally** with ObjectBox changes
4. **Implement Phase 2** (Services)
5. **Update UI** (Phase 3)
6. **Full integration testing**
7. **Deploy with data migration**

