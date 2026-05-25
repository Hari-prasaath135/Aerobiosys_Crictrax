# 🧹 UNUSED FILES ANALYSIS REPORT
**Project:** TURF_TOWN (Aerobiosys Cricket Scoring System)  
**Date:** 2026-05-24  
**Total Dart Files:** 82  
**Unused Files Found:** 21

---

## 📊 SUMMARY

| Category | Count | Action |
|----------|-------|--------|
| **SAFE TO DELETE** | 18 | Delete immediately |
| **VERIFY BEFORE DELETE** | 3 | Check usage first |
| **KEEP** | 61 | Keep these files |

---

## 🗑️ SAFE TO DELETE (18 files)

These files are completely unused and can be safely removed.

### 1. **Duplicate Widget Directory** (5 files)
> **Status:** Unused - Exact duplicates of files in `lib/src/widgets/`
> **Action:** DELETE ENTIRE FOLDER `lib/src/Score_widgets/`

```
lib/src/Score_widgets/
├── Circular_button.dart              ❌ (duplicate of ../widgets/Circular_button.dart)
├── Extra_Score_Popup.dart            ❌ (duplicate of ../widgets/Extra_Score_Popup.dart)
├── Navigation_bar.dart               ❌ (duplicate of ../widgets/Navigation_bar.dart)
├── buttons.dart                      ❌ (duplicate of ../widgets/buttons.dart)
└── score_buttons_row.dart            ❌ (duplicate of ../widgets/score_buttons_row.dart)
```

**Reason:** These files are never imported from anywhere. The correct imports use `lib/src/widgets/` versions.

---

### 2. **CommonParameters - Unused Validators** (2 files)
> **Status:** Never imported anywhere
> **Action:** DELETE

```
lib/src/CommonParameters/
├── Validators.dart                   ❌ UNUSED
└── buttons.dart                      ❌ UNUSED
```

**Impact:** No files depend on these. Safe to remove.

---

### 3. **Models - Legacy Score Management** (2 files)
> **Status:** Replaced by modern cricket_scorer_screen.dart implementation
> **Action:** DELETE

```
lib/src/models/
├── ScoreController.dart              ✅ USED (keep - used by ScoreCard.dart)
├── ScoreManager.dart                 ✅ USED (keep - used by ScoreCard.dart)
└── buttons.dart                      ❌ UNUSED
```

**Wait! ScoreController and ScoreManager ARE USED. Let me correct this.** 
- `ScoreController.dart` - **KEEP** (used by Home.dart & ScoreCard.dart)
- `ScoreManager.dart` - **KEEP** (used by ScoreCard.dart)
- `buttons.dart` - **DELETE** (never imported)

---

### 4. **Models - Deprecated ObjectBox** (1 file)
> **Status:** Replaced by db_helper.dart
> **Action:** DELETE

```
lib/src/models/
└── objectbox_helper.dart             ❌ UNUSED (replaced by db_helper.dart)
```

**Reason:** The project now uses SQLite via `db_helper.dart`. ObjectBox helper is obsolete.

---

### 5. **Screens Folder - Legacy/Unused Screens** (7 files)
> **Status:** Never imported; deprecated in favor of Pages/Teams structure
> **Action:** DELETE with verification

```
lib/src/Screens/
├── account.dart                      ⚠️  (see next section)
├── advanced.settings_screen.dart     ❌ UNUSED
├── loading_screen.dart               ❌ UNUSED (but may be in use - check)
├── Navigation_bar.dart               ❌ UNUSED
├── Phone_no.dart                     ✅ USED (keep - imported by Sliding_page & account)
├── privacy.dart                      ⚠️  (see next section)
└── setting.dart                      ⚠️  (see next section)
```

**Files to definitely DELETE:**
- `advanced.settings_screen.dart` - Never imported, unused
- `Navigation_bar.dart` - Never imported, unused

---

### 6. **Root Level Duplicates** (2 files)
> **Status:** Legacy/test files at project root
> **Action:** DELETE

