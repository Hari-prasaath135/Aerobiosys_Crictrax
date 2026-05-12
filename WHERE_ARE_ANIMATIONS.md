# 📍 WHERE ARE THE ANIMATIONS? - Quick Answer

## File Location
```
📁 lib
  📁 src
    📁 Pages
      📁 Teams
        📄 scoreboard_page.dart ← ALL ANIMATIONS HERE!
```

**Full Path**:
```
lib/src/Pages/Teams/scoreboard_page.dart
```

---

## Which Page in Your App?

### User Flow:
```
Home Page
  ↓
Choose Team Selection → InitialTeamPage.dart
  ↓
Select 2 Teams + Add Players
  ↓
Tap "Start Match"
  ↓
CricketScorerScreen.dart (Shows Live Scoreboard button)
  ↓
Tap "Live Scoreboard" or Auto-refresh
  ↓
🎬 ScoreboardPage.dart ← ANIMATIONS DISPLAY HERE!
   ├─ 4s/6s Highlighting ✨
   ├─ Confetti Animation 🎉
   ├─ Wicket Lightning ⚡
   ├─ Duck Animation 🦆
   └─ Runout Highlight 🔴
```

---

## 5 Animation Effects Location

### 1. **4s & 6s Button Highlighting** 🎨
**Page**: ScoreboardPage.dart
**Method**: `_buildFoursSixesCell()` (Lines 721-754)
**Appears In**: Scorecard table under batsman stats
```
Example:
Batsman     R  B  4s  6s  SR
Player1    50 25 [2] [1] 200
                   ↑   ↑
              Blue  Orange
```

---

### 2. **Boundary Confetti Animation** 🎉
**Page**: ScoreboardPage.dart
**Generation**: `_generateConfetti()` (Lines 815-835)
**Display**: Overlay in `build()` method (Lines 357-363)
**Trigger**: `recordNormalBall()` (Lines 157-160)
**Appears In**: Full screen overlay (top to bottom)
```
When: 4 or 6 runs recorded
Where: Entire screen
Duration: 1000ms
Visual: 20 falling particles with colors
```

---

### 3. **Wicket Lightning Animation** ⚡
**Page**: ScoreboardPage.dart
**Display**: `build()` method (Lines 365-394)
**Animation**: `_triggerWicketAnimation()` (Lines 801-803)
**Trigger**: `recordNormalBall()` (Lines 151-152)
**Appears In**: Center of screen
```
When: Wicket dismissed
Where: Center screen overlay
Duration: 900ms
Visual: Rotating ⚡ in red circle
```

---

### 4. **Duck Animation** 🦆
**Page**: ScoreboardPage.dart
**Widget**: `_buildDuckAnimationWidget()` (Lines 756-788)
**In Batsman Row**: `_buildBatsmanRow()` (Lines 688-699)
**Animation**: `_triggerDuckAnimation()` (Lines 805-808)
**Trigger**: `recordNormalBall()` (Lines 154-155)
**Appears In**: Batsman row (dismissal status column)
```
When: 0-run dismissal
Where: Next to player name in "Out Batsmen" section
Duration: 1000ms
Visual: Duck emoji scales and fades
```

---

### 5. **Runout Highlight** 🔴
**Page**: ScoreboardPage.dart
**Detection**: `_checkForRunouts()` (Lines 176-196)
**Display**: `_buildBatsmanRow()` (Lines 638-718)
**Animation**: `_triggerRunoutHighlight()` (Lines 810-813)
**Trigger**: Auto-refresh every 2 seconds (Line 170)
**Appears In**: Entire batsman row
```
When: Runout marked
Where: Red border around player's scorecard row
Duration: 800ms
Visual: Red border fades from opaque to transparent
```

---

## Open the File

### In Android Studio / IntelliJ
1. Open project
2. Navigate to: `lib/src/Pages/Teams/scoreboard_page.dart`
3. Click on file
4. See all 1089 lines of scoreboard code with animations

