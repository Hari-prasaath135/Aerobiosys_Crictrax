# 📋 END-TO-END TEST PLAN - CricSync Full Workflow

**Date**: 2026-02-14
**Scope**: Splash Screen → Bluetooth → Full Match → Persistence → New Match
**Device**: Real Android Device with Bluetooth

---

## 🚀 PHASE 1: APP LAUNCH & SPLASH SCREEN

### Test 1.1: Splash Screen Animation Sequence
**Objective**: Verify new splash screen with Lottie animations displays correctly

```
Expected Flow:
┌─ 0-3200ms: Sports loader animation (zoom in/out)
├─ 3200-6400ms: Cricket bat & ball loader (zoom in/out)
├─ 6400-9400ms: "CricSync" gradient text + tagline fade-in
└─ 9400ms+: Auto-navigate to SlidingPage
```

**Steps**:
1. [ ] Launch app: `flutter run`
2. [ ] Watch splash screen
3. [ ] Verify Sports loader animation plays ✓
4. [ ] Verify Cricket loader animation plays ✓
5. [ ] Verify "CricSync" text appears with gradient ✓
6. [ ] Verify "Your Ultimate Sports Hub" tagline appears ✓
7. [ ] Verify auto-navigation to home page ✓

**Expected Result**: Smooth sequential animations, no UI glitches
**Actual Result**: ________________

---

### Test 1.2: Navigation After Splash
**Objective**: Verify splash navigates correctly to SlidingPage

**Steps**:
1. [ ] Allow splash to complete
2. [ ] Verify SlidingPage loads without errors
3. [ ] Check console for navigation messages ✓

**Expected Result**: Clean navigation, no exceptions
**Actual Result**: ________________

---

## 🔵 PHASE 2: BLUETOOTH CONNECTION

### Test 2.1: Bluetooth Device Discovery
**Objective**: Verify device can find ESP32/LED display

**Steps**:
1. [ ] Ensure LED display/ESP32 is powered on
2. [ ] On SlidingPage, look for "Connect Bluetooth" option
3. [ ] Tap Bluetooth button
4. [ ] Verify device list appears
5. [ ] Locate your LED device in list ✓
6. [ ] Tap to connect

**Expected Result**: Device connects without errors
**Actual Result**: ________________

**Console Logs Should Show**:
```
✅ BleManagerService: Initialized with [DeviceName]
✅ Bluetooth service ready
```

---

### Test 2.2: Bluetooth Connection Verification
**Objective**: Confirm connection is stable

**Steps**:
1. [ ] After connection, verify "Connected" status shows
2. [ ] Check LED display receives test signals
3. [ ] Monitor logcat for connection status:
   ```
   D/[FBP-Android]: [FBP] onConnectionStateChange: connected
   ```
4. [ ] Verify no immediate disconnects ✓

**Expected Result**: Stable connection, no errors
**Actual Result**: ________________

---

## 🏏 PHASE 3: FIRST INNINGS SETUP

### Test 3.1: Team & Player Selection
**Objective**: Set up match with teams and players

**Steps**:
1. [ ] Tap "New Match" from home
2. [ ] Select Team A (batting team)
3. [ ] Select Team B (bowling team)
4. [ ] Verify player lists load
5. [ ] Proceed to match setup ✓

**Expected Result**: Smooth navigation, all data loads
**Actual Result**: ________________

---

### Test 3.2: Match Initialization
**Objective**: Verify match initializes with Bluetooth ready

**Steps**:
1. [ ] Start match (1st Innings)
2. [ ] Wait for "Initializing..." screen to complete
3. [ ] Monitor logcat for:
   ```
   ⏳ Waiting for Bluetooth connection...
   ✅ Bluetooth connected - ready to send commands
   🧹 Clearing display before drawing layout...
   ✅ Full LED layout drawn
   ```
4. [ ] Verify LED display shows match layout ✓
5. [ ] Verify no errors in console ✓

**Expected Result**: LED displays match data, no errors
**Actual Result**: ________________

---

## 📊 PHASE 4: FIRST INNINGS SCORING

### Test 4.1: Score Entry
**Objective**: Record batting stats and verify LED updates

**Steps**:
1. [ ] Record several runs (1, 2, 4, 6)
2. [ ] Watch LED display update after each run
3. [ ] Verify runs display correctly: `SCR: XX/W`
4. [ ] Verify CRR and overs update
5. [ ] Test extras (wide, no-ball, bye) ✓
6. [ ] Verify LED reflects all changes ✓

**Expected Result**: LED updates in real-time, no lag
**Actual Result**: ________________

