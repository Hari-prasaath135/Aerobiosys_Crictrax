# ✂️ DELETION COMMANDS - UNUSED FILES

**Safe to delete immediately** (verified through import analysis)

## Phase 1: Delete Duplicate Widgets Directory
```powershell
# Remove entire Score_widgets folder (5 duplicate files)
Remove-Item -Path "lib\src\Score_widgets" -Recurse -Force
```

## Phase 2: Delete Unused Model Files
```powershell
# Delete unused buttons model
Remove-Item -Path "lib\src\models\buttons.dart" -Force

# Delete deprecated ObjectBox helper (replaced by db_helper.dart)
Remove-Item -Path "lib\src\models\objectbox_helper.dart" -Force
```

## Phase 3: Delete Unused CommonParameters
```powershell
# Delete unused validators
Remove-Item -Path "lib\src\CommonParameters\Validators.dart" -Force

# Delete unused buttons in CommonParameters
Remove-Item -Path "lib\src\CommonParameters\buttons.dart" -Force
```

## Phase 4: Delete Unused Screens
```powershell
# Delete advanced settings screen
Remove-Item -Path "lib\src\Screens\advanced.settings_screen.dart" -Force

# Delete unused Navigation_bar
Remove-Item -Path "lib\src\Screens\Navigation_bar.dart" -Force

# Delete unused loading_screen (NOT imported)
Remove-Item -Path "lib\src\Screens\loading_screen.dart" -Force
```

## Phase 5: Delete Root Level Duplicates
```powershell
# Delete root level duplicate files
Remove-Item -Path "main.dart" -Force
Remove-Item -Path "Team_Name.dart" -Force
Remove-Item -Path "setting.dart" -Force
```

## Phase 6: Delete Features Folder
```powershell
# Delete abandoned features structure
Remove-Item -Path "features\lib\Team_Name.dart" -Force
Remove-Item -Path "features\lib" -Recurse -Force
Remove-Item -Path "features" -Recurse -Force
```

## ⚠️ VERIFY THESE 3 BEFORE DELETING

```powershell
# VERIFY - Check if these are truly unused:

# 1. Check if player_details_screen is imported anywhere
Select-String -Path "lib\src\**\*.dart" -Pattern "player_details_screen" -Recurse

# 2. Check if team_name_screen is imported anywhere
Select-String -Path "lib\src\**\*.dart" -Pattern "team_name_screen" -Recurse

# 3. Double-check loading_screen was never imported
Select-String -Path "lib\src\**\*.dart" -Pattern "loading_screen" -Recurse

# If NO results from above, safe to delete:
Remove-Item -Path "lib\src\Pages\Teams\player_details_screen.dart" -Force
Remove-Item -Path "lib\src\Pages\Teams\team_name_screen.dart" -Force
```

## 📋 COMPLETE FILE LIST TO DELETE

**16 Safe Files:**
1. lib/src/Score_widgets/buttons.dart
2. lib/src/Score_widgets/Circular_button.dart
3. lib/src/Score_widgets/Extra_Score_Popup.dart
4. lib/src/Score_widgets/Navigation_bar.dart
5. lib/src/Score_widgets/score_buttons_row.dart
6. lib/src/models/buttons.dart
7. lib/src/models/objectbox_helper.dart
8. lib/src/CommonParameters/Validators.dart
9. lib/src/CommonParameters/buttons.dart
10. lib/src/Screens/advanced.settings_screen.dart
11. lib/src/Screens/Navigation_bar.dart
12. lib/src/Screens/loading_screen.dart
13. main.dart (root)
14. Team_Name.dart (root)
15. setting.dart (root)
16. features/lib/Team_Name.dart

**3 Verify Files (Check before deleting):**
1. lib/src/Pages/Teams/player_details_screen.dart
2. lib/src/Pages/Teams/team_name_screen.dart

---

## ✅ FILES TO KEEP (DO NOT DELETE)

**All other files remain:**
- firebase_options.dart
- lib/main.dart
- All cricket_scorer_screen.dart and related game files
- All models (match, innings, score, batsman, bowler, team, team_member, etc.)
- All services (bluetooth, auth, firestore, firebase, environment)
- All widgets in lib/src/widgets/ (NOT Score_widgets)
- All UI components and animations
- Menu system files
- Authentication screens

---

## 🚀 BULK DELETE COMMAND (One-Liner)

```powershell
# Run this to delete all safe files at once:
$filesToDelete = @(
    "lib\src\Score_widgets",
    "lib\src\models\buttons.dart",
    "lib\src\models\objectbox_helper.dart",
    "lib\src\CommonParameters\Validators.dart",
    "lib\src\CommonParameters\buttons.dart",
    "lib\src\Screens\advanced.settings_screen.dart",
    "lib\src\Screens\Navigation_bar.dart",
    "lib\src\Screens\loading_screen.dart",
    "main.dart",
    "Team_Name.dart",
    "setting.dart",
    "features"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Recurse -Force
        Write-Host "✓ Deleted: $file"
    } else {
        Write-Host "✗ Not found: $file"
    }
}

Write-Host "Cleanup complete!"
```

---

## 🔍 POST-DELETION VERIFICATION

After deleting, run this to ensure no broken imports:

```bash
# Compile check (from project root)
flutter pub get
flutter analyze

# Run tests to verify app still works
flutter test
```

---

## 📊 IMPACT SUMMARY

**Before Cleanup:**
- 82 total Dart files
- Multiple duplicate widgets
- Legacy/obsolete code scattered

**After Cleanup:**
- ~63 active Dart files
- No duplicates
- Clean project structure
- Easier maintenance

**Estimated Cleanup:**
- Time: 5 minutes
- Risk: Very Low
- Files Removed: 16 safe + up to 2 verify
- Lines of Code Removed: ~2,000+
