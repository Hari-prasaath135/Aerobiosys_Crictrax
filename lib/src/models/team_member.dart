// team_member.dart — in-memory cache backed by Firestore (fire-and-forget writes)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class TeamMember {
  final String playerId;
  final String teamId;

  /// Internal storage. Always use [playerName] getter in UI — never teamName directly.
  final String teamName;
  final String role;
  final String teamOwnerUid;

  /// ✅ Safe getter — prefers trimmed value, never returns empty string.
  String get playerName {
    final n = teamName.trim();
    return n.isNotEmpty ? n : '(Unnamed Player)';
  }

  static final Map<String, TeamMember> _cache = {};

  const TeamMember({
    required this.playerId,
    required this.teamId,
    required this.teamName,
    this.role = '',
    this.teamOwnerUid = '',
  });

  // ─── Path helpers ─────────────────────────────────────────────────────────

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
        'teamName': teamName,    // kept for backward compat
        'playerName': teamName,  // ✅ canonical — always written
        'role': role,
        'teamOwnerUid': teamOwnerUid,
      };

  /// ✅ Fixed: reads playerName first (canonical), falls back to teamName (legacy).
  /// Handles every Firestore doc format — old, new, or mixed.
  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final rawPlayerName = (map['playerName'] as String? ?? '').trim();
    final rawTeamName   = (map['teamName']   as String? ?? '').trim();

    // Prefer playerName → teamName → empty (playerName getter handles empty)
    final resolvedName = rawPlayerName.isNotEmpty
        ? rawPlayerName
        : rawTeamName;

    final m = TeamMember(
      playerId:     (map['playerId']     as String? ?? '').trim(),
      teamId:       (map['teamId']       as String? ?? '').trim(),
      teamName:     resolvedName,
      role:         (map['role']         as String? ?? '').trim(),
      teamOwnerUid: (map['teamOwnerUid'] as String? ?? '').trim(),
    );

    if (m.playerId.isNotEmpty) _cache[m.playerId] = m;
    return m;
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  void save() {
    _cache[playerId] = this;
    final uid = teamOwnerUid.isNotEmpty
        ? teamOwnerUid
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isNotEmpty && teamId.isNotEmpty) {
      _doc.set(toMap()).catchError((_) {});
    }
  }

  // ─── Synchronous factory ──────────────────────────────────────────────────

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
      playerId:     playerId ?? const Uuid().v4(),
      teamId:       teamId,
      teamName:     playerName.trim(),
      role:         role,
      teamOwnerUid: uid,
    );
    _cache[m.playerId] = m;
    m.save();
    return m;
  }

  // ─── Synchronous lookups ──────────────────────────────────────────────────

  static TeamMember? getByPlayerId(String playerId) => _cache[playerId];

  static List<TeamMember> getByTeamId(String teamId) =>
      _cache.values.where((m) => m.teamId == teamId).toList();

  // ─── Cache management ─────────────────────────────────────────────────────

  static void addToCache(TeamMember m)         => _cache[m.playerId] = m;
  static void removeFromCache(String playerId) => _cache.remove(playerId);
  static void clearCache()                     => _cache.clear();

  static void clearCacheForTeam(String teamId) =>
      _cache.removeWhere((_, member) => member.teamId == teamId);

  static void addBulk(List<TeamMember> members) {
    for (final m in members) {
      _cache[m.playerId] = m;
    }
  }

  // ─── Async load helpers ───────────────────────────────────────────────────

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