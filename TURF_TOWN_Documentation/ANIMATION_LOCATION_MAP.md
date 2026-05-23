# 📍 Animation Effects - Location Map

## 📄 File Location
**All animations are in ONE file**:
```
lib/src/Pages/Teams/scoreboard_page.dart
```

## 🗺️ Page Navigation Path in App
```
InitialTeamPage.dart (Team Selection)
    ↓ (Tap "Start Match")
CricketScorerScreen.dart (Record Scoring)
    ↓ (Shows Live Scoreboard)
ScoreboardPage.dart ← **ALL ANIMATIONS HERE**
```

---

## 🎬 Animation Effects Location Details

### 1. **4s & 6s Button Highlighting**
**Page**: ScoreboardPage.dart
**Line Range**: 721-754

**Code Location**:
```dart
Widget _buildFoursSixesCell(String count, String type, bool isHighlighted) {
  // Lines 721-754
  // Blue highlighting for 4s
  // Orange highlighting for 6s
}
```

**Where It Appears**:
- In the scorecard table
- Under the "Batsman" section
- In the columns labeled "4s" and "6s"
- Visible when innings is expanded

**Visual Location on Screen**:
```
Batsman Section
├─ Player Name | R | B | [4s] [6s] SR
│                          ↑    ↑
│                    Blue   Orange
│                    boxes  boxes
└─ Numbers like [2] [1] are highlighted
```

---

### 2. **Boundary Confetti Animation (4s & 6s)**
**Page**: ScoreboardPage.dart
**Line Range**: 815-835 (Generation) + 357-363 (Display)

**Generation Code**:
```dart
void _generateConfetti() {
  // Lines 815-835
  // Creates 20 confetti particles
  // Assigns random colors (Red, Yellow, Green, Blue)
  // Sets velocity and rotation properties
}
```

**Display Code**:
```dart
if (_showBoundaryConfetti)
  IgnorePointer(
    child: CustomPaint(
      painter: ConfettiPainter(_confettiPieces),
      size: Size.infinite,
    ),
  ),
  // Lines 357-363
  // Renders confetti on full screen
```

**Trigger Code**:
```dart
void recordNormalBall(...) {
  // Lines 157-160
  if (runs == 4 || runs == 6) {
    _triggerBoundaryAnimation(batsmanId);
  }
}
```

**Visual Location on Screen**:
```
┌─────────────────────────────────┐
│  🎉 🎉 🎉 Confetti particles    │
│ 🎉        falling on screen     │
│ 🎉   🎉   with gravity & rotation
│  🎉    🎉   (Full screen overlay) │
└─────────────────────────────────┘
```

**When Visible**: When 4 or 6 runs are recorded (1000ms duration)

---

### 3. **Wicket Lightning Animation**
**Page**: ScoreboardPage.dart
**Line Range**: 364-394 (Display) + 801-803 (Trigger)

**Display Code**:
```dart
if (_showWicketAnimation)
  AnimatedBuilder(
    animation: _wicketAnimationController,
    builder: (context, child) {
      return IgnorePointer(
        child: Center(
          child: Transform.rotate(
            angle: _wicketRotation.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.8),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Text(
                  '⚡',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ),
          ),
        ),
      );
    },
  ),
  // Lines 364-394
```

**Trigger Code**:
```dart
void recordNormalBall(...) {
  // Lines 151-156
  if (isWicket) {
    _triggerWicketAnimation();
  }
}
```

**Visual Location on Screen**:
```
         ┌─────────┐
         │    ⚡   │
         │  ┌───┐  │ ← Red circular border
         │  │ ⚡ │  │   (150x150 pixels)
         │  └───┘  │   (Center of screen)
         └─────────┘   (Rotates 0°-360°)
```

**When Visible**: When any wicket is recorded (900ms duration)

---

### 4. **Duck Animation (0-run Dismissal)**
**Page**: ScoreboardPage.dart
**Line Range**: 756-788 (Widget) + 688-699 (Integration)

**Widget Code**:
```dart
Widget _buildDuckAnimationWidget(String batsmanId) {
  // Lines 756-788
  // Shows "Duck" text in red
  // Shows 🦆 emoji with scale + fade animation
  return Stack(
    alignment: Alignment.center,
    children: [
      Text('Duck', style: TextStyle(color: Colors.red, ...)),
      if (isDuckBatsman && _showDuckAnimation)
        AnimatedBuilder(
          animation: _duckAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _duckScale.value,
              child: Opacity(
                opacity: _duckOpacity.value,
                child: const Text('🦆', style: TextStyle(fontSize: 16)),
              ),
            );
          },
        ),
    ],
  );
}
```

**Integration Code** (in _buildBatsmanRow):
```dart
if (batsman.isOut && batsman.runs == 0)
  _buildDuckAnimationWidget(batsman.playerId)
else
  Text(_getOutText(batsman), ...)
  // Lines 688-699
```

