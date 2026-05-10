# TURF TOWN - Complete Project Guide

## 📱 Project Overview

**TURF TOWN** is a comprehensive Flutter-based cricket scoring and management application. It enables teams to create matches, track live scores with real-time Bluetooth LED display integration, view historical match data, and analyze team performance.

**Key Technologies:**
- **Framework:** Flutter (Dart)
- **Database:** ObjectBox (local NoSQL database)
- **State Management:** Provider
- **Bluetooth:** Flutter Blue Plus
- **Animations:** Lottie
- **Charts:** FL Chart
- **Storage:** SharedPreferences, SQLite

---

## 🏗️ Architecture Overview

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        MyApp (main.dart)                     │
│                                                              │
│ • Initializes ObjectBox Database                            │
│ • Sets up app lifecycle observer                            │
│ • Manages Bluetooth persistence across navigation           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    SplashScreenNew                           │
│              (Intro/Welcome Screen)                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                        Home Page                             │
│    • Navigate to Team Selection                             │
│    • View Match History                                     │
│    • Access Bluetooth Connection                            │
│    • View Settings & Account                                │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
         ▼           ▼           ▼
    ┌────────┐ ┌──────────┐ ┌──────────┐
    │ Teams  │ │ History  │ │Bluetooth │
    │ Page   │ │ Page     │ │ Page     │
    └────┬───┘ └──────────┘ └──────────┘
         │
         ▼
    ┌──────────────────┐
    │ Match Selection  │
    │ (InitialTeamPage)│
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ Toss & Settings  │
    │ (Match Config)   │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────────────────────────┐
    │     Cricket Scorer Screen            │
    │ • Record runs, wickets, extras       │
    │ • Send updates to LED display        │
    │ • Live Bluetooth connection          │
    └────┬─────────────────────────────────┘
         │
         ▼
    ┌──────────────────────────────────────┐
    │     Scoreboard Page                  │
    │ • Real-time match display            │
    │ • Animations (4s, 6s, wickets)      │
    │ • Auto-refresh every 2 seconds       │
    └──────────────────────────────────────┘
```

---

## 🗄️ Database Models

### Core Entities (ObjectBox)

#### 1. **Team**
```dart
@Entity()
class Team {
  @Id() int id;                    // Auto-incremented PK
  @Unique() String teamId;         // UUID (unique identifier)
  String teamName;                 // Team name (2-30 chars)
  int teamCount;                   // Number of players in team
}
```

**Methods:**
- `create(teamName)` - Create new team
- `getAll()` - Get all teams
- `getById(teamId)` - Get specific team
- `updateName(newName)` - Update team name
- `delete()` - Delete team

---

#### 2. **TeamMember (Player)**
```dart
@Entity()
class TeamMember {
  @Id() int id;
  @Unique() String playerId;       // UUID
  String teamId;                   // Foreign key to Team
  String playerName;               // Player name (2-30 chars)
}
```

**Methods:**
- `create(teamId, playerName)` - Add player to team
- `getByTeamId(teamId)` - Get all players in team
- `deleteByPlayerId(playerId)` - Remove player
- `updateName(newName)` - Change player name

---

#### 3. **Match**
```dart
@Entity()
class Match {
  @Id() int id;
  @Unique() String matchId;        // m_01, m_02, etc.
  String teamId1, teamId2;         // Two teams playing
  String tossWonBy;                // Team that won toss
  int batBowlFlag;                 // 0=bat, 1=bowl
  int noballFlag;                  // 0=allowed, 1=not allowed
  int wideFlag;                    // 0=allowed, 1=not allowed
  int overs;                       // Number of overs
  DateTime? matchStartTime;        // When match started
}
```

**Key Methods:**
- `create(teamId1, teamId2, tossWonBy, ...)` - Create match
- `getByMatchId(matchId)` - Fetch match
- `getBattingTeamId()` - Get team batting now
- `getBowlingTeamId()` - Get team bowling now
- `saveToHistory()` - Save completed match to history

---

#### 4. **Innings**
```dart
@Entity()
class Innings {
  @Id() int id;
  @Unique() String inningsId;      // i_01, i_02, etc.
  String matchId;                  // Foreign key
  int inningsNumber;               // 1 or 2
  String battingTeamId;            // Team batting in this innings
  String bowlingTeamId;            // Team bowling in this innings
  int targetRuns;                  // Target for 2nd innings
  bool isCompleted;                // Is innings finished?
}
```

**Methods:**
- `create(matchId, inningsNumber, ...)` - Create innings
- `getFirstInnings(matchId)` - Get 1st innings
- `getSecondInnings(matchId)` - Get 2nd innings
- `complete()` - Mark innings as finished

---

#### 5. **Score** (Batting Statistics)
```dart
@Entity()
class Score {
  @Id() int id;
  @Unique() String inningsId;      // FK to Innings
  int totalRuns;                   // Total runs scored
  int wickets;                     // Wickets lost
  double overs;                    // Overs bowled (e.g., 5.3)
  double crr;                      // Current run rate