### Using Terminal
```bash
# Navigate to project
cd d:\TURF_TOWN_-Aravind-kumar-k\TURF_TOWN_-Aravind-kumar-k

# Open file in VS Code
code lib/src/Pages/Teams/scoreboard_page.dart

# Or open in Android Studio
# File → Open → lib/src/Pages/Teams/scoreboard_page.dart
```

---

## Line Number Quick Reference

| Animation | Method Name | Lines |
|-----------|-------------|-------|
| **Setup** | _initializeAnimations() | 63-108 |
| **Cleanup** | dispose() | 111-118 |
| **4s/6s Highlighting** | _buildFoursSixesCell() | 721-754 |
| **Confetti Generation** | _generateConfetti() | 815-835 |
| **Confetti Display** | build() overlay | 357-363 |
| **Boundary Trigger** | recordNormalBall() | 157-160 |
| **Wicket Display** | build() overlay | 365-394 |
| **Wicket Trigger** | recordNormalBall() | 151-152 |
| **Duck Widget** | _buildDuckAnimationWidget() | 756-788 |
| **Duck Trigger** | recordNormalBall() | 154-155 |
| **Runout Detection** | _checkForRunouts() | 176-196 |
| **Runout Trigger** | _startAutoRefresh() | 170 |
| **Runout Display** | _buildBatsmanRow() | 638-718 |

---

## Main Sections in ScoreboardPage.dart

```dart
Lines 1-11     → Imports
Lines 13-24    → ScoreboardPage class (StatefulWidget)
Lines 27-54    → State variables & animations setup
Lines 57-118   → initState() & dispose()
Lines 123-227  → Game logic methods (recordWide, recordNoBall, etc.)
Lines 165-196  → Auto-refresh & runout detection
Lines 204-397  → Main build() method with animations
Lines 400-616  → _buildInningsSection() widget
Lines 634-718  → _buildBatsmanRow() with runout highlight & duck
Lines 721-754  → _buildFoursSixesCell() highlighting
Lines 756-788  → _buildDuckAnimationWidget() duck animation
Lines 790-822  → _buildBowlerRow() widget
Lines 977-1035 → _getOutText() dismissal info
Lines 1037-1052→ ConfettiPiece custom class
Lines 1054-1089→ ConfettiPainter custom class (particle rendering)
```

---

## How to See Animations in Action

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Navigate to ScoreboardPage
```
Home → Select Teams → Start Match → View Scoreboard
```

### Step 3: Record Scoring Events
- **For 4s/6s Highlighting**: Tap "4 runs" → See blue/orange box
- **For Confetti**: Record 4 or 6 runs → See particles fall
- **For Wicket**: Mark batsman out → See lightning rotate
- **For Duck**: Mark out on first ball (0 runs) → See duck emoji
- **For Runout**: Mark as runout → See red border flash

### Step 4: Open File to See Code
```
lib/src/Pages/Teams/scoreboard_page.dart
```

---

## Visual Map of ScoreboardPage.dart