**Trigger Code**:
```dart
void recordNormalBall(...) {
  // Lines 154-156
  if (isWicket && batsman.runs == 0) {
    _triggerDuckAnimation(batsmanId);
  }
}
```

**Visual Location on Screen**:
```
In the "Out Batsmen" section:

Out Batsmen:
├─ Player Name      Duck 🦆 ← Red "Duck" text
│                   (emoji scales & fades)
└─ Other dismissals
```

**When Visible**: When batsman gets out with 0 runs (1000ms duration)

---

### 5. **Runout Highlight (Red Border Flash)**
**Page**: ScoreboardPage.dart
**Line Range**: 638-718 (Display in Row) + 176-196 (Detection)

**Display Code** (in _buildBatsmanRow):
```dart
return AnimatedBuilder(
  animation: _runoutHighlightController,
  builder: (context, child) {
    return Container(
      decoration: isHighlighted && _showRunoutHighlight
          ? BoxDecoration(
              border: Border.all(
                color: _runoutBorderColor.value ?? Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Batsman row content (name, runs, 4s, 6s, etc.)
          ],
        ),
      ),
    );
  },
);
// Lines 638-718
```

**Detection Code** (Auto-runs every 2 seconds):
```dart
void _checkForRunouts() {
  // Lines 176-196
  for (final batsman in batsmen) {
    if (batsman.isOut &&
        batsman.dismissalType == 'runout' &&
        _lastRunoutBatsman != batsman.playerId) {
      _triggerRunoutHighlight(batsman.playerId);
      _showRunoutHighlight = true;
    }
  }
}
```

**Visual Location on Screen**:
```
In the Scoreboard batsmen section:

Batsman          R  B  4s 6s SR
Player 1        50 25  2  1  200
Player 2 (runout) ┃━━━━━━━━━━━┃ ← Red border flashes
                  opacity: 0.8 → 0.0
Player 3        35 20  1  2  175
```

**When Visible**: When runout is detected (800ms duration, every 2 seconds)

---

## 📍 Full Page Structure

```
ScoreboardPage
├── StatefulWidget class (Lines 13-24)
│
├── _ScoreboardPageState
│   ├── State Variables
│   │   ├── Animation Controllers (Lines 34-37)
│   │   ├── Animation Values (Lines 40-45)
│   │   └── State Tracking (Lines 48-54)
│   │
│   ├── Lifecycle Methods
│   │   ├── initState() → _initializeAnimations() (Lines 57-108)
│   │   └── dispose() (Lines 111-118)
│   │
│   ├── Auto-Refresh System
│   │   ├── _startAutoRefresh() (Lines 165-174)
│   │   └── _checkForRunouts() (Lines 176-196)
│   │
│   ├── Build Method (Main UI)
│   │   ├── Stack (Lines 217)
│   │   ├── Main Content (Lines 219-354)
│   │   ├── Confetti Overlay (Lines 357-363)
│   │   └── Wicket Overlay (Lines 365-394)
│   │
│   ├── Animation Trigger Methods
│   │   ├── _triggerBoundaryAnimation() (Lines 796-799)
│   │   ├── _triggerWicketAnimation() (Lines 801-803)
│   │   ├── _triggerDuckAnimation() (Lines 805-808)
│   │   └── _triggerRunoutHighlight() (Lines 810-813)
│   │
│   ├── Animation Generation
│   │   └── _generateConfetti() (Lines 815-835)
│   │
│   ├── Widget Builders
│   │   ├── _buildInningsSection() (Lines 400-616)
│   │   ├── _buildBatsmanRow() (Lines 634-718) ← Runout + Duck
│   │   ├── _buildFoursSixesCell() (Lines 721-754) ← 4s/6s Highlighting
│   │   ├── _buildDuckAnimationWidget() (Lines 756-788) ← Duck Animation
│   │   ├── _buildBowlerRow() (Lines 790-822)
│   │   └── Other builders...
│   │
│   ├── Game Logic Methods
│   │   ├── recordWide() (Lines 123-141)
│   │   ├── recordNoBall() (Lines 143-162)
│   │   ├── recordBye() (Lines 164-181)
│   │   └── recordNormalBall() (Lines 183-227) ← Boundary/Wicket triggers
│   │
│   └── Dismissal Logic
│       └── _getOutText() (Lines 977-1035)
│
├── Custom Classes
│   ├── ConfettiPiece (Lines 1037-1052)
│   └── ConfettiPainter (Lines 1054-1089)
│
└── EOF
```

---

## 🎯 Where Each Effect Is Triggered

### Effect 1: 4s & 6s Highlighting
- **Trigger Source**: `recordNormalBall()` method (Lines 157-160)
- **Display Method**: `_buildFoursSixesCell()` (Lines 721-754)
- **In Batsman Row**: Called at line 706-707