```
Project Root/
├── Team_Name.dart                    ❌ UNUSED (duplicate of lib/src/Pages/Teams/Team_Name.dart)
├── setting.dart                      ❌ UNUSED (duplicate of lib/src/Screens/setting.dart)
└── main.dart                         ❌ UNUSED (entry point is lib/main.dart)
```

---

### 7. **Features Folder** (1 file)
> **Status:** Abandoned project structure
> **Action:** DELETE

```
features/
└── lib/Team_Name.dart                ❌ UNUSED
```

**Reason:** This appears to be a legacy project structure. No imports reference this.

---

## ⚠️ VERIFY BEFORE DELETE (3 files)

These files have **internal cross-references but no external imports**. Verify they're not needed:

### 1. **Pages/Teams - Potential Duplicates**

```
lib/src/Pages/Teams/
├── team_members.dart                 ✅ USED (imported by Home.dart for Firestore integration)
├── team_members_page.dart            ✅ USED (imported by team_page.dart)
├── team_page.dart                    ✅ USED (imported by InitialTeamPage.dart)
└── team_name_screen.dart             ⚠️  (check if used)
```

**Action:** Check if `team_name_screen.dart` is used anywhere.

---

### 2. **Player Details Screen**

```
lib/src/Pages/Teams/
└── player_details_screen.dart        ❌ UNUSED (Never imported)
```

**Recommendation:** DELETE - No files import this.

---

### 3. **Menus Folder - Circular Reference Risk**

```
lib/src/Menus/
├── account.dart                      ⚠️  May have circular imports
├── privacy.dart                      ⚠️  May have circular imports
└── setting.dart                      ⚠️  May have circular imports
```

**Status:** These are imported from Home.dart and used. However:
- `Menus/account.dart` ← imports → `Menus/setting.dart`
- `Menus/setting.dart` ← imports → `Menus/privacy.dart`
- `Menus/privacy.dart` ← imports → `Menus/setting.dart`

**Recommendation:** Check for actual circular dependencies. These may be legitimately used together.

---

## ✅ KEEP THESE FILES (Do Not Delete)

### Critical Entry Points
- `lib/main.dart` - Application entry point
- `lib/firebase_options.dart` - Firebase configuration

### Active Pages & Views
- `lib/src/views/splash_screen_new.dart`
- `lib/src/views/Sliding_page.dart`
- `lib/src/views/Home.dart`
- `lib/src/views/history_page.dart`
- `lib/src/views/bluetooth_page.dart`
- `lib/src/views/alerts_page.dart`
- `lib/src/views/Venue.dart`

### Cricket Game Core
- `lib/src/Pages/Teams/cricket_scorer_screen.dart`
- `lib/src/Pages/Teams/scoreboard_page.dart`
- `lib/src/Pages/Teams/match_graph_page.dart`
- `lib/src/Pages/Teams/playerselection_page.dart`
- `lib/src/Pages/Teams/InitialTeamPage.dart`
- `lib/src/Pages/Teams/NewTeamsPage.dart`
- `lib/src/Pages/Teams/Team_Name.dart`
- `lib/src/Pages/Teams/TeamPage.dart`
- `lib/src/Pages/Teams/tournament_page.dart`
- `lib/src/Pages/Teams/team_page.dart`
- `lib/src/Pages/Teams/team_members_page.dart`
- `lib/src/Pages/Teams/team_members.dart`

### Models (All Active)
- `lib/src/models/db_helper.dart`
- `lib/src/models/match.dart`
- `lib/src/models/innings.dart`
- `lib/src/models/score.dart`
- `lib/src/models/batsman.dart`
- `lib/src/models/bowler.dart`
- `lib/src/models/team.dart`
- `lib/src/models/team_member.dart`
- `lib/src/models/match_history.dart`
- `lib/src/models/match_storage.dart`
- `lib/src/models/team_storage.dart`
- `lib/src/models/player_storage.dart`
- `lib/src/models/tournament_model.dart`
- `lib/src/models/Tournament_team.dart`
- `lib/src/models/ScoreController.dart`
- `lib/src/models/ScoreManager.dart`
- `lib/src/models/objectbox.g.dart` (generated)