  // Extras tracking
  int wides, noBalls, byes, legByes;

  // Current match state
  String strikeBatsmanId;
  String nonStrikeBatsmanId;
  String currentBowlerId;
  int currentBall;                 // Total balls in innings
  List<String> currentOver;        // Balls in current over
}
```

**Methods:**
- `create(inningsId)` - Initialize score
- `getByInningsId(inningsId)` - Fetch score
- `addRuns(runs, isBoundary)` - Record runs
- `addWicket()` - Record dismissal
- `newOver()` - Start new over

---

#### 6. **Batsman**
```dart
@Entity()
class Batsman {
  @Id() int id;
  @Unique() String batsmanId;      // UUID
  String inningsId;                // FK to Innings
  String playerId;                 // Which player
  int runsScored;                  // Total runs
  int ballsFaced;                  // Deliveries faced
  bool isOut;                      // Dismissed?
  String dismissalType;            // caught, bowled, etc.
  String? dismissedBy;             // Bowler ID (if applicable)
}
```

**Methods:**
- `create(inningsId, playerId, ...)` - Add batsman
- `getByInningsId(inningsId)` - Get all batsmen in innings
- `recordRuns(runs, ballType)` - Update runs
- `recordDismissal(type, bowlerId)` - Mark out

---

#### 7. **Bowler**
```dart
@Entity()
class Bowler {
  @Id() int id;
  @Unique() String bowlerId;       // UUID
  String inningsId;                // FK to Innings
  String playerId;                 // Which player
  int ballsBowled;                 // Total deliveries
  int runsGiven;                   // Runs conceded
  int wickets;                     // Dismissals
  double overs;                    // Overs bowled
  int wides, noBalls;              // Extras given
}
```

**Methods:**
- `create(inningsId, playerId)` - Register bowler
- `getByInningsId(inningsId)` - Get all bowlers
- `addRuns(runs)` - Update runs given
- `addWicket()` - Record dismissal

---

#### 8. **MatchHistory**
```dart
@Entity()
class MatchHistory {
  @Id() int id;
  @Unique() String matchId;
  String teamAId, teamBId;
  DateTime matchDate;
  String matchType;                // 'CRICKET', 'FOOTBALL', etc.
  int team1Runs, team1Wickets;
  double team1Overs;
  int team2Runs, team2Wickets;
  double team2Overs;
  String result;                   // "Team A won by X runs"
  bool isCompleted;
  DateTime? matchStartTime;
  DateTime? matchEndTime;
}
```

**Methods:**
- `create(...)` - Save match to history
- `getByMatchId(matchId)` - Fetch historical match
- `getAll()` - Get all completed matches

---

## 📱 Key Pages & Features

### 1. **Home Page** (`home.dart`)
Main navigation hub with tabs:
- **Teams Tab:** Manage teams and players
- **History Tab:** View past match results
- **Bluetooth Tab:** Connect to LED display

---

### 2. **Team Management** (`InitialTeamPage.dart`)
- Create teams (2-30 character names)
- Add players via dialog (max 11 per team)
- Delete teams and players
- Real-time player count from database

**Validation:**
- Player names: 2-30 characters
- Max 11 players per team
- Duplicate detection (case-insensitive)

---

### 3. **Match Setup Flow**

**Step 1: Select Teams**
- Choose Team 1 and Team 2
- Cannot select same team twice

**Step 2: Toss Configuration**
- Select toss winner
- Choose bat/bowl decision (0=bat, 1=bowl)
- Set number of overs

**Step 3: Configure Rules**
- Enable/disable no-balls
- Enable/disable wides

---

### 4. **Cricket Scorer Screen** (`cricket_scorer_screen.dart`)

**Purpose:** Live scoring during match

**Key Features:**
- **Batsman/Bowler Display:** Current striker, non-striker, current bowler
- **Score Buttons:** Record 0-6 runs
- **Extras Panel:** Add wides, no-balls, byes, leg-byes
- **Wicket Management:** Record dismissals
- **Runout Mode:** Special logic for run-outs
- **LED Integration:** Send live updates to Bluetooth display

**Score Recording Flow:**
```
User clicks "1 Run"
    ↓
