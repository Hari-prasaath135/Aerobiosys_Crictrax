# ⚡ QUICK TEST GUIDE - Bluetooth Auto-Reconnect

**What to Test**: Bluetooth automatically reconnects after match ends

---

## 🚀 QUICK START (5 minutes)

### Before You Start
```bash
# 1. Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 2. Open logcat in another terminal
adb logcat | grep -E "flutter|FBP"

# 3. Ensure Bluetooth device is ON and available
```

### Test Flow (Fastest Path)
```
1. Start app
2. Go to Bluetooth page → Connect to LED device
3. Go to Home → Start Match
4. Quick match:
   - First innings: 20 runs in 2 overs (10 balls)
   - Target: 21 runs
   - Second innings: Score 21 runs
5. Tap "Finish" when done
6. Watch logcat for:
   - "LED clear complete, initiating auto-reconnect..."
   - "Auto-reconnect successful"
7. Navigate to Home
8. Check Bluetooth page → Should show "Connected" ✅
```

**Total Time**: ~3-5 minutes

---

## 📋 MINIMAL TEST CHECKLIST

```
What To Check              | Expected             | Status
---------------------------|----------------------|---------
Victory dialog appears      | Yes                 | [ ]
LED clears                  | Display goes black  | [ ]
Reconnect starts            | See in logcat       | [ ]
Reconnect succeeds          | See "successful"    | [ ]
Auto-navigate to Home       | After ~3 sec        | [ ]
Bluetooth shows Connected   | Yes                 | [ ]
Can start new match         | Yes, no reconnect   | [ ]
```

---

## 🔍 LOGCAT WATCH POINTS

Look for these exact messages (copy-paste to find):

```
"🧹 Clearing LED display"
↓
"✅ LED display cleared"
↓
"🔄 LED clear complete, initiating auto-reconnect..."
↓
"🔄 BleManagerService: Attempting auto-reconnect..."
↓
"✅ Auto-reconnect successful" ← SUCCESS!
```

---

## ⚡ If Something Goes Wrong

### No Reconnect Message?
- Check if Bluetooth was actually connected before
- Check LED clearing actually happened
- Look for errors in logcat starting with "❌"

### Reconnect Failed?
- Device might be unreachable
- Try manual reconnect (should still work)
- Check device is ON and in range

### Stuck on Victory Dialog?
- This is separate from reconnect
- Close app and restart
- Try again

---

## 📊 Success Criteria

✅ **Minimum**: Reconnect message appears in logcat
✅ **Good**: Reconnect succeeds + Bluetooth shows Connected
✅ **Excellent**: Can do 3+ matches without manual reconnect

---

**That's it!** If you see "Auto-reconnect successful", the feature works! 🎉

