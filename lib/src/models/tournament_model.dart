import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String createdBy;
  final bool isOnlineTournament;
  final String? format; // ← BUG 3 FIX: added format field

  const Tournament({
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
    required this.createdAt,
    required this.createdBy,
    this.isOnlineTournament = false,
    this.logoPath,
    this.format, // ← BUG 3 FIX
  });

  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('tournaments');

  Map<String, dynamic> toMap() => {
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
        'createdBy': createdBy,
        'isOnlineTournament': isOnlineTournament,
        'format': format, // ← BUG 3 FIX: persisted to Firestore
      };

  factory Tournament.fromMap(Map<String, dynamic> map) => Tournament(
        tournamentId: map['tournamentId'] as String,
        name: map['name'] as String,
        city: map['city'] as String,
        ground: map['ground'] as String,
        organizerName: map['organizerName'] as String,
        organizerPhone: map['organizerPhone'] as String,
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        categories: List<String>.from(map['categories'] ?? []),
        tags: List<String>.from(map['tags'] ?? []),
        logoPath: map['logoPath'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        createdBy: (map['createdBy'] as String?) ?? '',
        isOnlineTournament: (map['isOnlineTournament'] as bool?) ?? false,
        format: map['format'] as String?, // ← BUG 3 FIX: read from Firestore
      );

  static String generateId() => _col.doc().id;

  bool get isOwnedByCurrentUser {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == createdBy;
  }

  static bool get currentUserIsAnonymous {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  static Future<void> save(Tournament tournament) async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot create tournaments.');
    }
    await _col.doc(tournament.tournamentId).set(tournament.toMap());
  }

  static Future<List<Tournament>> getAll() async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot view tournaments.');
    }
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => Tournament.fromMap(doc.data())).toList();
  }

  static Stream<List<Tournament>> stream() {
    if (currentUserIsAnonymous) {
      return const Stream.empty();
    }
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Tournament.fromMap(doc.data())).toList());
  }

  static Future<void> delete(String tournamentId) async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot delete tournaments.');
    }
    await _col.doc(tournamentId).delete();
  }
}