import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/team.dart';

// Renamed to avoid conflict with flutter_blue_plus BluetoothService
class BleManagerService {
  // Singleton pattern
  static final BleManagerService _instance = BleManagerService._internal();
  factory BleManagerService() => _instance;
  BleManagerService._internal();

  // Connection state
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _autoUpdateTimer;
  
  // BLE Configuration
  static const int MAX_BLE_CHUNK_SIZE = 200;
  static const Duration AUTO_REFRESH_INTERVAL = Duration(seconds: 3);
  static const Duration CHUNK_DELAY = Duration(milliseconds: 50);
  
  // Callbacks for UI updates
  Function(String message, Color color)? onStatusUpdate;
  VoidCallback? onDisconnected;
  
  // Getters
  bool get isConnected => _connectedDevice != null && _writeCharacteristic != null;
  bool get isAutoRefreshActive => _autoUpdateTimer != null && _autoUpdateTimer!.isActive;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  String get deviceName => _connectedDevice?.platformName ?? 'Unknown Device';

  /// Initialize the service with connected device and characteristics
  void initialize({
    required BluetoothDevice device,
    required BluetoothCharacteristic writeCharacteristic,
    BluetoothCharacteristic? readCharacteristic,
    Function(String, Color)? statusCallback,
    VoidCallback? disconnectCallback,
  }) {
    _connectionSubscription?.cancel();
    _autoUpdateTimer?.cancel();

    _connectedDevice = device;
    _writeCharacteristic = writeCharacteristic;
    _readCharacteristic = readCharacteristic;
    onStatusUpdate = statusCallback;
    onDisconnected = disconnectCallback;

    // 🔥 NEW: Listen to device connection state changes for persistent connection tracking
    // This ensures the UI always reflects the actual device connection state
    _connectionSubscription = device.connectionState.listen((state) {
      debugPrint('🔗 BleManagerService: Connection state changed to $state');

      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnection();
        onDisconnected?.call();
      } else if (state == BluetoothConnectionState.connected) {
        _notifyStatus('Bluetooth connected', Colors.green);
      }
    });

    if (_readCharacteristic != null &&
        _readCharacteristic!.properties.notify) {
      _setupReadNotifications();
    }

