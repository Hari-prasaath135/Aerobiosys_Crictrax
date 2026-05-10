# Quick Testing Checklist - Save & Resume Matches

**Date**: February 10, 2025
**Ready For**: Immediate Testing
**Estimated Time**: 15-20 minutes for full test

---

## ✅ Pre-Testing Checklist

- [ ] Device/emulator running
- [ ] App freshly built
- [ ] No previous test data interfering
- [ ] At least 2 teams created
- [ ] Teams have players assigned

---

## 🧪 Test 1: Save Incomplete Match (3 min)

### Steps
1. [ ] Start new match (Team A vs Team B)
2. [ ] Go through toss page
3. [ ] Start Cricket Scorer
4. [ ] Play several overs (record exact runs: 4s, 6s, singles)
5. [ ] Mark 2-3 wickets
6. [ ] **Tap back button**
7. [ ] Verify dialog appears with 3 buttons

### Expected Result
- [ ] Dialog: "Leave Match?" with 3 buttons
- [ ] "Continue Match" button visible
- [ ] "Save & Exit" button (green) visible
- [ ] "Discard & Exit" button (red) visible

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 2: Confirm Save Action (2 min)

### Steps
1. [ ] Tap "Save & Exit" button
2. [ ] Wait for success message
3. [ ] Verify message: "Match saved! You can resume it later."
4. [ ] Wait for navigation

### Expected Result
- [ ] Success message appears
- [ ] Message text correct
- [ ] Auto-redirects to Team Page (~500ms)

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 3: Check History Page (2 min)

### Steps
1. [ ] Navigate to History Page
2. [ ] Look for "PAUSED MATCHES" section
3. [ ] Verify gold header
4. [ ] Verify paused match card visible

### Expected Result
- [ ] "PAUSED MATCHES" section at top (gold header)
- [ ] Paused match shows:
  - [ ] Team names (Team A vs Team B)
  - [ ] Team A: Runs/Wickets (Overs)
  - [ ] Team B: Runs/Wickets (Overs)
  - [ ] Gold border
  - [ ] Play icon (▶)
  - [ ] "⏸ PAUSED - TAP TO RESUME" badge

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 4: Resume Match (3 min) - **CRITICAL TEST**

### Steps
1. [ ] Tap on paused match card
2. [ ] **WATCH FOR LOADING SCREEN**
3. [ ] Count seconds until match loads
4. [ ] Check for error dialogs
5. [ ] Verify match data displayed

### Expected Result
- [ ] ✅ **NO LOADING HANG** (fix applied)
- [ ] Loading time: < 3 seconds
- [ ] NO error dialogs
- [ ] Match displays with data
- [ ] Can see batsmen, bowler, score

**⚠️ CRITICAL**: If loading hangs > 5 seconds, **FIX DID NOT WORK**

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 5: Verify Restored Data (3 min)

### Steps
1. [ ] After match loads, compare with pre-save data
2. [ ] Check strike batsman name (should match)
3. [ ] Check non-strike batsman name (should match)
4. [ ] Check bowler name (should match)
5. [ ] Check total runs (should match)
6. [ ] Check wickets (should match)
7. [ ] Check overs (should match)

### Expected Result
- [ ] All data matches pre-save values
- [ ] No data corruption
- [ ] Exact same state as paused

| Data | Before Save | After Resume | ✅/❌ |
|------|-----------|-------------|------|
| Batsman 1 | | | |
| Batsman 2 | | | |
| Bowler | | | |
| Runs | | | |
| Wickets | | | |
| Overs | | | |

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 6: Test Buttons After Resume (2 min)

### Steps
1. [ ] Tap "4 runs" button
2. [ ] Verify score updates
3. [ ] Tap "Wicket" button
4. [ ] Verify wicket dialog appears
5. [ ] Test 1-2 more buttons

### Expected Result
- [ ] All buttons responsive
- [ ] Scoring works correctly
- [ ] Wicket dialog appears
- [ ] No crashes or errors

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 7: Continue Playing (2 min)

### Steps
1. [ ] Add a few more overs to match
2. [ ] Score some runs
3. [ ] Complete the current over
4. [ ] Verify bowler selection dialog

### Expected Result
- [ ] Match continues normally
- [ ] Scoring works
- [ ] Over completion triggers dialog
- [ ] No freezing or lag

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 8: Save Again (1 min)

### Steps
1. [ ] Tap back button
2. [ ] Select "Save & Exit" again
3. [ ] Go to History
4. [ ] Verify score updated in paused section

### Expected Result
- [ ] Can save again
- [ ] Only one entry for match (not duplicated)
- [ ] Score updated to new value

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 9: Discard Match (1 min)

