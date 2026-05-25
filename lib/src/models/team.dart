// team.dart — in-memory cache backed by Firestore (fire-and-forget writes)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class Team {
  final String teamId;
  final String teamName;
  int teamCount;           // mutable so updateCountSync works
  final String createdBy;
  final String ownerName;

  // ─── Local In-Memory Cache — keyed by teamId ─────────────────────────────
  static final Map<String, Team> _cache = {};
  
  
  static void removeFromCache(String teamId) => _cache.remove(teamId);
  
  
  
  Team({
    required this.teamId,
    required this.teamName,
    required this.teamCount,
    required this.createdBy,
    required this.ownerName,
  });

  // ─── Path helper ──────────────────────────────────────────────────────────
  /// /users/{uid}/teams/{teamId}
  /// Uses createdBy so the path is always for the owning user,
  /// even if called from a context where FirebaseAuth.currentUser differs.
  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId);
  }

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'teamId': teamId,
        'teamName': teamName,
        'teamCount': teamCount,
        'createdBy': createdBy,
        'ownerName': ownerName,
      };

  factory Team.fromMap(Map<String, dynamic> map) {
    final t = Team(
      teamId: map['teamId'] as String? ?? map['id'] as String? ?? '',
      teamName: map['teamName'] as String? ?? '',
      teamCount: (map['teamCount'] as num?)?.toInt() ?? 0,
      createdBy: map['createdBy'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
    );
    if (t.teamId.isNotEmpty) _cache[t.teamId] = t;
    return t;
  }

  // ─── save ─────────────────────────────────────────────────────────────────
  void save() {
    _cache[teamId] = this;
    // Write to /users/{uid}/teams/{teamId}
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isNotEmpty) {
      _doc.set(toMap()).catchError((_) {});
    }
  }

  /// Updates the player count synchronously (used by InitialTeamPage).
  void updateCountSync(int newCount) {
    teamCount = newCount;
    _cache[teamId] = this;
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isNotEmpty) {
      _doc.update({'teamCount': newCount}).catchError((_) {});
    }
  }

  // ─── SYNCHRONOUS FACTORY ──────────────────────────────────────────────────
  static Team create({
    required String teamName,
    required int teamCount,
    required String createdBy,
    String ownerName = '',
    String? teamId,
  }) {
    final t = Team(
      teamId: teamId ?? const Uuid().v4(),
      teamName: teamName,
      teamCount: teamCount,
      createdBy: createdBy,
      ownerName: ownerName,
    );
    _cache[t.teamId] = t;
    t.save();
    return t;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static Team? getById(String teamId) => _cache[teamId];
  static List<Team> getAll() => _cache.values.toList();

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(Team t) => _cache[t.teamId] = t;
  static void clearCache() => _cache.clear();

  // ─── Async load ───────────────────────────────────────────────────────────
  /// Loads teams from /users/{userId}/teams
  static Future<void> loadFromFirestore(String userId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('teams')
          .get();
      for (final doc in snap.docs) {
        Team.fromMap({...doc.data(), 'teamId': doc.id});
      }
    } catch (_) {}
  }

  static Future<List<Team>> fetchAll(String userId) async {
    await loadFromFirestore(userId);
    return getAll();
  }
}