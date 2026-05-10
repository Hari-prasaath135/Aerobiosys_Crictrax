# Scoreboard Animation Test Plan

## Overview
This document outlines the test scenarios for the enhanced scoreboard UI animations implemented in scoreboard_page.dart.

## Animation Features Implemented

### 1. **4s and 6s Button Highlighting** ✓
- **Feature**: Fours and sixes in the scorecard are highlighted with colored containers
- **Visual**:
  - Fours (4): Blue background with blue border
  - Sixes (6): Orange background with orange border
- **Trigger**: Automatic when value > 0
- **Location**: Scorecard table cells

### 2. **Boundary Animation Effects (4s and 6s)** ✓
- **Feature**: Confetti animation on screen after boundary hits
- **Animation Type**: Confetti particles with physics simulation
- **Duration**: 1000ms (Medium duration as requested)
- **Trigger**: When batsman scores 4 or 6 runs in recordNormalBall()
- **Visual**: 20 colored particles falling with gravity and rotation

### 3. **Wicket Animation Effects** ✓
- **Feature**: Rotating lightning bolt emoji (⚡) displayed when wicket falls
- **Animation Type**: Continuous rotation with scale effect
- **Duration**: 900ms (Medium-fast for dramatic impact)
- **Trigger**: When isWicket=true in recordNormalBall()
- **Visual**: Rotating red circle with lightning emoji in center
- **Location**: Center of screen overlay

### 4. **Duck-out Player Animations** ✓
- **Feature**: Duck emoji (🦆) animation for players who score 0 runs and get out
- **Animation Type**: Scale + Fade (grow and disappear)
- **Duration**: 1000ms (Medium duration)
- **Trigger**: When batsman is out with runs == 0
- **Visual**: Duck emoji scales up from 0 to 1.0, then fades to transparent
- **Location**: Next to player dismissal status
- **Condition**: Automatic - shows "Duck" text with animated emoji overlay

### 5. **Runout Button Highlighting** ✓
- **Feature**: Red border flash around entire batsman scorecard row when marked as runout
- **Animation Type**: Border color fade (red to transparent)
- **Duration**: 800ms (Medium duration)
- **Trigger**: Auto-detected on each refresh when dismissalType == 'runout'
- **Visual**: Red border with 0.8 opacity fading to 0.0
- **Location**: Full width of batsman row
- **Method**: _checkForRunouts() called during auto-refresh

## Test Scenarios

### Scenario 1: Boundary Animation (4 Runs)
**Setup**:
- Have active batsman in match
- Record a 4-run boundary

**Expected Result**:
1. Confetti particles appear on screen
2. Particles fall with gravity physics
3. Particles rotate as they fall
4. Fours cell highlights with blue background and border
5. Animation completes in ~1 second

**Test Steps**:
1. In cricket_scorer_screen, select a batsman
2. Input 4 runs
3. Confirm the score update
4. Observe confetti animation on scoreboard

---

### Scenario 2: Boundary Animation (6 Runs)
**Setup**:
- Have active batsman in match
- Record a 6-run boundary

**Expected Result**:
1. Confetti particles appear on screen
2. Sixes cell highlights with orange background and border
3. Animation completes in ~1 second

**Test Steps**:
1. In cricket_scorer_screen, select a batsman
2. Input 6 runs
3. Confirm the score update
4. Observe confetti animation and orange highlight

---

### Scenario 3: Wicket Animation
**Setup**:
- Have bowler ready
- Mark batsman as out (not runout)

**Expected Result**:
1. Red circular overlay appears in center of screen
2. Lightning emoji (⚡) rotates continuously
3. Animation lasts ~900ms
4. Overlay disappears
5. Batsman appears in "Out batsmen" section with dismissal info

**Test Steps**:
1. In cricket_scorer_screen, record a normal wicket
2. Observe the rotating lightning animation
3. Verify batsman status changes to "out"

---

### Scenario 4: Duck Out Animation
**Setup**:
- Batsman gets out without scoring any runs

**Expected Result**:
1. Batsman row shows "Duck" text in red
2. Duck emoji (🦆) animates with scale + fade
3. Emoji scales from 0 to 1.0 then fades out
4. Animation completes in ~1 second

**Test Steps**:
1. In cricket_scorer_screen, mark a batsman out on first ball (0 runs)
2. Open scoreboard
3. Scroll to out batsmen section
4. Observe duck emoji animation with "Duck" text

---

### Scenario 5: Runout Highlight
**Setup**:
- Record a runout dismissal

**Expected Result**:
1. Batsman row that was marked runout flashes with red border
2. Border opacity fades from 0.8 to 0.0
3. Animation lasts ~800ms
4. Border disappears completely
5. Batsman appears in "Out batsmen" section with "run out" info

**Test Steps**:
1. In cricket_scorer_screen, select "Runout" option
2. Choose a fielder who made the runout
3. Return to scoreboard
4. Observe red border flash on runout batsman's row
5. Verify dismissal shows correct fielder name

---

### Scenario 6: 4s and 6s Highlighting
**Setup**:
- Complete an over with multiple 4s and 6s

**Expected Result**:
1. All 4s appear with blue highlighting
2. All 6s appear with orange highlighting
3. Non-boundary runs appear without highlighting
4. Highlighting persists throughout innings

**Test Steps**:
1. Input multiple 4s and 6s in scorecard
2. Scroll through batsman rows
3. Verify visual distinction between 4s, 6s, and other runs

---

## Test Execution Checklist

- [ ] Build app successfully: `flutter build apk` or `flutter run`
- [ ] Scenario 1: 4-run boundary animation works
- [ ] Scenario 2: 6-run boundary animation works
- [ ] Scenario 3: Wicket animation works
- [ ] Scenario 4: Duck animation works
- [ ] Scenario 5: Runout highlight works
- [ ] Scenario 6: 4s and 6s highlighting persistent
- [ ] Animation duration matches preferences (800-1200ms)
- [ ] No animation overlaps interfere with each other
- [ ] No memory leaks or performance issues
- [ ] Animations work on different screen sizes
- [ ] Animations work with auto-refresh enabled/disabled

## Performance Notes

- All animations use Flutter's built-in AnimationController
- Confetti uses CustomPaint for efficient particle rendering
- Animations are GPU-accelerated where possible
- IgnorePointer used to prevent animation overlays from blocking interaction
- Memory is cleaned up properly in dispose()

## Known Limitations

- Confetti particles are simple squares (not custom shapes)
- Duck emoji animation doesn't support custom GIF files (uses emoji instead)
- All animations are non-interactive (can't be clicked)
- Animations play automatically based on game events (not user-triggered)
