import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'dart:async';
import 'package:TURF_TOWN_/src/Menus/setting.dart';
import 'package:TURF_TOWN_/src/services/bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<ScanResult> scanResults = [];

  final String serviceUUID = "ABCD";
  final String characteristicUUID = "1234";

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // 🔥 NEW: Store connected device ID for highlighting
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _initBluetooth();

    // 🔥 NEW: Check if already connected on page load
    _checkExistingConnection();
  }
  
  // 🔥 NEW: Check for existing connection when page loads
  void _checkExistingConnection() {
    final bleService = BleManagerService();
    if (bleService.isConnected && bleService.connectedDevice != null) {
      setState(() {
        _connectedDeviceId = bleService.connectedDevice!.remoteId.toString();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();

    if (await FlutterBluePlus.isSupported == false) {
      _showSnackBar('Bluetooth not supported by this device', Colors.red);
      return;
    }

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        debugPrint('Bluetooth is ON');
      } else {
        debugPrint('Bluetooth is OFF');
        _showSnackBar('Please turn on Bluetooth', Colors.orange);
      }
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 31) {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

          if (statuses.values.any((status) => !status.isGranted)) {
            _showSnackBar('Bluetooth permissions are required', Colors.red);
            return;
          }
        } else {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetooth,
            Permission.location,
          ].request();

          if (statuses.values.any((status) => !status.isGranted)) {
            _showSnackBar('Bluetooth permissions are required', Colors.red);
            return;
          }
        }
      } catch (e) {
        debugPrint('Error requesting permissions: $e');
        _showSnackBar('Error requesting permissions', Colors.red);
      }
    }
  }

  void startSearching() async {
    // 🔥 NEW: Prevent scanning if already connected
    final bleService = BleManagerService();
    if (bleService.isConnected) {
      _showSnackBar('Already connected. Disconnect first to scan again.', Colors.orange);
      return;
    }

    await _requestPermissions();

    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('Error turning on Bluetooth: $e');
      }
    }

    setState(() {
      isSearching = true;
      scanResults.clear();
    });
    _animationController.repeat();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            scanResults = results;
          });
        }
      });

      _showSnackBar('Scanning for BLE devices...', Colors.blue);

      await Future.delayed(const Duration(seconds: 15));
      await FlutterBluePlus.stopScan();

      if (mounted) {
        setState(() {
          isSearching = false;
        });
        _animationController.stop();
        _animationController.reset();

        if (scanResults.isEmpty) {
          _showSnackBar(
            'No devices found. Make sure your ESP32 is powered on.',
            Colors.orange,
          );
        } else {
          _showSnackBar(
            'Found ${scanResults.length} device(s). Tap to connect.',
            Colors.green,
          );
        }
      }
    } catch (e) {
      debugPrint('Error during scanning: $e');
      _showSnackBar('Error scanning for devices: $e', Colors.red);
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // 🔥 NEW: Prevent connecting to other devices if already connected
    final bleService = BleManagerService();
    if (bleService.isConnected) {
      _showSnackBar('Already connected to a device. Disconnect first.', Colors.orange);
      return;
    }
    
    try {
      _showSnackBar('Connecting to ${device.platformName}...', Colors.blue);

      // Cancel any existing connection attempts
      try {
        await device.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('No previous connection to cancel');
      }

      // Attempt connection with proper timeout and auto-connect disabled
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Verify connection state before proceeding
      final connectionState = await device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception('Device not in connected state');
      }

      _showSnackBar('Connected! Discovering services...', Colors.green);

      // Request MTU increase
      try {
        await device.requestMtu(512);
        debugPrint('✅ MTU increased to 512');
      } catch (e) {
        debugPrint('⚠️ Could not increase MTU: $e');
      }

      // Small delay before service discovery
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      debugPrint('Found ${services.length} services');

      bool serviceFound = false;

      for (BluetoothService service in services) {
        debugPrint('Service UUID: ${service.uuid}');

        if (service.uuid.toString().toUpperCase().contains(serviceUUID.toUpperCase())) {
          serviceFound = true;
          debugPrint('✅ Target service found!');

          BluetoothCharacteristic? foundWriteCharacteristic;
          BluetoothCharacteristic? foundReadCharacteristic;

          for (BluetoothCharacteristic characteristic in service.characteristics) {
            debugPrint('Characteristic UUID: ${characteristic.uuid}');
            final charUuidStr = characteristic.uuid.toString().toUpperCase();

            if (charUuidStr.contains("1234")) {
              if (characteristic.properties.write ||
                  characteristic.properties.writeWithoutResponse) {
                foundWriteCharacteristic = characteristic;
                debugPrint('✅ Write characteristic found');
              }
            }

            if (charUuidStr.contains("5678")) {
              if (characteristic.properties.read ||
                  characteristic.properties.notify) {
                foundReadCharacteristic = characteristic;
                debugPrint('✅ Read characteristic found');
              }
            }
          }

          if (foundWriteCharacteristic != null) {
            debugPrint('╔════════════════════════════════════════╗');
            debugPrint('║  ✅ BLUETOOTH CONNECTION SUCCESSFUL ✅  ║');
            debugPrint('╠════════════════════════════════════════╣');
            debugPrint('║  Device: ${device.platformName.padRight(28)}║');
            debugPrint('║  Status: Ready to receive commands     ║');
            debugPrint('╚════════════════════════════════════════╝');

            _showSnackBar('✅ Connected! Ready to send data', Colors.green);

            // 🔥 NEW: Store connected device ID for UI highlighting
            setState(() {
              _connectedDeviceId = device.remoteId.toString();
            });

            BleManagerService().initialize(
              device: device,
              writeCharacteristic: foundWriteCharacteristic,
              readCharacteristic: foundReadCharacteristic,
              statusCallback: _showSnackBar,
              disconnectCallback: () {
                if (mounted) {
                  setState(() {
                    // 🔥 NEW: Clear highlighted device on disconnect
                    _connectedDeviceId = null;
                  });
                }
              },
            );

            return;
          } else {
            throw Exception('Write characteristic not found in service');
          }
        }
      }

      if (!serviceFound) {
        throw Exception('Service UUID $serviceUUID not found on device');
      }

    } on TimeoutException {
      debugPrint('❌ Connection timeout');
      _showSnackBar('Connection timeout - device not responding', Colors.red);

      try {
        await device.disconnect();
      } catch (_) {}
    } catch (e) {
      debugPrint('❌ Error connecting to device: $e');

      String errorMessage = 'Connection failed';
      if (e.toString().contains('133')) {
        errorMessage = 'Connection error - try resetting Bluetooth';
      } else if (e.toString().contains('62')) {
        errorMessage = 'Device not accepting connections - check ESP32';
      } else if (e.toString().contains('Service')) {
        errorMessage = 'Service not found - check ESP32 firmware';
      }

      _showSnackBar(errorMessage, Colors.red);

      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<void> _disconnectDevice() async {
    final bleService = BleManagerService();

    if (!bleService.isConnected) return;

    try {
      _showSnackBar('Disconnecting...', Colors.orange);

      await bleService.disconnect();

      if (mounted) {
        setState(() {
          // 🔥 NEW: Clear connected device ID on manual disconnect
          _connectedDeviceId = null;
        });
      }

      _showSnackBar('Device disconnected', Colors.orange);
    } catch (e) {
      debugPrint('Error disconnecting device: $e');
      _showSnackBar('Error disconnecting device', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('esp32') ||
        name.contains('matrix') ||
        name.contains('led')) {
      return Icons.developer_board;
    } else if (name.contains('score') || name.contains('cricket')) {
      return Icons.sports_cricket;
    } else {
      return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleService = BleManagerService();
    final isConnected = bleService.isConnected;
    final deviceName = bleService.deviceName;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A5C), Color(0xFF000000)],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cricket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Scorer',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                IconButton(
  icon: const Icon(
    Icons.settings,
    color: Colors.white,
    size: 24,
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: isSearching || isConnected
                      ? SizedBox(
                          key: const ValueKey('animation'),
                          width: 200,
                          height: 200,
                          // 🔥 Lottie animation with smooth transition
                          child: Lottie.asset(
                            'assets/images/balls.json',
                            fit: BoxFit.contain,
                            repeat: isSearching || isConnected,
                          ),
                        )
                      : Icon(
                          key: const ValueKey('icon'),
                          Icons.bluetooth_disabled,
                          size: 140,
                          color: Colors.grey,
                        ),
                ),
              ),
              Text(
                isConnected
                    ? 'Connected to $deviceName'
                    : 'Not Connected',
                style: TextStyle(
                  color: isConnected
                      ? Colors.greenAccent
                      : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: isConnected
                      ? _disconnectDevice
                      : (isSearching ? null : startSearching),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected
                        ? Colors.redAccent
                        : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    isConnected
                        ? 'Disconnect'
                        : (isSearching ? 'Searching...' : 'Start Scanning'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: scanResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No devices found',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: scanResults.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final result = scanResults[index];
                          final device = result.device;
                          
                          final deviceName = device.platformName.isEmpty
                              ? 'Unknown Device'
                              : device.platformName;
                          
                          // 🔥 NEW: Check if this device is currently connected
                          final isThisDeviceConnected = _connectedDeviceId == device.remoteId.toString();

                          return Card(
                            color: isThisDeviceConnected 
                                ? const Color(0xFF2E4E3E) // 🔥 NEW: Green tint for connected device
                                : const Color(0xFF1E1E2E),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              // 🔥 NEW: Green border for connected device
                              side: isThisDeviceConnected
                                  ? const BorderSide(color: Colors.greenAccent, width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: Icon(
                                isThisDeviceConnected
                                    ? Icons.bluetooth_connected // 🔥 NEW: Connected icon
                                    : _getDeviceIcon(deviceName),
                                color: isThisDeviceConnected
                                    ? Colors.greenAccent // 🔥 NEW: Green for connected
                                    : Colors.blueAccent,
                                size: 36,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      deviceName,
                                      style: TextStyle(
                                        color: isThisDeviceConnected
                                            ? Colors.greenAccent // 🔥 NEW: Green text for connected
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // 🔥 NEW: "CONNECTED" badge
                                  if (isThisDeviceConnected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.greenAccent,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'CONNECTED',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                device.remoteId.toString(),
                                style: TextStyle(
                                  color: isThisDeviceConnected
                                      ? Colors.greenAccent.withOpacity(0.7) // 🔥 NEW: Green subtitle
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: result.rssi != 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isThisDeviceConnected
                                            ? Colors.greenAccent.withOpacity(0.2) // 🔥 NEW: Green RSSI badge
                                            : Colors.blueAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${result.rssi} dBm',
                                        style: TextStyle(
                                          color: isThisDeviceConnected
                                              ? Colors.greenAccent // 🔥 NEW: Green RSSI text
                                              : Colors.blueAccent,
                                          fontSize: 12,
                                        ),
                                        
                                      ),
                                    )
                                  : null,
                              // 🔥 NEW: Disable tap if already connected (unless it's this device)
                              onTap: isConnected && !isThisDeviceConnected
                                  ? () {
                                      _showSnackBar(
                                        'Already connected. Disconnect first.',
                                        Colors.orange,
                                      );
                                    }
                                  : () => _connectToDevice(device),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}