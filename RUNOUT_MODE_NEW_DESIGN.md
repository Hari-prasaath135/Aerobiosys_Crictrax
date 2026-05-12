# Runout Mode - New Design Plan

**Status**: 🎨 **DESIGN PHASE**
**Date**: February 10, 2026

---

## User Requirements (FINAL)

### ✅ Clarified Requirements
1. **Blur**: Only background (NOT buttons)
2. **Highlight**: Only scoring buttons (1,2,4,6,0,Wicket, Extras, Undo)
3. **Button Style**: Color change + glow effect
4. **Background Effect**: Blur everything EXCEPT button area
5. **Dismissal**: Both methods work (tap blur OR press score button)

---

## End-to-End Flow

```
User taps RO (Runout) button
    ↓
_isRunoutModeActive = true
    ↓
1. ALL interactive buttons get: Color change + glow
2. Background gets: Gaussian blur + dark overlay
3. Button area stays: Clear, bright, fully visible
    ↓
User options:
    ↓
    A) Tap any run score button (1/2/4/6/0)
       → addRuns() dismisses blur
       → All effects removed
       → Continue scoring

    B) Tap Wicket button
       → addWicket() dismisses blur
       → All effects removed
       → Dialog appears

    C) Tap back button
       → _showLeaveMatchDialog() dismisses blur
       → All effects removed
       → Dialog appears

    D) Tap blurred background
       → GestureDetector dismisses blur
       → All effects removed
       → Runout mode stays on (can score)
```

---

## Architecture Changes

### Current (OLD - To Remove)
```dart
_isRunoutModeActive = false;  // ← Keep this
// OLD: Full-screen blur overlay
// OLD: Scorecard border highlighting
// OLD: StateColor tint
```

### New Design
```dart
_isRunoutModeActive = false;  // ← Keep this
// NEW: Stack with two parts:
//   1. Background blur layer (above content, below buttons)
//   2. Interactive button area (stays clear)
```

---

## Implementation Strategy

### Phase 1: Remove Old Implementation
**Remove from cricket_scorer_screen.dart**:
- Old blur overlay Positioned widget (lines ~2976-3003)
- Old scorecard highlighting in decoration (lines ~2300-2318)
- Keep: `_isRunoutModeActive` variable
- Keep: Button activation logic in `_buildRunoutButton()`
- Keep: Dismissal triggers in `addRuns()`, `_showLeaveMatchDialog()`

### Phase 2: Identify Button Area
**Calculate button area bounds**:
- Buttons are in bottom section of screen
- Find all button containers in build method
- Create invisible layer that covers button area
- This prevents blur from affecting button zone

### Phase 3: Create Smart Blur Overlay
**New blur structure**:
```dart
// Create blur that avoids button area
Stack(
  children: [
    // Original content (scorecard, batsmen, etc.)
    ...[existing content]...,

    // NEW: Smart blur overlay
    if (_isRunoutModeActive)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: buttonAreaHeight,  // ← Stop before buttons
        child: Container with BackdropFilter
      ),

    // Button area stays CLEAR (no blur, no overlay)
  ]
)
```

### Phase 4: Highlight Buttons
**Add glow to buttons dynamically**:
```dart
// In _buildRunButton(), _buildWicketButton(), etc.
decoration: BoxDecoration(
  // ... existing styles ...
  boxShadow: [
    if (_isRunoutModeActive)
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.8),
        blurRadius: 15,  // Glowing effect
        spreadRadius: 3,
      ),
  ],
),
// Color change: Brighten button colors
color: _isRunoutModeActive
  ? buttonColor.withValues(alpha: 0.9)
  : buttonColor,
```

### Phase 5: Add Dismissal Points
**Ensure all dismissal methods work**:
- `addRuns()`: Already dismisses ✓
- `addWicket()`: Already dismisses ✓
- `_showLeaveMatchDialog()`: Already dismisses ✓
- Tap blur: Add GestureDetector to blur layer ✓

---

## Technical Implementation Details

### State Variable (Keep Existing)
```dart
bool _isRunoutModeActive = false;
```

### Calculate Button Area Height
```dart
// In build method, calculate where buttons start
final buttonAreaHeight = MediaQuery.of(context).size.height * 0.25;
// Adjust percentage based on actual button positions
```

