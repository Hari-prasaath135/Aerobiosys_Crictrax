import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class EnvironmentService {
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();

  Timer? _clockTimer;
  String _currentTime = '';
  double? _currentTemperature;
  String? _weatherCondition;
  
  // Getters
  String get currentTime => _currentTime;
  double? get currentTemperature => _currentTemperature;
  String? get weatherCondition => _weatherCondition;

  // Start the service
  void initialize() {
    print('🚀 EnvironmentService: Initializing...');
    _startClock();
    _fetchWeatherData();
    
    // Fetch weather every 10 minutes
    Timer.periodic(const Duration(minutes: 10), (timer) {
      print('🔄 EnvironmentService: Refreshing weather data...');
      _fetchWeatherData();
    });
  }

  // Start clock timer
  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    print('⏰ Clock started');
  }

  // Update current time
  void _updateTime() {
    _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
  }

  // Fetch weather data
 // Fetch weather data
Future<void> _fetchWeatherData() async {
  print('🌍 EnvironmentService: Fetching weather data...');
  
  try {
    // Get current location
    print('📍 EnvironmentService: Getting location...');
    Position position = await _determinePosition();
    print('📍 EnvironmentService: Location obtained - Lat: ${position.latitude}, Lon: ${position.longitude}');
    
    // Fetch weather from OpenWeatherMap (free API)
    final apiKey = '69c33457d3d2aeb67e719420c81677f5';
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';
    
    print('🌐 EnvironmentService: Calling weather API...');
    
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('API call timed out after 10 seconds');
      },
    );
    
    print('📡 EnvironmentService: API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Round to nearest integer
      final rawTemp = data['main']['temp'].toDouble();
      _currentTemperature = rawTemp.roundToDouble();
      _weatherCondition = data['weather'][0]['main'];
      
      print('✅ EnvironmentService: Weather updated successfully');
      print('   📊 Raw Temperature: ${rawTemp}°C');
      print('   🌡️ Rounded Temperature: ${_currentTemperature?.toInt()}°C');
      print('   ☁️ Condition: $_weatherCondition');
    } else {
      print('❌ EnvironmentService: API Error - Status: ${response.statusCode}');
      print('   Response: ${response.body}');
      _currentTemperature = null;
      _weatherCondition = 'API Error';
    }
  } catch (e, stackTrace) {
    print('❌ EnvironmentService: Error fetching weather');
    print('   Error: $e');
    print('   Stack trace: $stackTrace');
    _currentTemperature = null;
    _weatherCondition = 'Error';
  }
}
// Add this method to EnvironmentService class for testing
Future<void> testWeatherAPI() async {
  print('🧪 EnvironmentService: Testing weather API...');
  
  // Test with Puducherry coordinates
  final testLat = 11.9416;
  final testLon = 79.8083;
  final apiKey = '69c33457d3d2aeb67e719420c81677f5';
  final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$testLat&lon=$testLon&units=metric&appid=$apiKey';
  
  print('🔗 Test URL: $url');
  
  try {
    final response = await http.get(Uri.parse(url));
    print('📡 Test Response Status: ${response.statusCode}');
    print('📦 Test Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ API is working!');
      print('   Location: ${data['name']}');
      print('   Temperature: ${data['main']['temp']}°C');
      print('   Weather: ${data['weather'][0]['main']}');
    } else {
      print('❌ API returned error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Test failed: $e');
  }
}


  // Get device location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Default Puducherry coordinates
    Position defaultPosition = Position(
      latitude: 11.9416,
      longitude: 79.8083,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    print('🔍 Checking location services...');
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location services disabled, using default coordinates (Puducherry)');
      return defaultPosition;
    }

    print('🔑 Checking location permission...');
    permission = await Geolocator.checkPermission();
    print('🔑 Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      print('🔑 Requesting location permission...');
      permission = await Geolocator.requestPermission();
      print('🔑 Permission result: $permission');
      
      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied, using default coordinates (Puducherry)');
        return defaultPosition;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⚠️ Location permission denied forever, using default coordinates (Puducherry)');
      return defaultPosition;
    }

    try {
      print('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      print('✅ Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting position: $e, using default coordinates (Puducherry)');
      return defaultPosition;
    }
  }

  // Dispose method
  void dispose() {
    _clockTimer?.cancel();
    print('🛑 EnvironmentService disposed');
  }
}