recordNormalBall(runs=1)
    ↓
Check if boundary (4 or 6)?
    ↓
Update Batsman & Bowler statistics
    ↓
Update Score (totalRuns, crr, overs)
    ↓
Check for over completion
    ↓
Send update via Bluetooth
    ↓
Trigger animations
    ↓
setState() to update UI
```

**Animations Triggered:**
- **4 Runs:** Blue confetti animation
- **6 Runs:** Orange confetti animation
- **Wicket:** Rotating lightning emoji
- **Duck (0 runs out):** Scale + fade emoji
- **Runout:** Red highlight flash on scorecard

---

### 5. **Scoreboard Page** (`scoreboard_page.dart`)

**Purpose:** Display live match statistics

**Features:**
- Real-time score updates (2-second auto-refresh)
- Batsman scorecard with animations
- Bowler statistics
- Match progress visualization
- Target chase display (for 2nd innings)

**Animation Architecture:**
```dart
class _ScoreboardPageState extends State<ScoreboardPage>
    with TickerProviderStateMixin {

  late AnimationController boundaryController;
  late AnimationController wicketController;

  @override
  void initState() {
    boundaryController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _triggerBoundaryAnimation(String batsmanId) {
    boundaryController.forward(from: 0.0);
  }
}
```

---

### 6. **Bluetooth Connection** (`bluetooth_page.dart`)

**Purpose:** Connect to external LED display via Bluetooth

**Features:**
- Scan for available devices
- Connect/disconnect
- Auto-refresh status
- Connection persistence across page navigation

**Connection Lifecycle:**
```
Scan → List Devices → Connect → Discover Services →
Find Characteristics → Initialize BleManagerService →
Ready for data transmission
```

---

## 🔌 Bluetooth Integration (BleManagerService)

### Architecture (Singleton Pattern)

```dart
class BleManagerService {
  static final BleManagerService _instance = BleManagerService._internal();
  factory BleManagerService() => _instance;

  // Single instance throughout entire app
}
```

### Key Features

#### 1. **Connection Persistence**
```dart
// Listens to device connection state changes globally
_connectionSubscription = device.connectionState.listen((state) {
  if (state == BluetoothConnectionState.disconnected) {
    _handleDisconnection();
  }
});

// Connection persists across page navigation
// Only disconnects on explicit user action or app termination
```

#### 2. **Live Score Updates**

**Sending Match Data:**
```dart
Future<bool> sendMatchUpdate() async {
  // Get current match, innings, and score from database
  final match = Match.getByMatchId(currentMatchId);
  final innings = Innings.getSecondInnings(match.matchId);
  final score = Score.getByInningsId(innings.inningsId);

  // Build JSON payload
  final scorecardData = {
    'type': 'SCORE',
    'matchId': match.matchId,
    'bat': battingTeam.teamName,
    'runs': score.totalRuns,
    'wkts': score.wickets,
    'ovs': score.overs,
    'crr': score.crr,
    'tgt': targetRuns,
    'need': runsNeeded,
  };

  // Send via Bluetooth
  await _sendDataInChunks(jsonEncode(scorecardData));
}
```

**Auto-Refresh:**
```dart
void startAutoRefresh({Duration? interval}) {
  _autoUpdateTimer = Timer.periodic(
    interval ?? Duration(seconds: 3),
    (_) => sendMatchUpdate(),
  );
}
```

#### 3. **LED Display Control**

**Raw Command Sending:**
```dart
Future<bool> sendRawCommand(String command) async {
  // For LED-specific commands without JSON encoding
  final bytes = utf8.encode(command);
  await _writeCharacteristic!.write(bytes, withoutResponse: false);
}

// Example: Clear display
await BleManagerService().clearDisplay();

// Example: Set brightness
await BleManagerService().setBrightness(75);
```

#### 4. **Data Chunking**
```dart
Future<void> _sendDataInChunks(String data) async {
  // Split large data into 200-byte chunks
  final dataBytes = utf8.encode(data);
  final totalChunks = (dataBytes.length / MAX_BLE_CHUNK_SIZE).ceil();

  // Send each chunk with header [i/total]
  for (int i = 0; i < totalChunks; i++) {
    final chunk = dataBytes.sublist(start, end);
    final header = utf8.encode('[$i/$totalChunks]');
    await _writeCharacteristic!.write([...header, ...chunk]);
    await Future.delayed(Duration(milliseconds: 50));
  }

  // Send END marker
  await _writeCharacteristic!.write(utf8.encode('[END]'));
}
```

#### 5. **Auto-Reconnect**
```dart
Future<void> autoReconnect() async {
  // Disconnect first
  await deviceToReconnect.disconnect();
  await Future.delayed(Duration(milliseconds: 300));

  // Reconnect
  await deviceToReconnect.connect(
    timeout: Duration(seconds: 15),
    autoConnect: false,
  );

  // Rediscover services & characteristics
  final services = await deviceToReconnect.discoverServices();
  // Re-find write and read characteristics...

  // Re-setup notifications
  await _setupReadNotifications();
}
```

---

## 🎨 Animation System

### 1. **Cricket Animations** (`cricket_animations.dart`)

**Lottie Animations Used:**
- `Duck Out.lottie` - Duck emoji scale + fade
- `CRICKET OUT ANIMATION.lottie` - Rotating lightning
- `Scored 4.lottie` - Boundary confetti (blue)
- `SIX ANIMATION.lottie` - Boundary confetti (orange)

**Animation Triggers:**

```dart
// In cricket_scorer_screen.dart
void recordNormalBall(int runs) {
  // ... record score ...

  if (runs == 4) {
    _triggerBoundaryAnimation('4');
  } else if (runs == 6) {
    _triggerBoundaryAnimation('6');
  }

  if (checkForWicket()) {
    _triggerWicketAnimation();
  }

  if (isDuck) {
    _triggerDuckAnimation(batsmanId);
  }
}
```

### 2. **Animation States**

```dart
// Boundary animation
bool _showBoundaryAnimation = false;
String? _boundaryAnimationType; // '4' or '6'

// Wicket animation
bool _showWicketAnimation = false;

// Duck animation
bool _showDuckAnimation = false;
String? _lastDuckBatsman; // Track which batsman

// Victory animation
bool _showVictoryAnimation = false;

// Runout highlight
bool _showRunoutHighlight = false;
int _runoutHighlightIndex = 0;
```

### 3. **Timing Configuration**

```dart
const Duration animationDuration = Duration(milliseconds: 1000);
const Duration wicketDuration = Duration(milliseconds: 900);
const Duration duckDuration = Duration(milliseconds: 1000);
const Duration runoutDuration = Duration(milliseconds: 800);
```

---

## 🎯 Game Flow & State Management

### Match Initialization

```
1. User creates match with toss & settings
   ↓
2. First Innings starts with first batsman & bowler
   ↓
3. Score object created (totalRuns=0, wickets=0, overs=0)
   ↓
4. Batsman & Bowler objects created for each player
   ↓
5. CricketScorerScreen loads with live UI
```

### Score Recording

```
Button Pressed (1-6 runs)
    ↓
recordNormalBall(runs) {
  1. Update batsman.runsScored += runs
  2. Update bowler.runsGiven += runs
  3. Update score.totalRuns += runs
  4. Update score.currentOver += 'runs'
  5. Increment score.currentBall

  if (score.currentBall % 6 == 0) {
    // Over complete
    score.newOver()
    score.overs++
    score.currentOver = []
  }

  // Calculate CRR
  score.crr = score.totalRuns / score.overs

  // Trigger animations
  if (runs == 4 || runs == 6) {
    _triggerBoundaryAnimation()
  }

  // Send Bluetooth update
  sendMatchUpdate()

  // Save to database
  score.save()
  batsman.save()
  bowler.save()

  setState() // Refresh UI
}
```

### Wicket Recording

```
User clicks "Wicket" button
    ↓
Opens wicket dialog with dismissal types:
- Caught
- Bowled
- LBW (Leg Before Wicket)
- Stumped
- Runout
    ↓
Update batsman.isOut = true
Update batsman.dismissalType = selected type
Update score.wickets++
    ↓
Special handling for RUNOUT:
  - Multiple batsmen involved
  - Highlight affected players
  - Show runout animation
    ↓
Trigger wicket animation
Send Bluetooth update
Save to database
    ↓
Advance to next batsman
```

### Over Completion

```
Ball 6 of over complete
    ↓
score.currentBall % 6 == 0
    ↓
score.overs++ (update from 5.5 to 6.0)
score.currentOver = []
    ↓
Check if innings is complete:
  if (score.wickets >= 10 || score.overs >= maxOvers) {
    markInningsComplete()
  }
    ↓
If not complete, swap strikers:
  temp = strikeBatsman
  strikeBatsman = nonStrikeBatsman
  nonStrikeBatsman = temp
    ↓
Change bowler for new over
    ↓
Reset UI buttons
Send Bluetooth update
```

### Match Completion

```
Second innings ends (wicket or overs)
    ↓
Determine winner:
  if (team2_runs >= team2_target) {
    "Team B won by X wickets"
  } else {
    "Team A won by Y runs"
  }
    ↓
Save match to MatchHistory:
  - Final scores
  - Wickets
  - Overs
  - Result message
  - Match duration
    ↓
Freeze all buttons (isMatchComplete = true)
Show victory animation
Auto-reconnect Bluetooth for next match
    ↓
Navigate back to home or match selection
```

---

## 📊 Key Algorithms

### 1. **Current Run Rate (CRR) Calculation**

```dart
double calculateCRR(int totalRuns, double oversCompleted) {
  if (oversCompleted == 0) return 0.0;
  return totalRuns / oversCompleted;
}

// Example: 45 runs in 8.3 overs = 45 / 8.33 = 5.40
```

### 2. **Runs Needed (Chase)**

```dart
int calculateRunsNeeded(int target, int currentRuns) {
  return target - currentRuns;
}

// Example: Target 150, current 78 = 150 - 78 = 72 needed
```

### 3. **Over Format Conversion**

```dart
// Internal storage: double (e.g., 5.3 means 5 overs, 3 balls)
double calculateOvers(int totalBalls) {
  int overs = totalBalls ~/ 6;       // Integer division
  int balls = totalBalls % 6;        // Remainder
  return overs + (balls / 10);       // e.g., 5.3
}

// Example: 33 balls = 5 overs 3 balls = 5.3
```

### 4. **Wicket Determination**

```dart
bool checkForWicket() {
  return lastBallType == 'WICKET';
}

// Types: CAUGHT, BOWLED, LBW, STUMPED, RUNOUT
```

### 5. **Duck Detection**

```dart
bool isDuck(Batsman batsman) {
  return batsman.runsScored == 0 && batsman.isOut;
}
```

---

## 🗂️ File Structure

```
lib/
├── main.dart                              # App entry, ObjectBox init
├── src/
│   ├── models/
│   │   ├── team.dart                      # Team entity
│   │   ├── team_member.dart               # Player entity
│   │   ├── match.dart                     # Match entity
│   │   ├── innings.dart                   # Innings entity
│   │   ├── score.dart                     # Batting stats entity
│   │   ├── batsman.dart                   # Individual batsman
│   │   ├── bowler.dart                    # Individual bowler
│   │   ├── match_history.dart             # Completed match storage
│   │   ├── objectbox_helper.dart          # Database config
│   │   ├── objectbox.g.dart               # Generated code
│   │   ├── match_storage.dart             # Match queries
│   │   ├── team_storage.dart              # Team queries
│   │   └── player_storage.dart            # Player queries
│   │
│   ├── services/
│   │   ├── bluetooth_service.dart         # BLE communication (singleton)
│   │   ├── environment_service.dart       # Config management
│   │   ├── splash_animations_service.dart # Intro animations
│   │   └── Otp.dart                       # OTP utilities
│   │
│   ├── Pages/Teams/
│   │   ├── InitialTeamPage.dart           # Team selection
│   │   ├── team_members_page.dart         # Player management
│   │   ├── cricket_scorer_screen.dart     # Live scoring
│   │   ├── scoreboard_page.dart           # Display scores
│   │   ├── match_graph_page.dart          # Statistics charts
│   │   ├── team_name_screen.dart          # Team creation
│   │   └── playerselection_page.dart      # Player selection
│   │
│   ├── views/
│   │   ├── Home.dart                      # Main navigation hub
│   │   ├── bluetooth_page.dart            # Bluetooth connection
│   │   ├── history_page.dart              # Match history
│   │   ├── splash_screen_new.dart         # Splash/intro
│   │   ├── Venue.dart                     # Venue selection
│   │   ├── alerts_page.dart               # Notifications
│   │   └── Sliding_page.dart              # Carousel navigation
│   │
│   ├── widgets/
│   │   ├── cricket_animations.dart        # Lottie animations
│   │   ├── morphing_sport_shape.dart      # Shape animations
│   │   ├── shadow_painter.dart            # Custom painters
│   │   ├── Navigation_bar.dart            # Bottom nav
│   │   ├── Circular_button.dart           # Custom buttons
│   │   └── buttons.dart                   # Button utilities
│   │
│   ├── Scorecard/
│   │   └── ScoreCard.dart                 # Scorecard display
│   │
│   ├── CommonParameters/
│   │   ├── AppBackGround1/
│   │   │   ├── Appbg1.dart               # Background theme 1
│   │   │   └── Appbg2.dart               # Background theme 2
│   │   ├── buttons.dart                   # Button styles
│   │   └── Validators.dart                # Input validation
│   │
│   └── utils/
│       ├── animation_constants.dart       # Animation timing
│       └── ...
│
├── assets/
│   └── images/
│       ├── *.png, *.jpg                   # Background images
│       ├── *.svg                          # Icons
│       ├── *.lottie                       # Animations
│       └── *.json                         # Data files
│
└── pubspec.yaml                           # Dependencies
```

---

## 🔑 Key Concepts

### 1. **Singleton Pattern (BleManagerService)**

```dart
// Only one instance throughout app lifetime
BleManagerService service = BleManagerService();
BleManagerService service2 = BleManagerService();
assert(service == service2);  // True - same instance
```

**Benefits:**
- Single Bluetooth connection state
- Persistent across page navigation
- No duplicate connections
- Centralized state management

---

### 2. **Observer Pattern (App Lifecycle)**

```dart
// main.dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app pause, resume, detach, etc.
  }
}
```

**States Handled:**
- `resumed` - App visible and running
- `paused` - App not visible (but running)
- `inactive` - App transitioning (e.g., navigation)
- `detached` - App terminating
- `hidden` - App hidden (Android only)

---

### 3. **Stream Subscription Pattern**

```dart
// Listen to Bluetooth connection state changes
_connectionSubscription = device.connectionState.listen((state) {
  if (state == BluetoothConnectionState.disconnected) {
    _handleDisconnection();
  }
});

