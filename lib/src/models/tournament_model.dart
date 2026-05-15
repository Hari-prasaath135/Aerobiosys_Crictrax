import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Map<String, dynamic> toFirestoreMap() => {
        'tournamentId': tournamentId,
        'name': name,
        'city': city,
        'ground': ground,
        'organizerName': organizerName,
        'organizerPhone': organizerPhone,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'categories': categories,
        'tags': tags,
        'logoPath': logoPath,
        'createdAt': Timestamp.fromDate(createdAt),
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

  factory Tournament.fromFirestore(Map<String, dynamic> data) => Tournament(
        tournamentId: data['tournamentId'] ?? '',
        name: data['name'] ?? '',
        city: data['city'] ?? '',
        ground: data['ground'] ?? '',
        organizerName: data['organizerName'] ?? '',
        organizerPhone: data['organizerPhone'] ?? '',
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
        categories: List<String>.from(data['categories'] ?? []),
        tags: List<String>.from(data['tags'] ?? []),
        logoPath: data['logoPath'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );

  // ─── Local (SharedPreferences) ────────────────────────────────────────────

  static Future<void> _saveLocal(Tournament t) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAllLocal();
    all.add(t);
    final encoded = all.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('tournaments', encoded);
  }

  static Future<List<Tournament>> _getAllLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('tournaments') ?? [];
    return raw.map((e) => Tournament.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> _deleteLocal(String tournamentId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAllLocal();
    final updated = all.where((t) => t.tournamentId != tournamentId).toList();
    final encoded = updated.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('tournaments', encoded);
  }

  // ─── Firestore helpers ────────────────────────────────────────────────────

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Path: /users/{uid}/tournaments/{tournamentId}
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('tournaments');

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Saves to both Firestore and local SharedPreferences.
  static Future<void> save(Tournament t) async {
    await _collection.doc(t.tournamentId).set(t.toFirestoreMap());
    await _saveLocal(t);
  }

  /// Deletes from both Firestore and local SharedPreferences.
  static Future<void> delete(String tournamentId) async {
    await _collection.doc(tournamentId).delete();
    await _deleteLocal(tournamentId);
  }

  /// Fetches from Firestore first; falls back to local cache on error.
  static Future<List<Tournament>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: false)
          .get();

      final tournaments =
          snapshot.docs.map((doc) => Tournament.fromFirestore(doc.data())).toList();

      final prefs = await SharedPreferences.getInstance();
      final encoded = tournaments.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('tournaments', encoded);

      return tournaments;
    } catch (_) {
      return _getAllLocal();
    }
  }

  static String generateId() =>
      'TRN_${DateTime.now().millisecondsSinceEpoch}';
}