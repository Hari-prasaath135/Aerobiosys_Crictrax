# End-to-End Resume Match Test Plan

**Date**: February 10, 2025
**Status**: ✅ Ready for Testing
**Test Scope**: Complete paused match resume workflow

---

## Test Objective

Verify that:
1. ✅ Match can be saved mid-game with all data intact
2. ✅ Paused match appears in History with correct display
3. ✅ Resume action properly restores match state
4. ✅ All match data (batsmen, bowlers, scores) persists after resume
5. ✅ Buttons and scoring work correctly after resuming

---

## Test Environment Setup

### Prerequisites
- ✅ Flutter app running on device/emulator
- ✅ At least 2 teams created in app
- ✅ Teams have players assigned

### Before Each Test
1. Clean previous test data if needed
2. Start fresh match with known teams
3. Record initial setup for comparison

---

## Test 1: Save Incomplete Match

### Steps
1. Open app → Team Page
2. Select 2 teams (e.g., "Team A" vs "Team B")
3. Go to Toss page → Select winner and decision
4. Navigate to Cricket Scorer screen
5. **Play several overs** (record exact ball-by-ball):
   - Record specific runs (4s, 6s, singles)
   - Mark 2-3 wickets
   - Take note of current score
6. Tap **back arrow** button
7. Dialog appears: "Leave Match?"

### Expected Result
✅ Dialog shows 3 buttons:
- Continue Match
- Save & Exit (green)
- Discard & Exit (red)

### Pass/Fail Criteria
| Criteria | Status |
|----------|--------|
| Dialog appears | ✅ |
| 3 buttons visible | ✅ |
| Correct button colors | ✅ |
| All buttons clickable | ✅ |

---

## Test 2: Confirm Save Action

### Steps
1. **Tap "Save & Exit"** button
2. Wait for processing
3. Check for success message
4. Verify redirection

### Expected Result
✅ Success message: "Match saved! You can resume it later."
✅ Automatically redirected to Team Page after ~0.5 seconds

### Pass/Fail Criteria
| Criteria | Expected | Actual |
|----------|----------|--------|
| Success message appears | Yes | |
| Message text correct | "Match saved!..." | |
| Auto-redirect to Team Page | Yes | |
| Redirect timing (~500ms) | 200-800ms | |

---

## Test 3: Verify Paused Match in History

### Steps
1. From Team Page, navigate to **History Page**
2. Observe match display
3. Note paused match location and styling

### Expected Result
✅ "PAUSED MATCHES" section appears at TOP with gold header
✅ Saved match displays with:
- Team names (Team A vs Team B)
- Team A score and overs
- Team B score and overs
- Gold border highlight
- Play icon (▶)
- "⏸ PAUSED - TAP TO RESUME" badge in gold

✅ Below paused matches: "COMPLETED MATCHES" section (if any)

### Pass/Fail Criteria
| Element | Expected | Actual |
|---------|----------|--------|
| Paused section visible | Yes | |
| Gold header text | "PAUSED MATCHES..." | |
| Match card visible | Yes | |
| Team names correct | Team A vs Team B | |
| Score displays | Run/Wicket format | |
| Overs display | X.Y format | |
| Gold border | Visible | |
| Play icon | Visible | |
| Paused badge | Gold badge | |
| Section order | Paused on top | |

---

## Test 4: Resume Match from History

### Steps
1. In History Page, tap on **paused match card**
2. Wait for navigation and loading
3. Observe Cricket Scorer screen appears

### Expected Result
✅ Navigates to Cricket Scorer Screen
✅ Loading screen appears briefly (max 3 seconds)
✅ Match data loads successfully
✅ No errors or stuck screens

### Pass/Fail Criteria
| Criteria | Expected | Actual |
|----------|----------|--------|
| Navigation successful | Yes | |
| Loading screen appears | Yes | |
| Loading time | <3 seconds | |
| No error dialogs | Correct | |
| Scorer screen appears | Yes | |
| Data loads completely | Yes | |

---

## Test 5: Verify Restored Match State

### Steps
1. Once Cricket Scorer loads, verify displayed data
2. Check current batsmen names
3. Check bowler name
4. Check score display
5. Compare with pre-save state

