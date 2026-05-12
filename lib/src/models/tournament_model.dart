import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Tournament {
  final String tournamentId;
  final String name;
  final String city;
  final String ground;
  final String organizerName;
  final String organizerPhone;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories;
  final List<String> tags;
  final String? logoPath;
  final DateTime createdAt;

  Tournament({
    required this.tournamentId,
    required this.name,
    required this.city,
    required this.ground,
    required this.organizerName,
    required this.organizerPhone,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.tags,
    this.logoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'name': name,
        'city': city,
        'ground': ground,
        'organizerName': organizerName,
        'organizerPhone': organizerPhone,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'categories': categories,
        'tags': tags,
        'logoPath': logoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        tournamentId: json['tournamentId'],
        name: json['name'],
        city: json['city'],
        ground: json['ground'],
        organizerName: json['organizerName'],
        organizerPhone: json['organizerPhone'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        categories: List<String>.from(json['categories']),
        tags: List<String>.from(json['tags']),
        logoPath: json['logoPath'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  static Future<void> save(Tournament t) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    all.add(t);
    final encoded = all.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('tournaments', encoded);
  }

  static Future<List<Tournament>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('tournaments') ?? [];
    return raw.map((e) => Tournament.fromJson(jsonDecode(e))).toList();
  }

  static String generateId() =>
      'TRN_${DateTime.now().millisecondsSinceEpoch}';
}