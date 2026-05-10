# ⚡ BLUETOOTH PERSISTENCE - QUICK TEST GUIDE

**What to Test**: Connection persists across page navigations and device state changes are detected immediately.

---

## 🚀 QUICK START (10 minutes)

### Before Testing
```bash
# 1. Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 2. Open logcat (optional but helpful)
adb logcat | grep -E "flutter|BleManagerService"

# 3. Ensure Bluetooth device is ON and available
```

---

## 📋 5-MINUTE TEST

### Test 1: Connection Persistence (MOST IMPORTANT)
```
1. Open app → Tap Bluetooth icon on Home page
2. Tap "Start Scanning"
3. Select your Bluetooth device (e.g., ESP32)
4. Confirm: Shows "Connected to [device]" ✅
5. Tap "Home" button (navigate away)
6. Wait 3-5 seconds
7. Tap Bluetooth icon again (navigate back)
8. IMPORTANT: Should STILL show "Connected to [device]" ✅

Expected: Connection persists!
If shows "Not Connected": Connection persistence not working ❌
```

### Test 2: Immediate Disconnection Detection (2 minutes)
```
1. Connected device on Bluetooth page
2. Turn OFF the Bluetooth device (power down)
3. Watch the UI carefully
4. Within 1-2 seconds: Should change to "Not Connected" ✅

Expected: Quick update (not waiting 30 seconds)
If no update after 5 seconds: Detection not working ❌
```

### Test 3: Navigation Loop (2 minutes)
```
1. Connect to device
2. Tap: Home → Cricket Scorer → Bluetooth
3. Should show: "Connected to [device]" ✅
4. Tap: Settings → Home → Bluetooth
5. Should STILL show: "Connected to [device]" ✅

Expected: Connection survives all navigation
If shows "Not Connected" at any point: Test fails ❌
```

---

## 🎯 FULL TEST SUITE (15 minutes)

### Test 1: Connection Persistence
✅ See Quick Start Test 1 above

### Test 2: Disconnection Detection
✅ See Quick Start Test 2 above

### Test 3: Multiple Navigations
```
1. Connect to device
2. Cycle 5 times:
   - Navigate away (Home, Cricket, Settings)
   - Return to Bluetooth page
   - Verify shows "Connected" each time ✅
```

### Test 4: Auto-Reconnect Integration
```
1. Connect to device on Bluetooth page
2. Stay on Bluetooth page
3. Start a quick match:
   - Set target 20 runs
   - Score 20 runs in second innings
   - Hit "Finish" button
4. Observe Bluetooth page during match completion
5. After match: Should show "Connected" ✅
6. Check if reconnection happened (logcat):
   "Auto-reconnect successful" ✅
```

### Test 5: Manual Disconnect
```
1. Connected device
2. Tap "Disconnect" button
3. Should show "Not Connected" ✅
4. Button changes to "Start Scanning" ✅
5. Can reconnect by scanning and selecting ✅
```

---

## 📊 SUCCESS CRITERIA

| Test | Expected | Result |
|------|----------|--------|
| Connection persists | Still "Connected" after navigation | [ ] ✅ |
| Disconnection immediate | Updates in <2 seconds | [ ] ✅ |
| Navigation loop | Survives 5 cycles | [ ] ✅ |
| Auto-reconnect | Successful after match | [ ] ✅ |
| Manual disconnect | Works immediately | [ ] ✅ |

---

## 🔍 LOGCAT WATCH POINTS (Optional)

Look for these messages to confirm implementation working:

### Connection Established
```
🔗 BleManagerService: Connection state changed to BluetoothConnectionState.connected
✅ BleManagerService: Initialized with [Device Name]
```

### Device Disconnected
```
🔗 BleManagerService: Connection state changed to BluetoothConnectionState.disconnected
❌ BleManagerService: Device disconnected
```

### Auto-Reconnect
```
🔄 BleManagerService: Attempting auto-reconnect...
✅ BleManagerService: Auto-reconnect successful
🟢 Bluetooth reconnected (green status)
```

---

## ⚠️ TROUBLESHOOTING

### Connection Not Persisting?
- Check: Is Bluetooth page being kept in memory?
- Try: Multiple navigate cycles (3-4 times)
- Look for: `🔗 BleManagerService` messages in logcat

### Disconnection Takes Too Long?
- Expected: <2 seconds
- If taking >5 seconds: May be device-specific
- Try: Different Bluetooth device if available

### Auto-Reconnect Not Showing?
- Check: Did match actually complete?
- Look for: "Auto-reconnect successful" in logcat
- Note: Reconnect happens in background - may not see UI change if on different page

### Device Not Connecting?
- Verify: Device is ON and in range
- Try: Forget device and reconnect
- Check: Bluetooth permissions granted

---

## ✅ PASSING CRITERIA

**MUST PASS**:
- ✅ Connection persists across page navigations
- ✅ Disconnection detected within 1-2 seconds
- ✅ Works like native mobile Bluetooth

**NICE TO HAVE**:
- ✅ Auto-reconnect updates UI in real-time
- ✅ Logcat shows connection state changes

---

## 📱 Device Setup

### Android Device
```
1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect to PC via USB
4. Allow USB debugging prompt on device
```

### Bluetooth Device (ESP32 or similar)
```
1. Power ON Bluetooth device
2. Ensure it's in pairing mode
3. Device should appear when scanning
```

---

## 🎯 TEST RESULT SUMMARY

**Test Name** | **Status** | **Notes**
---|---|---
Connection Persistence | [ ] Pass | Should show "Connected" after returning to page
Disconnection Detection | [ ] Pass | UI should update within 1-2 seconds
Navigation Loop | [ ] Pass | Survives 5 navigate/return cycles
Auto-Reconnect | [ ] Pass | Works after match completion
Manual Disconnect | [ ] Pass | Disconnect button works immediately

---

**That's it!** If all tests pass, the feature is working correctly! 🎉

Run this on your Android device and report results:
- ✅ What worked
- ❌ What didn't work
- ⚠️ Any unexpected behavior

The most important test is **Connection Persistence** - if that passes, the core feature is working!