### Restored Data Checklist

| Data | Expected | Actual |
|------|----------|--------|
| **Teams** | | |
| Batting team | Same as before save | |
| Bowling team | Same as before save | |
| **Strike Batsman** | | |
| Name | Previously selected | |
| Runs | Same as before save | |
| Balls faced | Same as before save | |
| **Non-Strike Batsman** | | |
| Name | Previously selected | |
| Runs | Same as before save | |
| **Bowler** | | |
| Name | Previously selected | |
| Overs | Same as before save | |
| Runs conceded | Same as before save | |
| **Score Display** | | |
| Total runs | Same as before save | |
| Wickets | Same as before save | |
| Overs | Same as before save (X.Y) | |
| Current over | Correct (if not complete) | |

---

## Test 6: Button Functionality After Resume

### Steps
1. With resumed match visible, test each button
2. Tap "4 runs" button
3. Verify score updates
4. Tap "Wicket" button
5. Verify wicket dialog appears
6. Test other buttons: 6, 1, 2, Byes, etc.

### Expected Result
✅ All buttons responsive
✅ Scoring works correctly
✅ Wicket dialog appears
✅ Changes persisted in display
✅ Animations play (if applicable)

### Pass/Fail Criteria
| Button | Action | Expected Result | Status |
|--------|--------|-----------------|--------|
| 4 runs | Tap | Score +4, animation | ✅ |
| 6 runs | Tap | Score +6, animation | ✅ |
| 1 run | Tap | Score +1 | ✅ |
| 2 runs | Tap | Score +2 | ✅ |
| 0 runs | Tap | No score | ✅ |
| Wicket (W) | Tap | Wicket dialog | ✅ |
| No Ball | Tap | Toggle, affects extras | ✅ |
| Wide | Tap | Toggle, affects extras | ✅ |
| Byes | Tap | Toggle, affects extras | ✅ |

---

## Test 7: Continue Playing After Resume

### Steps
1. After resume, continue scoring
2. Add 2-3 more overs
3. Mark some more boundaries/wickets
4. Complete current over
5. Verify flow works

### Expected Result
✅ Match continues normally
✅ New scores added correctly
✅ Over completion triggers bowler selection
✅ Smooth gameplay without freezing

### Pass/Fail Criteria
| Step | Expected | Status |
|------|----------|--------|
| Scoring works | Yes | |
| Over completion | Normal dialog | |
| Bowler selection | Works | |
| No crashes | Correct | |
| Data persists | Correct | |

---

## Test 8: Save Again After Resume

### Steps
1. After adding more overs, tap back again
2. Dialog appears
3. Tap "Save & Exit" again
4. Go to History
5. Verify updated score in paused section

### Expected Result
✅ Can save paused match again
✅ Updated score shows in History
✅ Previous save is replaced with new version
✅ Only one entry for same match in paused section

### Pass/Fail Criteria
| Criterion | Expected | Status |
|-----------|----------|--------|
| Dialog appears | Yes | |
| Save works | Yes | |
| Score updates | Yes | |
| Only 1 entry | Yes | |
| New score correct | Yes | |

---

## Test 9: Complete Match After Resume

### Steps
1. Resume paused match
2. Play remaining overs to completion
3. Match completion occurs (victory/loss)
4. Victory animation plays
5. Verify match moves to completed

### Expected Result
✅ Can complete match after resume
✅ Victory animation plays
✅ Match moves to "COMPLETED MATCHES" section
✅ Removed from "PAUSED MATCHES" section

### Pass/Fail Criteria
| Criterion | Expected | Status |
|-----------|----------|--------|
| Match completes | Yes | |
| Victory animation | Plays | |
| History updated | Moves to completed | |
| Paused entry removed | Yes | |
| Completed shows result | Correct | |

---

## Test 10: Multiple Paused Matches

### Steps
1. Create and pause 3 different matches
2. Record different progress for each
3. Go to History
4. Verify all 3 appear in paused section
5. Resume each one sequentially
6. Verify each resumes with correct data

### Expected Result
✅ All 3 paused matches appear in History
✅ Each displays correct team names and scores
✅ Each resumes with its own data intact
✅ No cross-contamination between matches

