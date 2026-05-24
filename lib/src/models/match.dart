import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Match {
  final String matchId;
  final String teamId1;
  final String teamId2;
  final int overs;
  final bool isNoballAllowed;
  final bool isWideAllowed;
  final DateTime? matchDate;
  bool isCompleted;

  // ─── Local In-Memory Cache ────────────────────────────────────────────────
  static final Map<String, Match> _cache = {};

  Match({
    required this.matchId,
    required this.teamId1,
    required this.teamId2,
    required this.overs,
    required this.isNoballAllowed,
    required this.isWideAllowed,
    this.matchDate,
    this.isCompleted = false,
  });

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'teamId1': teamId1,
        'teamId2': teamId2,
        'overs': overs,
        'isNoballAllowed': isNoballAllowed,
        'isWideAllowed': isWideAllowed,
        'isCompleted': isCompleted,
        'matchDate': matchDate?.toIso8601String(),
      };

  factory Match.fromMap(Map<String, dynamic> map) {
    final m = Match(
      matchId: map['matchId'] as String,
      teamId1: map['teamId1'] as String? ?? '',
      teamId2: map['teamId2'] as String? ?? '',
      overs: (map['overs'] as num?)?.toInt() ?? 20,
      isNoballAllowed: map['isNoballAllowed'] as bool? ?? true,
      isWideAllowed: map['isWideAllowed'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
      matchDate: map['matchDate'] != null
          ? DateTime.tryParse(map['matchDate'] as String)
          : null,
    );
    _cache[m.matchId] = m;
    return m;
  }

  void save() {
    _cache[matchId] = this;
    FirebaseFirestore.instance
        .collection('matches_global')
        .doc(matchId)
        .set(toMap())
        .catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY ──────────────────────────────────────────────────
  static Match create({
    required String teamId1,
    required String teamId2,
    required int overs,
    bool isNoballAllowed = true,
    bool isWideAllowed = true,
    DateTime? matchDate,
  }) {
    final m = Match(
      matchId: const Uuid().v4(),
      teamId1: teamId1,
      teamId2: teamId2,
      overs: overs,
      isNoballAllowed: isNoballAllowed,
      isWideAllowed: isWideAllowed,
      matchDate: matchDate ?? DateTime.now(),
    );
    _cache[m.matchId] = m;
    m.save();
    return m;
  }

  // ─── SYNCHRONOUS LOOKUP ───────────────────────────────────────────────────
  static Match? getByMatchId(String matchId) => _cache[matchId];

  static List<Match> getAll() => _cache.values.toList();

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(Match m) => _cache[m.matchId] = m;

  static void clearCache() => _cache.clear();

  // ─── Legacy async load ────────────────────────────────────────────────────
  static Future<void> loadFromFirestore(String matchId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches_global')
          .doc(matchId)
          .get();
      if (doc.exists && doc.data() != null) {
        Match.fromMap(doc.data()!);
      }
    } catch (_) {}
  }
}