// Always unsubscribe in cleanup
@override
void dispose() {
  _connectionSubscription?.cancel();
}
```

---

### 4. **ObjectBox Query Pattern**

```dart
// Read
final query = ObjectBoxHelper.teamBox
    .query(Team_.teamId.equals(teamId))
    .build();
final team = query.findFirst();
query.close();  // Important: free resources

// Create
final team = Team(teamId: uuid, teamName: 'Name');
ObjectBoxHelper.teamBox.put(team);

// Update
team.teamName = 'New Name';
ObjectBoxHelper.teamBox.put(team);  // Put again to update

// Delete
ObjectBoxHelper.teamBox.remove(team.id);
```

---

### 5. **Timer & Animation Pattern**

```dart
// One-time animation
AnimationController controller = AnimationController(
  duration: Duration(milliseconds: 1000),
  vsync: this,
);
controller.forward(from: 0.0);  // Start from beginning

// Repeating auto-refresh
_autoUpdateTimer = Timer.periodic(Duration(seconds: 3), (_) {
  sendMatchUpdate();
});

// Cleanup
@override
void dispose() {
  controller.dispose();
  _autoUpdateTimer?.cancel();
  super.dispose();
}
```

---

## 🧪 Testing Scenarios

### Match Creation & Setup
- [ ] Create two teams with valid names
- [ ] Add 11 players to each team
- [ ] Try to add duplicate player (should fail)
- [ ] Create match with toss settings
- [ ] Verify match ID generated correctly (m_01, m_02)

### Scoring
- [ ] Record 1, 2, 3, 4, 6 runs
- [ ] Record extras (wide, no-ball, bye, leg-bye)
- [ ] Complete an over (6 balls)
- [ ] Advance to next over
- [ ] Record wicket (various types)
- [ ] Verify CRR calculation
- [ ] Check batsman & bowler stats update

### Animations
- [ ] 4 runs → Blue confetti animation
- [ ] 6 runs → Orange confetti animation
- [ ] Wicket → Lightning animation
- [ ] Duck → Duck emoji animation
- [ ] Runout → Highlight flash

### Bluetooth
- [ ] Connect to device
- [ ] Navigate away and return → Connection persists
- [ ] Disconnect device → UI updates within 2 seconds
- [ ] Send score update → Data received
- [ ] Auto-reconnect after match → Silent reconnection

### Match Completion
- [ ] Complete first innings → Show target
- [ ] Complete second innings → Calculate winner
- [ ] Save to history → Verify in history page
- [ ] Victory animation plays
- [ ] Match locked (buttons disabled)

---

## 🐛 Known Issues & Solutions

### Issue: Bluetooth Disconnects on Page Navigation
**Root Cause:** App lifecycle `inactive` state triggers disconnect
**Solution:** Only disconnect on `detached` state (real app termination)
**Code Location:** `main.dart:43-63`

### Issue: LED Display Shows Overlapping Text
**Root Cause:** Commands sent too quickly (150ms intervals)
**Solution:** Increased delays to 250ms minimum between command batches
**Code Location:** `cricket_scorer_screen.dart` - LED rendering methods

### Issue: Cricket Scorer Screen Doesn't Update Live
**Root Cause:** Animations not triggered from business logic
**Solution:** Call `_triggerBoundaryAnimation()` from `recordNormalBall()`
**Code Location:** `cricket_scorer_screen.dart:recordNormalBall()`

### Issue: CRR Calculation Shows Infinity
**Root Cause:** Division by zero when overs = 0
**Solution:** Check `overs > 0` before calculating
```dart
double crr = (overs == 0) ? 0.0 : totalRuns / overs;
```

---

## 📈 Performance Optimization

### Database Queries
- Close queries after use to free resources
- Use indexes on frequently queried fields (teamId, matchId)
- Batch operations when possible

### UI Rendering
- Use `const` constructor when possible
- Implement `shouldRebuild()` in providers
- Use `AnimatedBuilder` instead of `setState()` for animations

### Bluetooth
- Send data in 200-byte chunks
- Add 50ms delay between chunks
- Implement auto-reconnect with 15-second timeout
- Cancel timers when no longer needed

### Asset Management
- Use `.webp` format for images
- Compress Lottie animations
- Lazy-load images not visible on screen

---

## 🔐 Security Considerations

### Data Protection
- ObjectBox stores data locally (no encryption by default)
- Consider adding encryption for sensitive match data
- Use SharedPreferences with caution (human-readable)

### Bluetooth Security
- Verify device pairing before connection
- Validate incoming data before processing
- Implement checksum/hash verification for large transfers

### User Input
- Validate team names (length, special characters)
- Validate player count (max 11)
- Sanitize database queries (ObjectBox handles automatically)

---

## 🚀 Deployment

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### Dependencies to Build
```bash
flutter pub get
flutter pub run build_runner build  # For ObjectBox code generation
```

### Required Permissions (AndroidManifest.xml)
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

---

## 📚 Dependencies Overview

| Package | Purpose |
|---------|---------|
| `objectbox` | Local database |
| `flutter_blue_plus` | Bluetooth connectivity |
| `provider` | State management |
| `lottie` | Complex animations |
| `fl_chart` | Charts & graphs |
| `google_fonts` | Custom fonts |
| `geolocator` | Location services |
| `shared_preferences` | Persistent settings |
| `uuid` | Unique ID generation |
| `intl` | Internationalization |

---

## 📖 Quick Reference

### Create a Team
```dart
final team = Team.create('Team Name');
```

### Create a Match
```dart
final match = Match.create(
  teamId1: 'team1-id',
  teamId2: 'team2-id',
  tossWonBy: 'team1-id',
  batBowlFlag: 0,  // Bat first
  noballFlag: 0,   // No-balls allowed
  wideFlag: 0,     // Wides allowed
  overs: 10,
);
```

### Add Player to Team
```dart
final player = TeamMember.create(
  teamId: team.teamId,
  playerName: 'Player Name',
);
```

### Send Bluetooth Update
```dart
await BleManagerService().sendMatchUpdate();
```

### Start Auto-Refresh
```dart
BleManagerService().startAutoRefresh(
  interval: Duration(seconds: 3),
);
```

### Record Runs
```dart
// In CricketScorerScreen
recordNormalBall(4);  // 4 runs
// Triggers: batsman update, bowler update, score update, animation
```

### Record Wicket
```dart
// In CricketScorerScreen
recordWicket(
  dismissalType: 'BOWLED',
  bowlerId: currentBowler.bowlerId,
);
```

---

## 🎓 Architecture Best Practices Used

1. **Separation of Concerns**
   - Database logic in models
   - UI logic in widgets
   - Business logic in service classes

2. **Single Responsibility**
   - Each class has one clear purpose
   - BleManagerService only handles Bluetooth
   - Match class only handles match data

3. **DRY (Don't Repeat Yourself)**
   - Reusable widgets and components
   - Common button styles in CommonParameters
   - Shared animation logic in cricket_animations.dart

4. **State Management**
   - ObjectBox for persistent state
   - Provider for reactive state
   - Callbacks for UI notifications

5. **Error Handling**
   - Try-catch blocks in critical operations
   - Validation before creating entities
   - Debug logging for troubleshooting

---

## 📞 Support & Debugging

### Enable Debug Logging
```dart
// Already enabled in bluetooth_service.dart
debugPrint('📤 Sending data...');
debugPrint('✅ Success');
debugPrint('❌ Error');
```

### Check Connection Status
```dart
BleManagerService().printDebugInfo();
// Prints: Connected, Device name, Auto-refresh status, etc.
```

### View Database Content
```dart
// In ObjectBox Helper
final teams = ObjectBoxHelper.teamBox.getAll();
print('Teams: ${teams.length}');
```

### Test Bluetooth Locally
```dart
// Simulate data without actual device
Future<void> testDataSend() async {
  final json = '{"type":"SCORE","runs":45,"wkts":3}';
  debugPrint('Would send: $json');
}
```

---

## 🎯 Future Enhancements

1. **Statistics & Analytics**
   - Player performance tracking
   - Head-to-head team comparisons
   - Season records

2. **Online Features**
   - Cloud sync for match data
   - Real-time multiplayer scoring
   - Live leaderboards

3. **Advanced Animations**
   - Stadium crowd reactions
   - Player images & highlights
   - Instant replays

4. **Hardware Integration**
   - Multiple LED displays
   - Wireless scoreboard synchronization
   - Smart speaker announcements

5. **AI Features**
   - Match outcome prediction
   - Player form analysis
   - Optimal team lineup suggestions

---

**Last Updated:** February 28, 2026
**App Version:** 1.0.0
**Status:** Production Ready ✅