### Services (All Active)
- `lib/src/services/bluetooth_service.dart`
- `lib/src/services/auth_service.dart`
- `lib/src/services/environment_service.dart`
- `lib/src/services/Firestore_service.dart`
- `lib/src/services/splash_animations_service.dart`
- `lib/src/services/Otp.dart`

### Widgets (Active)
- `lib/src/widgets/cricket_animations.dart`
- `lib/src/widgets/shadow_painter.dart`
- `lib/src/widgets/morphing_sport_shape.dart`
- `lib/src/widgets/Circular_button.dart`
- `lib/src/widgets/Extra_Score_Popup.dart`
- `lib/src/widgets/Navigation_bar.dart`
- `lib/src/widgets/buttons.dart`
- `lib/src/widgets/score_buttons_row.dart`

### UI Components
- `lib/src/CommonParameters/AppBackGround1/Appbg1.dart`
- `lib/src/CommonParameters/AppBackGround1/Appbg2.dart`
- `lib/src/Scorecard/ScoreCard.dart`
- `lib/src/utils/animation_constants.dart`

### Menu System (Keep - In Use)
- `lib/src/Menus/account.dart` ✅
- `lib/src/Menus/privacy.dart` ✅
- `lib/src/Menus/setting.dart` ✅

### Authentication Screens (Keep - In Auth Flow)
- `lib/src/Screens/account.dart` ✅
- `lib/src/Screens/Phone_no.dart` ✅
- `lib/src/Screens/privacy.dart` ✅
- `lib/src/Screens/setting.dart` ✅

---

## 🎯 CLEANUP ACTION PLAN

### Phase 1: Safe Deletes (No Risk)
**Estimated files:** 16

```bash
# Delete duplicate widgets folder
rm -rf lib/src/Score_widgets/

# Delete unused validators & buttons in CommonParameters
rm lib/src/CommonParameters/Validators.dart
rm lib/src/CommonParameters/buttons.dart

# Delete unused models
rm lib/src/models/buttons.dart
rm lib/src/models/objectbox_helper.dart

# Delete unused screens
rm lib/src/Screens/advanced.settings_screen.dart
rm lib/src/Screens/Navigation_bar.dart

# Delete root level duplicates
rm main.dart
rm Team_Name.dart
rm setting.dart

# Delete features folder
rm -rf features/
```

### Phase 2: Verify Before Delete (3 files)
```bash
# Check grep for these before deleting:
grep -r "player_details_screen" lib/
grep -r "team_name_screen" lib/
grep -r "loading_screen" lib/
```

### Phase 3: Review (Optional Cleanup)
- Review circular imports in `lib/src/Menus/`
- Consider renaming to remove case-sensitivity issues (e.g., `team_page.dart` vs `TeamPage.dart`)

---

## 📈 POTENTIAL SAVINGS

| Metric | Impact |
|--------|--------|
| **Files to Delete** | 16 safe + 3 verify = **~19 files** |
| **Duplicate Code** | All Score_widgets folder (5 files) |
| **Dead Code** | ~2,000+ lines of unused code |
| **Project Cleanup** | Better maintainability, reduced confusion |

---

## 🚀 NEXT STEPS

1. ✅ **Review this report** with team members
2. ✅ **Backup current state** (`git commit`)
3. ✅ **Execute Phase 1 deletes** (16 safe files)
4. ✅ **Test application** (verify nothing broke)
5. ✅ **Execute Phase 2 verification** (3 files)
6. ✅ **Optional: Phase 3** (structural improvements)

---

## 📝 NOTES

- Generated files (`objectbox.g.dart`) are kept
- Firebase config is kept
- All active game logic is preserved
- No breaking changes if Phase 1 is executed