### Pass/Fail Criteria
| Criterion | Expected | Status |
|-----------|----------|--------|
| All 3 appear | Yes | |
| Team names correct | Match-specific | |
| Scores different | Each unique | |
| Resume order | Any order works | |
| Data isolation | No mixing | |

---

## Test 11: Discard Match Flow

### Steps
1. Start new match
2. Play a few overs
3. Tap back, select "Discard & Exit"
4. Go to History
5. Verify match NOT in paused section

### Expected Result
✅ Match deleted without saving
✅ Does not appear in History
✅ Returns to Team Page

### Pass/Fail Criteria
| Criterion | Expected | Status |
|-----------|----------|--------|
| Navigates to Team Page | Yes | |
| No entry in History | Correct | |
| No data persisted | Correct | |

---

## Test 12: Edge Cases

### Test 12A: Resume with Missing Data
**Setup**: Manually corrupt paused state JSON in database
**Expected**: Error message shown, graceful handling

### Test 12B: Very Large Score
**Setup**: Play 100+ runs before saving
**Expected**: All data preserved correctly

### Test 12C: Many Wickets
**Setup**: Save with 8-9 wickets down
**Expected**: Correct batsmen order restored

### Test 12D: Resume with Network Delay
**Setup**: Simulate slow database
**Expected**: Loading timeout handled gracefully

---

## Test Execution Checklist

### Pre-Test
- [ ] Device/emulator ready
- [ ] App freshly built
- [ ] Teams created
- [ ] Database cleared (if needed)

### During Test
- [ ] Follow each test case step-by-step
- [ ] Record actual vs expected results
- [ ] Take screenshots for issues
- [ ] Note any error messages

### Post-Test
- [ ] Summarize results
- [ ] List any failures
- [ ] Note performance metrics
- [ ] Document bugs found

---

## Known Issues & Workarounds

### Issue: Loading Screen Hangs
**Cause**: inningsId not properly passed
**Fix**: Parse pausedState JSON to get correct inningsId ✅ (Applied)
**Workaround**: Manually pass correct IDs

### Issue: Data Not Restored
**Cause**: pausedState not being restored to Score/Batsman objects
**Fix**: Verify pausedState contains all required fields
**Workaround**: None needed if fix applied

---

## Success Criteria Summary

✅ **All tests pass** if:
1. Save dialog works with 3 buttons
2. Paused matches appear in History
3. Gold header and styling correct
4. Resume navigates without hanging
5. Match data fully restored
6. All buttons work after resume
7. Can continue playing or complete match
8. Can save again
9. Multiple paused matches work
10. Discard flow works correctly

---

## Failure Criteria

❌ **Test fails** if:
1. Loading screen hangs >5 seconds
2. Match data not restored
3. Buttons unresponsive after resume
4. Wrong data displayed after resume
5. Crash or error dialog appears
6. Data corruption or mixing
7. Incomplete restoration of state

---

## Performance Benchmarks

| Metric | Target | Actual |
|--------|--------|--------|
| Save time | <1 second | |
| Load paused matches | <2 seconds | |
| Resume navigation | <3 seconds | |
| Resume initialization | <2 seconds | |
| Scoring after resume | <100ms | |

---

## Test Report Template

```
Date: _______________
Tester: _______________
Build: _______________

Test 1: Save Match - PASS/FAIL
Test 2: Confirm Save - PASS/FAIL
Test 3: Verify in History - PASS/FAIL
Test 4: Resume Match - PASS/FAIL
Test 5: Verify State - PASS/FAIL
Test 6: Button Functionality - PASS/FAIL
Test 7: Continue Playing - PASS/FAIL
Test 8: Save Again - PASS/FAIL
Test 9: Complete Match - PASS/FAIL
Test 10: Multiple Matches - PASS/FAIL
Test 11: Discard Flow - PASS/FAIL
Test 12: Edge Cases - PASS/FAIL

Total Tests: 12
Passed: ___
Failed: ___

Critical Issues: _______________
Minor Issues: _______________
Performance: _______________

Sign-off: _______________
```

---

**Status**: ✅ READY FOR TESTING
**Quality**: Comprehensive Test Coverage
**Date**: February 10, 2025

🚀 **Ready to execute all tests!**

---