### Effect 2: Confetti Animation
- **Trigger Source**: `recordNormalBall()` method (Lines 157-160)
- **Animation Method**: `_triggerBoundaryAnimation()` (Lines 796-799)
- **Generation**: `_generateConfetti()` (Lines 815-835)
- **Display**: Overlay in build() (Lines 357-363)

### Effect 3: Wicket Lightning
- **Trigger Source**: `recordNormalBall()` method (Lines 151-152)
- **Animation Method**: `_triggerWicketAnimation()` (Lines 801-803)
- **Display**: Overlay in build() (Lines 365-394)

### Effect 4: Duck Animation
- **Trigger Source**: `recordNormalBall()` method (Lines 154-155)
- **Animation Method**: `_triggerDuckAnimation()` (Lines 805-808)
- **Display Method**: `_buildDuckAnimationWidget()` (Lines 756-788)
- **In Batsman Row**: Called at lines 688-699

### Effect 5: Runout Highlight
- **Detection Source**: `_checkForRunouts()` (Lines 176-196)
- **Called From**: `_startAutoRefresh()` every 2 seconds (Line 170)
- **Animation Method**: `_triggerRunoutHighlight()` (Lines 810-813)
- **Display**: In `_buildBatsmanRow()` (Lines 638-718)

---

## 🎬 User Journey to See Animations

```
App Start
   ↓
Home Page
   ↓
InitialTeamPage (Select teams, add players)
   ↓ Tap "Start Match"
CricketScorerScreen (Record scores)
   ↓ Shows "Live Scoreboard"
ScoreboardPage ← **YOU ARE HERE**
   ↓
See Animations:
├─ 4s/6s buttons highlighted in scorecard ✨
├─ Confetti falls when 4 or 6 recorded 🎉
├─ Lightning emoji rotates on wickets ⚡
├─ Duck emoji on 0-run dismissals 🦆
└─ Red border flashes on runouts 🔴
```

---

## 📱 Visual Layout on ScoreboardPage

```
┌─────────────────────────────────────────┐
│  ← Back  Team1 vs Team2  ↻ ⏸            │ ← Header
├─────────────────────────────────────────┤
│  ○ Live • Auto-refreshing every 2s     │
├─────────────────────────────────────────┤
│                                         │
│  📊 First Innings (Team1)               │ ← Innings Header
│  ├─ Batsman          R  B  4s 6s SR    │
│  │ Player1          50 25 [2][1] 200  │ ← 4s & 6s Highlighted!
│  │ Player2          35 20  1  2  175  │
│  │ Duck Player     Duck 🦆 (animates)  │ ← Duck Animation!
│  │ Runout Player   ┃━━━━━━━━━━━┃      │ ← Runout Border!
│  │                                     │
│  │ 🎉🎉🎉 (Confetti falls here)        │ ← Boundary Animation!
│  │ 🎉    🎉                            │
│  │                                     │
│  │     ⚡                              │ ← Wicket Animation!
│  │    ⚡⚡                             │
│  └─                                   │
│                                        │
│  📊 Second Innings (Team2)             │
│  └─ ...                                │
│                                        │
│  Last updated: HH:MM:SS                │
└─────────────────────────────────────────┘
```

---

## 🔗 How Animations Connect

```
CricketScorerScreen
    ↓ (Records 4 runs via buttons)
    ↓
ScoreboardPage.recordNormalBall(runs=4)
    ↓
Check: runs == 4 || runs == 6
    ↓ YES
_triggerBoundaryAnimation()
    ↓
_generateConfetti() → creates 20 particles
    ↓
Confetti overlay appears on screen
    ↓
ConfettiPainter.paint() animates particles
    ↓
_buildFoursSixesCell() highlights "4s" cell
    ↓
1000ms later → animation fades
```

---

## ✅ Summary

**All 5 animation effects are in ONE page**:

| Effect | File | Method | Lines |
|--------|------|--------|-------|
| **4s/6s Highlighting** | scoreboard_page.dart | _buildFoursSixesCell() | 721-754 |
| **Confetti Animation** | scoreboard_page.dart | _triggerBoundaryAnimation() + _generateConfetti() | 815-835 + 357-363 |
| **Wicket Lightning** | scoreboard_page.dart | _triggerWicketAnimation() | 801-803 + 365-394 |
| **Duck Emoji** | scoreboard_page.dart | _buildDuckAnimationWidget() | 756-788 |
| **Runout Highlight** | scoreboard_page.dart | _checkForRunouts() + _buildBatsmanRow() | 176-196 + 638-718 |

**Navigation**: `lib/src/Pages/Teams/scoreboard_page.dart`

**To See Animations**: Start a match in the app → Go to Live Scoreboard → Record scores