    debugPrint('✅ BleManagerService: Initialized with ${device.platformName}');
    _notifyStatus('Bluetooth service ready', Colors.green);
  }

  Future<void> _setupReadNotifications() async {
    if (_readCharacteristic == null) return;
    
    try {
      await _readCharacteristic!.setNotifyValue(true);
      _readCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          final data = utf8.decode(value);
          debugPrint('📥 BleManagerService received: $data');
          _handleIncomingData(data);
        }
      });
      debugPrint('✅ BleManagerService: Read notifications enabled');
    } catch (e) {
      debugPrint('⚠️ BleManagerService: Could not enable notifications: $e');
    }
  }

  void _handleIncomingData(String data) {
    try {
      final jsonData = json.decode(data);
      
      if (jsonData['type'] == 'ACK') {
        debugPrint('✅ ESP32 acknowledged: ${jsonData['message']}');
      } else if (jsonData['type'] == 'ERROR') {
        debugPrint('❌ ESP32 error: ${jsonData['error']}');
        _notifyStatus('ESP32 error: ${jsonData['error']}', Colors.red);
      } else if (jsonData['type'] == 'STATUS') {
        debugPrint('ℹ️ ESP32 status: ${jsonData['status']}');
      }
    } catch (e) {
      debugPrint('📥 ESP32 message: $data');
    }
  }

  void _handleDisconnection() {
    debugPrint('❌ BleManagerService: Device disconnected');
    _autoUpdateTimer?.cancel();
    _connectionSubscription?.cancel();
    
    final wasConnected = _connectedDevice != null;
    
    _connectedDevice = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
    
    if (wasConnected) {
      _notifyStatus('Bluetooth device disconnected', Colors.orange);
      onDisconnected?.call();
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔌 BleManagerService: Disconnecting...');

    _autoUpdateTimer?.cancel();
    _connectionSubscription?.cancel();

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        debugPrint('⚠️ BleManagerService: Error during disconnect: $e');
      }
    }

    _connectedDevice = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;

    _notifyStatus('Bluetooth disconnected', Colors.orange);
  }

  /// 🔥 NEW: Auto-reconnect to the last connected device
  /// Used after match completion to reset and reconnect Bluetooth silently
  Future<void> autoReconnect() async {
    debugPrint('🔄 BleManagerService: Attempting auto-reconnect...');

    // Can't reconnect without a previous device
    if (_connectedDevice == null) {
      debugPrint('⚠️ BleManagerService: No previous device to reconnect to');
      return;
    }

    final deviceToReconnect = _connectedDevice!;

    try {
      // First, ensure completely disconnected
      try {
        await deviceToReconnect.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('ℹ️ BleManagerService: Device already disconnected');
      }

      // Attempt reconnection
      await deviceToReconnect.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Verify connection state
      final connectionState = await deviceToReconnect.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception('Device not in connected state after reconnect');
      }

      _connectedDevice = deviceToReconnect;

      // Discover services again
      final services = await deviceToReconnect.discoverServices();
      debugPrint('🔄 Services rediscovered: ${services.length}');

      // Re-find characteristics
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          final charUuidStr = characteristic.uuid.toString().toUpperCase();

          // Find write characteristic (1234)
          if (charUuidStr.contains("1234")) {
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              _writeCharacteristic = characteristic;
              debugPrint('✅ Write characteristic re-found');
            }
          }

          // Find read characteristic (5678)
          if (charUuidStr.contains("5678")) {
            if (characteristic.properties.read || characteristic.properties.notify) {
              _readCharacteristic = characteristic;
              debugPrint('✅ Read characteristic re-found');
            }
          }
        }
      }

      // Re-setup notifications if available
      if (_readCharacteristic != null && _readCharacteristic!.properties.notify) {
        await _setupReadNotifications();
      }

      debugPrint('✅ BleManagerService: Auto-reconnect successful');
      _notifyStatus('Bluetooth reconnected', Colors.green);

    } catch (e) {
      debugPrint('❌ BleManagerService: Auto-reconnect failed: $e');
      _handleDisconnection();
    }
  }

  Future<bool> sendMatchUpdate() async {
    if (!isConnected) {
      debugPrint('⚠️ BleManagerService: No device connected');
      return false;
    }

    try {
      final matches = Match.getAll();
      if (matches.isEmpty) {
        debugPrint('⚠️ BleManagerService: No matches found');
        await _sendCommand('NO_MATCH_DATA');
        return false;
      }

      final currentMatch = matches.last;
      final currentInnings = Innings.getSecondInnings(currentMatch.matchId) ??
                             Innings.getFirstInnings(currentMatch.matchId);
      
      if (currentInnings == null) {
        debugPrint('⚠️ BleManagerService: No innings found');
        await _sendCommand('NO_INNINGS_DATA');
        return false;
      }

      final currentScore = Score.getByInningsId(currentInnings.inningsId);
      if (currentScore == null) {
        debugPrint('⚠️ BleManagerService: No score found');
        await _sendCommand('NO_SCORE_DATA');
        return false;
      }

      final battingTeam = Team.getById(currentInnings.battingTeamId);
      final bowlingTeam = Team.getById(currentInnings.bowlingTeamId);
      
      final Map<String, dynamic> scorecardData = {
        'type': 'SCORE',
        'matchId': currentMatch.matchId,
        'inningsNum': currentInnings.inningsNumber,
        'bat': battingTeam?.teamName ?? 'Team A',
        'bowl': bowlingTeam?.teamName ?? 'Team B',
        'runs': currentScore.totalRuns,
        'wkts': currentScore.wickets,
        'ovs': double.parse(currentScore.overs.toStringAsFixed(1)),
        'crr': double.parse(currentScore.crr.toStringAsFixed(2)),
        'hasTgt': currentInnings.hasValidTarget,
        'tgt': currentInnings.hasValidTarget ? currentInnings.targetRuns : 0,
        'need': currentInnings.hasValidTarget 
            ? (currentInnings.targetRuns - currentScore.totalRuns) 
            : 0,
        'ext': currentScore.totalExtras,
        'totalOvs': currentMatch.overs,
        'done': currentInnings.isCompleted,
      };

      String jsonData = json.encode(scorecardData);
      await _sendDataInChunks(jsonData);

      debugPrint('📤 BleManagerService: Sent ${currentScore.totalRuns}/${currentScore.wickets} (${currentScore.overs})');
      return true;
      
    } catch (e) {
      debugPrint('❌ BleManagerService error: $e');
      _notifyStatus('Bluetooth send error', Colors.red);
      return false;
    }
  }

  /// Send raw commands directly without JSON encoding (for LED display)