### New Blur Overlay Widget
```dart
if (_isRunoutModeActive)
  Positioned(
    top: 0,
    left: 0,
    right: 0,
    bottom: buttonAreaHeight,
    child: GestureDetector(
      onTap: () => setState(() => _isRunoutModeActive = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
          ),
        ),
      ),
    ),
  ),
```

### Button Highlight Logic
**Add to each button's decoration**:
```dart
boxShadow: [
  if (_isRunoutModeActive)
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.7),
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(0, 0),
    ),
  // Keep existing shadow
  BoxShadow(...)
],
```

---

## Files to Modify

**Only 1 file**: `lib/src/Pages/Teams/cricket_scorer_screen.dart`

### Changes Required
1. **Remove** (lines ~2976-3003): Old blur overlay Positioned widget
2. **Remove** (lines ~2300-2318): Old scorecard highlighting decoration
3. **Add** (in build method): New smart blur overlay before button area
4. **Modify** (_buildRunButton): Add glow shadow when `_isRunoutModeActive`
5. **Modify** (_buildWicketButton): Add glow shadow when `_isRunoutModeActive`
6. **Modify** (_buildExtrasOptions buttons): Add glow shadow when `_isRunoutModeActive`
7. **Modify** (_buildUndoButton): Add glow shadow when `_isRunoutModeActive`

---

## Visual Result

### When Runout Mode OFF
```
┌─────────────────────────────────┐
│   Header (Clear)                │
├─────────────────────────────────┤
│   Scorecard (Normal colors)     │
│   Batsmen info (Normal colors)  │
│   Bowler info (Normal colors)   │
├─────────────────────────────────┤
│  [4] [3] [1] [0] [2] [5] [6]   │
│  Normal button colors           │
│  [Wicket] [Extras] [Undo]       │
└─────────────────────────────────┘
```

### When Runout Mode ON
```
┌─────────────────────────────────┐
│   Header (Blurred + dark)       │ ← Blur effect
├─────────────────────────────────┤
│   Scorecard (Blurred + dark)    │ ← Blur effect
│   Batsmen info (Blurred + dark) │ ← Blur effect
│   Bowler info (Blurred + dark)  │ ← Blur effect
├─────────────────────────────────┤  ← Blur ends
│  [4✨][3✨][1✨][0✨][2✨][5✨][6✨] │ ← BRIGHT + GLOW
│  ✨ Glowing buttons (clear)     │ ← BRIGHT + GLOW
│  [W✨] [E✨] [U✨]              │ ← BRIGHT + GLOW
└─────────────────────────────────┘

✨ = Glow effect (white shadow)
```

---

## Testing Checklist

### Visual Verification
- [ ] Tap runout button → buttons get glow + color change
- [ ] Tap runout button → background above buttons is blurred
- [ ] Button area stays clear (no blur)
- [ ] All buttons remain fully clickable
- [ ] Tap score button → blur disappears, glow removed
- [ ] Tap back button → blur disappears, glow removed
- [ ] Tap blurred area → blur disappears, glow stays (can still score)
- [ ] Tap runout again → blur/glow returns

### Functional Verification
- [ ] Scoring works while blur is active
- [ ] Back button works while blur is active
- [ ] Multiple runout mode activations work
- [ ] No UI glitches or artifacts

---

## Success Criteria

✅ **Final Design Goals**:
1. Background blurred (not buttons)
2. Only buttons highlighted (not scorecard)
3. Color change + glow on buttons
4. Button area stays fully clear and clickable
5. Dismissal works (tap blur OR score button)
6. 0 compilation errors
7. Smooth, professional appearance

---

## Next Steps

1. ✅ Requirements clarified
2. ⏳ Remove old implementation (lines 2976-3003, 2300-2318)
3. ⏳ Implement new blur overlay (smart positioning)
4. ⏳ Add button highlighting (all interactive buttons)
5. ⏳ Test end-to-end flow
6. ⏳ Verify compilation

---

**Status**: Ready for implementation
**Difficulty**: Medium (UI positioning + conditional styling)
**Estimated Time**: 30-45 minutes

---
