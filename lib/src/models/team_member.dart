// team_member.dart — in-memory cache backed by Firestore (fire-and-forget writes)
//
// NOTE: The field `teamName` intentionally stores the player's *display name*.
// All screens reference it as `player.teamName` to get the player name —
// this naming is preserved exactly to avoid breaking any existing callers.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class TeamMember {
  final String playerId;
  final String teamId;
  /// Stores the player's display name (field name kept as teamName to match
  /// existing screen code: player.teamName).
  final String teamName;
  final String role;

  /// UID of the team owner — used to build the correct nested Firestore path.
  /// Defaults to the current user's uid if not supplied.
  final String teamOwnerUid;

  // ─── Local In-Memory Cache — keyed by playerId ────────────────────────────
  static final Map<String, TeamMember> _cache = {};

  const TeamMember({
    required this.playerId,
    required this.teamId,
    required this.teamName,
    this.role = '',
    this.teamOwnerUid = '',
  });

  // ─── Path helper ──────────────────────────────────────────────────────────
  /// /users/{uid}/teams/{teamId}/members/{playerId}
  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = teamOwnerUid.isNotEmpty
        ? teamOwnerUid
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(playerId);
  }

  /// Collection reference — used for bulk reads.
  static CollectionReference<Map<String, dynamic>> _col(
      String uid, String teamId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('teams')
          .doc(teamId)
          .collection('members');

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'teamId': teamId,
        'teamName': teamName,
        'playerName': teamName,
        'role': role,
        'teamOwnerUid': teamOwnerUid,
      };

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final m = TeamMember(
      playerId: map['playerId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      teamName: map['teamName'] as String? ??
          map['playerName'] as String? ??
          '',
      role: map['role'] as String? ?? '',
      teamOwnerUid: map['teamOwnerUid'] as String? ?? '',
    );
    if (m.playerId.isNotEmpty) _cache[m.playerId] = m;
    return m;
  }

  // ─── save ─────────────────────────────────────────────────────────────────
  void save() {
    _cache[playerId] = this;
    // Write to /users/{uid}/teams/{teamId}/members/{playerId}
    final uid = teamOwnerUid.isNotEmpty
        ? teamOwnerUid
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isNotEmpty && teamId.isNotEmpty) {
      _doc.set(toMap()).catchError((_) {});
    }
  }

  // ─── SYNCHRONOUS FACTORY ──────────────────────────────────────────────────
  static TeamMember create({
    required String teamId,
    required String playerName,
    String role = '',
    String? playerId,
    String teamOwnerUid = '',
  }) {
    final uid = teamOwnerUid.isNotEmpty
        ? teamOwnerUid
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    final m = TeamMember(
      playerId: playerId ?? const Uuid().v4(),
      teamId: teamId,
      teamName: playerName,
      role: role,
      teamOwnerUid: uid,
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
  /// Loads members from /users/{uid}/teams/{teamId}/members
  /// [uid] defaults to the current user if omitted.
  static Future<void> loadFromFirestore(String teamId,
      {String uid = ''}) async {
    try {
      final resolvedUid = uid.isNotEmpty
          ? uid
          : (FirebaseAuth.instance.currentUser?.uid ?? '');
      if (resolvedUid.isEmpty) return;

      final snap = await _col(resolvedUid, teamId).get();
      for (final doc in snap.docs) {
        TeamMember.fromMap({...doc.data(), 'teamOwnerUid': resolvedUid});
      }
    } catch (_) {}
  }

  static Future<List<TeamMember>> fetchByTeamId(String teamId,
      {String uid = ''}) async {
    await loadFromFirestore(teamId, uid: uid);
    return getByTeamId(teamId);
  }
}