```
┌─ ScoreboardPage (class definition)
│
├─ _ScoreboardPageState
│  │
│  ├─ Variables
│  │  ├─ Timer _refreshTimer
│  │  ├─ bool _isAutoRefreshEnabled
│  │  ├─ AnimationController _boundaryAnimationController ← 4s/6s confetti
│  │  ├─ AnimationController _wicketAnimationController ← wicket lightning
│  │  ├─ AnimationController _duckAnimationController ← duck emoji
│  │  ├─ AnimationController _runoutHighlightController ← runout border
│  │  └─ List<ConfettiPiece> _confettiPieces ← particle list
│  │
│  ├─ initState()
│  │  └─ _initializeAnimations() ← Setup all 4 controllers
│  │
│  ├─ dispose()
│  │  └─ Cleanup all animation controllers
│  │
│  ├─ _startAutoRefresh()
│  │  └─ _checkForRunouts() ← Detect runouts every 2 seconds
│  │
│  ├─ build() ← Main UI
│  │  ├─ Container with gradient background
│  │  ├─ Column with header
│  │  ├─ Confetti overlay (Lines 357-363) ← 4s/6s confetti display
│  │  └─ Wicket overlay (Lines 365-394) ← Wicket animation display
│  │
│  ├─ _buildInningsSection()
│  │  └─ _buildBatsmanRow() ← Shows individual batsman
│  │     ├─ Calls _buildFoursSixesCell() ← 4s/6s highlighting
│  │     ├─ Calls _buildDuckAnimationWidget() ← Duck animation
│  │     └─ AnimatedBuilder for runout border ← Runout highlight
│  │
│  ├─ Game Logic
│  │  ├─ recordNormalBall()
│  │  │  ├─ Calls _triggerBoundaryAnimation() (4s/6s confetti)
│  │  │  ├─ Calls _triggerWicketAnimation() (wicket lightning)
│  │  │  └─ Calls _triggerDuckAnimation() (duck emoji)
│  │  │
│  │  ├─ recordWide()
│  │  ├─ recordNoBall()
│  │  └─ recordBye()
│  │
│  ├─ Animation Methods
│  │  ├─ _triggerBoundaryAnimation() ← Start confetti
│  │  ├─ _triggerWicketAnimation() ← Start lightning
│  │  ├─ _triggerDuckAnimation() ← Start duck emoji
│  │  ├─ _triggerRunoutHighlight() ← Start red border
│  │  └─ _generateConfetti() ← Create particles
│  │
│  ├─ Widget Builders
│  │  ├─ _buildBatsmanRow() ← Shows batsman with animations
│  │  ├─ _buildFoursSixesCell() ← Blue/orange highlighting
│  │  ├─ _buildDuckAnimationWidget() ← Duck emoji animation
│  │  └─ Other builders...
│  │
│  └─ Helper Methods
│     └─ _getOutText() ← Dismissal information
│
├─ ConfettiPiece (custom class for particles)
│  ├─ x, y, vx, vy ← Position & velocity
│  ├─ rotation ← Particle rotation
│  └─ color ← Random color
│
└─ ConfettiPainter extends CustomPainter
   ├─ paint() ← Draws particles with physics
   └─ shouldRepaint() ← Update on every frame
```

---

## Quick Find in File

### To Find Animation Code
1. **Search for "Animation" in file**:
   - Late animation variables: Line 40-45
   - Initialize: Line 63-108
   - Triggers: Line 151-160

2. **Search for "Confetti"**:
   - Generation: Line 815-835
   - Display: Line 357-363
   - Particle class: Line 1037-1052
   - Painter class: Line 1054-1089

3. **Search for "Duck"**:
   - Widget: Line 756-788
   - In batsman row: Line 688-699

4. **Search for "Wicket"**:
   - Overlay display: Line 365-394
   - Trigger: Line 801-803

5. **Search for "Runout"**:
   - Detection: Line 176-196
   - Trigger: Line 810-813
   - Display in row: Line 642-650

---

## Summary

**ONE FILE. FIVE ANIMATIONS.**

```
📁 Project Root
  └─ 📁 lib
      └─ 📁 src
          └─ 📁 Pages
              └─ 📁 Teams
                  └─ 📄 scoreboard_page.dart
                     ├─ 🎨 4s/6s Highlighting (Lines 721-754)
                     ├─ 🎉 Confetti Animation (Lines 815-835, 357-363)
                     ├─ ⚡ Wicket Lightning (Lines 365-394, 801-803)
                     ├─ 🦆 Duck Animation (Lines 756-788)
                     └─ 🔴 Runout Highlight (Lines 176-196, 638-718)
```

**Open this file to see all animation code!**