---

### Test 4.2: Animations
**Objective**: Verify Lottie animations trigger correctly

**Steps**:
1. [ ] Record 4 runs → Verify "Scored 4.lottie" plays
2. [ ] Record 6 runs → Verify "SIX ANIMATION.lottie" plays
3. [ ] Mark batsman out → Verify "CRICKET OUT ANIMATION.lottie"
4. [ ] Check if duck (out on 0 runs) → Verify "Duck Out.lottie"
5. [ ] All animations should fade automatically ✓

**Expected Result**: Smooth, professional animations
**Actual Result**: ________________

---

### Test 4.3: Wickets
**Objective**: Record dismissals and verify LED updates

**Steps**:
1. [ ] Record a wicket
2. [ ] Select bowler who got wicket
3. [ ] Verify wicket count updates on LED
4. [ ] Verify next batsman dialog appears
5. [ ] Select next batsman
6. [ ] Verify LED updates striker name ✓

**Expected Result**: Seamless wicket handling, LED updates immediately
**Actual Result**: ________________

---

### Test 4.4: Over Completion
**Objective**: Verify over transitions work correctly

**Steps**:
1. [ ] Complete an over (6 balls)
2. [ ] Verify "Change Bowler" dialog appears
3. [ ] Select new bowler
4. [ ] Verify striker/non-striker swap for even runs
5. [ ] Verify LED updates correctly ✓

**Expected Result**: Smooth over transitions, correct strike swaps
**Actual Result**: ________________

---

### Test 4.5: Innings Completion
**Objective**: Complete first innings scoring

**Steps**:
1. [ ] Continue scoring until innings end (10 wickets OR overs complete)
2. [ ] Verify final score displays
3. [ ] Verify LED shows final stats
4. [ ] Check target is set for 2nd innings ✓

**Expected Result**: Innings ends smoothly, target set correctly
**Actual Result**: ________________

---

## 🔄 PHASE 5: SECOND INNINGS SETUP

### Test 5.1: Innings 2 Transition
**Objective**: Verify transition from 1st to 2nd innings

**Steps**:
1. [ ] After 1st innings, verify 1st innings summary shows on LED for 3 seconds
2. [ ] Summary should display:
   - Team name who batted
   - Score (runs/wickets)
   - Overs
   - Target for 2nd innings
3. [ ] After 3 seconds, LED clears
4. [ ] 2nd innings layout draws ✓

**Expected Result**: Clean transition, proper summary display
**Actual Result**: ________________

---

### Test 5.2: 2nd Innings Initialization
**Objective**: Verify 2nd innings starts with fresh data

**Steps**:
1. [ ] Select batting team for 2nd innings
2. [ ] Select bowler for 2nd innings
3. [ ] Verify LED shows "TARGET: XXX" prominently
4. [ ] Verify runs needed calculation is correct ✓

**Expected Result**: Correct target setup, LED reflects requirements
**Actual Result**: ________________

---

## 🏆 PHASE 6: SECOND INNINGS SCORING & VICTORY

### Test 6.1: Chase Scoring
**Objective**: Record chase attempt and verify target tracking

**Steps**:
1. [ ] Score runs toward target
2. [ ] Monitor "runs needed" banner (should decrease)
3. [ ] Verify LED updates target progress
4. [ ] Verify animations trigger on 4/6
5. [ ] Continue until one of two outcomes ✓

**Expected Result**: Smooth chase tracking, real-time updates
**Actual Result**: ________________

---

### Test 6.2: Victory - Team Won (Target Met)
**Objective**: Verify victory when target is reached

**Steps**:
1. [ ] Record final runs to reach target
2. [ ] Verify victory animation triggers
3. [ ] Verify victory dialog appears with:
   - "Team Name won by X wickets"
   - Final scores displayed
4. [ ] Verify snackbar shows victory message ✓
5. [ ] Verify LED clears automatically

**Expected Result**: Professional victory display, animations smooth
**Actual Result**: ________________

---

### Test 6.3: Defeat - Team Did Not Meet Target
**Objective**: Verify match completion when target not met

**Steps**:
1. [ ] If target not met and all 10 wickets fall:
2. [ ] Verify victory dialog shows: "Team A won by X runs"
3. [ ] Verify scores display correctly
4. [ ] Verify snackbar confirms result ✓
5. [ ] Verify LED clears

**Expected Result**: Clear victory confirmation for winning team
**Actual Result**: ________________

---

## 🔴 PHASE 7: BLUETOOTH PERSISTENCE FIX (CRITICAL)

