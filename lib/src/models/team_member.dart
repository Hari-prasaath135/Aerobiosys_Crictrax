// team_member.dart — in-memory cache backed by Firestore (fire-and-forget writes)
//
// NOTE: The field `teamName` intentionally stores the player's *display name*.
// All screens reference it as `player.teamName` to get the player name —
// this naming is preserved exactly to avoid breaking any existing callers.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TeamMember {
  final String playerId;
  final String teamId;
  /// Stores the player's display name (field name kept as teamName to match
  /// existing screen code: player.teamName).
  final String teamName;
  final String role;

  // ─── Local In-Memory Cache — keyed by playerId ────────────────────────────
  static final Map<String, TeamMember> _cache = {};

  const TeamMember({
    required this.playerId,
    required this.teamId,
    required this.teamName,
    this.role = '',
  });

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'teamId': teamId,
        'teamName': teamName,
        'role': role,
      };

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final m = TeamMember(
      playerId: map['playerId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      teamName: map['teamName'] as String? ??
          map['playerName'] as String? ??
          '',
      role: map['role'] as String? ?? '',
    );
    if (m.playerId.isNotEmpty) _cache[m.playerId] = m;
    return m;
  }

  // ─── save ─────────────────────────────────────────────────────────────────
  void save() {
    _cache[playerId] = this;
    FirebaseFirestore.instance
        .collection('team_members')
        .doc(playerId)
        .set(toMap())
        .catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY ──────────────────────────────────────────────────
  static TeamMember create({
    required String teamId,
    required String playerName,
    String role = '',
    String? playerId,
  }) {
    final m = TeamMember(
      playerId: playerId ?? const Uuid().v4(),
      teamId: teamId,
      teamName: playerName,
      role: role,
    );
    _cache[m.playerId] = m;
    m.save();
    return m;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static TeamMember? getByPlayerId(String playerId) => _cache[playerId];

  static List<TeamMember> getByTeamId(String teamId) =>
      _cache.values.where((m) => m.teamId == teamId).toList();

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(TeamMember m) => _cache[m.playerId] = m;
  static void removeFromCache(String playerId) => _cache.remove(playerId);
  static void clearCache() => _cache.clear();

  static void addBulk(List<TeamMember> members) {
    for (final m in members) {
      _cache[m.playerId] = m;
    }
  }

  // ─── Async load helpers ───────────────────────────────────────────────────
  static Future<void> loadFromFirestore(String teamId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('team_members')
          .where('teamId', isEqualTo: teamId)
          .get();
      for (final doc in snap.docs) {
        TeamMember.fromMap(doc.data());
      }
    } catch (_) {}
  }

  static Future<List<TeamMember>> fetchByTeamId(String teamId) async {
    await loadFromFirestore(teamId);
    return getByTeamId(teamId);
  }
}