### Steps
1. [ ] Start another match
2. [ ] Play a few overs
3. [ ] Tap back → Select "Discard & Exit"
4. [ ] Go to History
5. [ ] Verify match NOT in paused section

### Expected Result
- [ ] Match discarded without saving
- [ ] Does not appear in History
- [ ] Returns to Team Page

**Status**: ✅ PASS / ❌ FAIL

---

## 🧪 Test 10: Multiple Paused Matches (2 min)

### Steps
1. [ ] Save 2-3 different matches
2. [ ] Each with different progress
3. [ ] Go to History
4. [ ] Verify all appear in paused section
5. [ ] Resume each one to verify data correct

### Expected Result
- [ ] All paused matches appear
- [ ] Each with correct team/score
- [ ] Each resumes with correct data
- [ ] No data mixing between matches

**Status**: ✅ PASS / ❌ FAIL

---

## 📊 Test Summary

| Test | Status | Notes |
|------|--------|-------|
| Test 1: Save Match | ✅/❌ | |
| Test 2: Confirm Save | ✅/❌ | |
| Test 3: Check History | ✅/❌ | |
| Test 4: Resume Match | ✅/❌ | 🚨 **CRITICAL** |
| Test 5: Verify Data | ✅/❌ | |
| Test 6: Test Buttons | ✅/❌ | |
| Test 7: Continue Playing | ✅/❌ | |
| Test 8: Save Again | ✅/❌ | |
| Test 9: Discard Match | ✅/❌ | |
| Test 10: Multiple Matches | ✅/❌ | |

**Total Tests**: 10
**Passed**: ___/10
**Failed**: ___/10

---

## 🎯 Critical Issues to Check

### Issue 1: Loading Screen Hang ⚠️
- **What**: Match stuck on loading when resuming
- **How to Test**: Test 4 (Resume Match)
- **Expected**: Loading completes in <3 seconds
- **Fix Status**: ✅ Applied (JSON parsing added)
- **If Failed**: Check if fix compiled correctly

### Issue 2: Data Not Restored ⚠️
- **What**: Data doesn't match pre-save values
- **How to Test**: Test 5 (Verify Data)
- **Expected**: All fields match exactly
- **Fix Status**: ✅ Applied (JSON restore added)
- **If Failed**: Check pausedState JSON format

### Issue 3: Buttons Not Working ⚠️
- **What**: Can't score after resume
- **How to Test**: Test 6 (Test Buttons)
- **Expected**: All buttons responsive
- **Fix Status**: ✅ Should work
- **If Failed**: Check initialization complete

---

## 🔧 Troubleshooting

### If Test 4 Fails (Loading Hangs)
1. Check compilation: `flutter analyze`
2. Verify JSON import: Look for `import 'dart:convert'`
3. Check _resumeMatch() method has jsonDecode()
4. Rebuild: `flutter clean && flutter pub get && flutter run`

### If Test 5 Fails (Data Not Restored)
1. Check pausedState is being saved (in logs)
2. Verify JSON contains all required fields
3. Check JSON parsing in _resumeMatch()
4. Print debug: `print(stateMap)` to see parsed data

### If Test 6 Fails (Buttons Don't Work)
1. Check isInitializing is set to false
2. Verify _initializeMatch() completed
3. Check for error dialogs
4. Run Test 4 again to verify match loaded

### If Test 9 Fails (Multiple Issues)
1. Run each test individually first
2. Note which specific test fails
3. Reference troubleshooting above
4. Document issue with screenshot

---

## 📱 Device Specifications (Record)

**Device/Emulator**: _______________
**OS**: Android ____ / iOS ____
**Flutter Version**: _______________
**Build**: Debug / Release

---

## 📝 Notes & Observations

```
Test Session Notes:
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

Issues Found:
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

Recommendations:
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

---

## ✍️ Tester Sign-Off

**Tester Name**: _______________
**Date**: _______________
**Time**: _______________
**Build Number**: _______________

**Overall Result**:
- [ ] ✅ ALL TESTS PASSED
- [ ] ⚠️ SOME TESTS FAILED (Document below)
- [ ] ❌ CRITICAL ISSUES FOUND (Do not deploy)

**Issues Found**: _______________
**Recommendation**: Deploy / Investigate / Reject

---

## 📧 Next Steps

**If ALL TESTS PASS** ✅:
- Deploy to production
- Update release notes
- Announce feature to users

**If SOME TESTS FAIL** ⚠️:
- Document issues in detail
- Create bug tickets
- Schedule fix and re-test

**If CRITICAL FAIL** ❌:
- Hold deployment
- Investigate root cause
- Apply fixes
- Full re-test required

---

**Testing Duration**: _____ minutes
**Completion Time**: _____:_____ (AM/PM)
**Status**: Ready / Pending / Failed

---

🎉 **Happy Testing!**

---