### Test 7.1: Bluetooth After Victory Dialog
**Objective**: **CRITICAL FIX VERIFICATION** - Bluetooth must stay connected

**Steps**:
1. [ ] Victory dialog is displayed
2. [ ] **CHECK LOGCAT** - Should NOT see:
   ```
   ❌ D/BluetoothGatt: [FBP] onMethodCall: disconnect
   ❌ D/BluetoothGatt: [FBP] onConnectionStateChange:disconnected
   ```
3. [ ] Verify connection status in app (should show "Connected")
4. [ ] Wait 3 seconds for auto-navigation ✓

**Expected Result**: Bluetooth stays connected during navigation ✅
**Actual Result**: ________________

---

### Test 7.2: Bluetooth After Navigation to Home
**Objective**: Verify Bluetooth persists after page navigation

**Steps**:
1. [ ] App auto-navigates to Home page
2. [ ] **CHECK LOGCAT** - No disconnect messages
3. [ ] On Home page, check Bluetooth status
4. [ ] Should still show "Connected" ✓
5. [ ] No manual reconnection needed

**Expected Result**: Bluetooth stays connected across navigation
**Actual Result**: ________________

**This is the CRITICAL FIX - If this fails, the fix didn't work!**

---

## 🎮 PHASE 8: NEW MATCH WITHOUT RECONNECTION

### Test 8.1: Start New Match (Bluetooth Still Connected)
**Objective**: Verify seamless new match start

**Steps**:
1. [ ] From Home page, tap "New Match"
2. [ ] **Bluetooth should still be connected** ✓
3. [ ] Select teams and players
4. [ ] Start new innings
5. [ ] Verify LED displays new match layout immediately
6. [ ] No Bluetooth reconnection needed ✓

**Expected Result**: Seamless new match, no Bluetooth interruption
**Actual Result**: ________________

---

### Test 8.2: Continuous Bluetooth Operation
**Objective**: Verify Bluetooth can handle multiple matches

**Steps**:
1. [ ] Record a few runs/wickets
2. [ ] Verify LED updates correctly
3. [ ] Verify no disconnections in logcat
4. [ ] Verify smooth operation ✓

**Expected Result**: Professional, uninterrupted operation
**Actual Result**: ________________

---

## 📱 PHASE 9: FULL WORKFLOW VERIFICATION

### Test 9.1: Complete End-to-End Flow
**Objective**: One continuous test from start to finish

```
Splash Screen
    ↓
App Home
    ↓
Select Teams & Players
    ↓
1st Innings Complete
    ↓
2nd Innings Complete & Victory
    ↓
Auto-navigate to Home ← BLUETOOTH STAYS CONNECTED ✅
    ↓
Select New Match
    ↓
2nd Match Starts Smoothly (NO RECONNECTION) ✓
```

**Checklist**:
- [ ] Splash animations play smoothly
- [ ] Bluetooth connects without issues
- [ ] LED displays match data correctly
- [ ] Animations trigger on 4/6/wickets
- [ ] First innings completes successfully
- [ ] Second innings summary displays
- [ ] Match victory/defeat handled properly
- [ ] **Bluetooth stays connected after match** ← CRITICAL
- [ ] Navigation to Home works smoothly
- [ ] New match starts without reconnection

**Expected Result**: Perfect end-to-end workflow
**Actual Result**: ________________

---

## 🐛 PHASE 10: BUG REPORTING

### Test 10.1: Issues Found
**If any issues found, document here**:

**Issue #1**:
- **Description**: ________________
- **Steps to Reproduce**: ________________
- **Expected**: ________________
- **Actual**: ________________
- **Severity**: [ ] Critical [ ] Major [ ] Minor

**Issue #2**:
- **Description**: ________________
- **Steps to Reproduce**: ________________
- **Expected**: ________________
- **Actual**: ________________
- **Severity**: [ ] Critical [ ] Major [ ] Minor

---

## ✅ FINAL SIGN-OFF

**Test Execution Date**: ________________
**Tester Name**: ________________
**Device Model**: ________________
**Android Version**: ________________
**Build Version**: ________________

### Overall Status:
- [ ] **PASS** - All tests passed, ready for production
- [ ] **PASS WITH NOTES** - Minor issues found, documented above
- [ ] **FAIL** - Critical issues found, needs fixing

### Critical Test (Bluetooth Persistence):
- [ ] **PASS** ✅ - Bluetooth stayed connected after match
- [ ] **FAIL** ❌ - Bluetooth disconnected (FIX DIDN'T WORK)

---

**Notes**:
```
________________
________________
________________
________________
```

---

*For issues, create GitHub issue or contact development team*