/// Send raw commands directly without JSON encoding (for LED display)
Future<bool> sendRawCommands(List<String> commands) async {
  if (!isConnected || _writeCharacteristic == null) {
    debugPrint('⚠️ Cannot send commands - not connected');
    return false;
  }

  try {
    debugPrint('📤 Sending ${commands.length} raw commands to LED display...');
    int successCount = 0;
    
    for (int i = 0; i < commands.length; i++) {
      String command = commands[i];
      
      // Add newline if not present
      if (!command.endsWith('\n')) {
        command = '$command\n';
      }
      
      final bytes = utf8.encode(command);
      
      // Send command
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      successCount++;
      
      // Small delay between commands for stability
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Progress logging
      if ((i + 1) % 5 == 0 || (i + 1) == commands.length) {
        debugPrint('📶 Progress: ${i + 1}/${commands.length} commands sent');
      }
    }
    
    debugPrint('✅ Successfully sent $successCount/${commands.length} commands');
    // REMOVED: _notifyStatus('LED display updated', Colors.green);
    return true;
    
  } catch (e) {
    debugPrint('❌ Error sending raw commands: $e');
    _notifyStatus('Failed to update LED display', Colors.red);
    return false;
  }
}

/// Send a single raw command
Future<bool> sendRawCommand(String command) async {
  if (!isConnected || _writeCharacteristic == null) {
    debugPrint('⚠️ Cannot send command - not connected');
    return false;
  }

  try {
    // Add newline if not present
    if (!command.endsWith('\n')) {
      command = '$command\n';
    }
    
    final bytes = utf8.encode(command);
    await _writeCharacteristic!.write(bytes, withoutResponse: false);
    
    debugPrint('📤 Sent: $command');
    return true;
    
  } catch (e) {
    debugPrint('❌ Error sending command: $e');
    return false;
  }
}

  Future<bool> sendAnimation(String animationType) async {
    if (!isConnected) {
      debugPrint('⚠️ BleManagerService: Cannot send animation - not connected');
      return false;
    }
    
    try {
      await _sendCommand(animationType);
      debugPrint('🎬 BleManagerService: Sent animation: $animationType');
      return true;
    } catch (e) {
      debugPrint('❌ BleManagerService animation error: $e');
      return false;
    }
  }

  void startAutoRefresh({Duration? interval}) {
    if (!isConnected) {
      debugPrint('⚠️ BleManagerService: Cannot start auto-refresh - not connected');
      return;
    }
    
    _autoUpdateTimer?.cancel();
    final refreshInterval = interval ?? AUTO_REFRESH_INTERVAL;
    
    _autoUpdateTimer = Timer.periodic(refreshInterval, (_) {
      sendMatchUpdate();
    });
    
    debugPrint('🔄 BleManagerService: Auto-refresh started (${refreshInterval.inSeconds}s)');
    _notifyStatus('Auto-refresh enabled', Colors.blue);
  }

  void stopAutoRefresh() {
    if (_autoUpdateTimer != null && _autoUpdateTimer!.isActive) {
      _autoUpdateTimer!.cancel();
      debugPrint('⏸️ BleManagerService: Auto-refresh stopped');
      _notifyStatus('Auto-refresh disabled', Colors.blue);
    }
  }

  Future<bool> sendCustomCommand(String commandType, Map<String, dynamic> data) async {
    if (!isConnected) return false;
    
    try {
      final commandData = {
        'type': commandType,
        ...data,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
      
      String jsonData = json.encode(commandData);
      
      if (utf8.encode(jsonData).length > MAX_BLE_CHUNK_SIZE) {
        await _sendDataInChunks(jsonData);
      } else {
        await _writeCharacteristic!.write(
          utf8.encode(jsonData),
          withoutResponse: false,
        );
      }
      
      debugPrint('📤 BleManagerService: Sent custom command: $commandType');
      return true;
    } catch (e) {
      debugPrint('❌ BleManagerService custom command error: $e');
      return false;
    }
  }

  Future<bool> setBrightness(int level) async {
    if (level < 0 || level > 100) {
      debugPrint('⚠️ BleManagerService: Invalid brightness level (0-100)');
      return false;
    }
    
    return await sendCustomCommand('BRIGHTNESS', {'level': level});
  }

  Future<bool> clearDisplay() async {
    return await sendAnimation('CLEAR');
  }

  Future<void> _sendDataInChunks(String data) async {
    if (_writeCharacteristic == null) {
      throw Exception('Write characteristic not available');
    }
    
    try {
      final dataBytes = utf8.encode(data);
      final totalChunks = (dataBytes.length / MAX_BLE_CHUNK_SIZE).ceil();
      
      debugPrint('📦 BleManagerService: Splitting ${dataBytes.length} bytes into $totalChunks chunks');
      
      for (int i = 0; i < totalChunks; i++) {
        final start = i * MAX_BLE_CHUNK_SIZE;
        final end = (start + MAX_BLE_CHUNK_SIZE < dataBytes.length) 
            ? start + MAX_BLE_CHUNK_SIZE 
            : dataBytes.length;
        
        final chunk = dataBytes.sublist(start, end);
        final header = utf8.encode('[$i/$totalChunks]');
        final chunkWithHeader = [...header, ...chunk];
        
        await _writeCharacteristic!.write(
          chunkWithHeader,
          withoutResponse: false,
        );
        
        debugPrint('📤 BleManagerService: Sent chunk ${i + 1}/$totalChunks (${chunk.length} bytes)');
        
        if (i < totalChunks - 1) {
          await Future.delayed(CHUNK_DELAY);
        }
      }
      
      await _writeCharacteristic!.write(
        utf8.encode('[END]'),
        withoutResponse: false,
      );
      
      debugPrint('✅ BleManagerService: All chunks sent successfully');
      
    } catch (e) {
      debugPrint('❌ BleManagerService chunk error: $e');
      rethrow;
    }
  }
  Future<bool> sendCommands(List<String> commands) async {
  if (!isConnected || _writeCharacteristic == null) {
    debugPrint('⚠️ Cannot send commands - not connected');
    return false;
  }

  try {
    for (String command in commands) {
      final commandData = json.encode({
        'type': 'CMD',
        'cmd': command,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      
      final bytes = utf8.encode(commandData);
      
      if (bytes.length > MAX_BLE_CHUNK_SIZE) {
        await _sendDataInChunks(commandData);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      }
      
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    debugPrint('✅ Sent ${commands.length} commands successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Error sending commands: $e');
    return false;
  }
}
  Future<void> _sendCommand(String command) async {
    if (_writeCharacteristic == null) {
      throw Exception('Write characteristic not available');
    }

    try {
      final commandData = json.encode({
        'type': 'CMD',
        'cmd': command,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      
      final bytes = utf8.encode(commandData);
      
      if (bytes.length > MAX_BLE_CHUNK_SIZE) {
        await _sendDataInChunks(commandData);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      }
      
      debugPrint('📤 BleManagerService: Command sent: $command');
    } catch (e) {
      debugPrint('❌ BleManagerService command error: $e');
      rethrow;
    }
  }

  void _notifyStatus(String message, Color color) {
    onStatusUpdate?.call(message, color);
  }

  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': isConnected,
      'deviceName': deviceName,
      'autoRefreshActive': isAutoRefreshActive,
      'hasWriteChar': _writeCharacteristic != null,
      'hasReadChar': _readCharacteristic != null,
    };
  }

  void printDebugInfo() {
    debugPrint('==================== BleManagerService Debug ====================');
    debugPrint('Connected: $isConnected');
    debugPrint('Device: ${_connectedDevice?.platformName ?? 'None'}');
    debugPrint('Device ID: ${_connectedDevice?.remoteId ?? 'None'}');
    debugPrint('Write Char: ${_writeCharacteristic != null ? 'Available' : 'Not Available'}');
    debugPrint('Read Char: ${_readCharacteristic != null ? 'Available' : 'Not Available'}');
    debugPrint('Auto-refresh: ${isAutoRefreshActive ? 'Active' : 'Inactive'}');
    debugPrint('================================================================');
  }
}