// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/match_storage.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Path helpers ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _teamsCol =>
      _db.collection('users').doc(_uid).collection('teams');

  CollectionReference<Map<String, dynamic>> _membersCol(String teamId) => _db
      .collection('users')
      .doc(_uid)
      .collection('teams')
      .doc(teamId)
      .collection('members');

  // ── Teams ──────────────────────────────────────────────────────────────────

  Future<List<Team>> getMyTeams() async {
    try {
      final snap = await _teamsCol.get();
      final teams = <Team>[];
      for (final doc in snap.docs) {
        final t = Team.fromMap({...doc.data(), 'teamId': doc.id});
        teams.add(t);
      }
      return teams;
    } catch (_) {
      return [];
    }
  }

  // ✅ FIX: teamName is POSITIONAL (first arg), ownerName & teamCount are named+optional
  Future<Team> createTeam(
    String teamName, { // <-- positional, NOT named
    String ownerName = '',
    int teamCount = 0,
  }) async {
    final t = Team.create(
      teamName: teamName,
      teamCount: teamCount,
      createdBy: _uid,
      ownerName: ownerName,
    );
    try {
      await _teamsCol.doc(t.teamId).set(t.toMap());
    } catch (_) {}
    return t;
  }

  // ✅ FIX: deleteTeam is explicitly defined here
  Future<void> deleteTeam(String teamId) async {
    try {
      // 1. Delete every member sub-doc first
      final membersSnap = await _membersCol(teamId).get();
      for (final doc in membersSnap.docs) {
        await doc.reference.delete();
        TeamMember.removeFromCache(doc.id);
      }
      // 2. Delete the team doc itself
      await _teamsCol.doc(teamId).delete();
      // 3. Remove from local in-memory cache
      Team.removeFromCache(teamId);
    } catch (_) {}
  }

  // ── Players ────────────────────────────────────────────────────────────────

  Future<List<TeamMember>> getTeamPlayers(String teamId) async {
    try {
      final snap = await _membersCol(teamId).get();
      final members = <TeamMember>[];
      for (final doc in snap.docs) {
        final m = TeamMember.fromMap(doc.data());
        members.add(m);
      }
      return members;
    } catch (_) {
      return TeamMember.getByTeamId(teamId);
    }
  }

  Future<List<TeamMember>> getPlayers(String ownerUid, String teamId) async {
    return getTeamPlayers(teamId);
  }

  Future<TeamMember> addPlayer({
    required String teamId,
    required String playerName,
    String role = '',
  }) async {
    final m = TeamMember.create(
      teamId: teamId,
      playerName: playerName,
      role: role,
    );
    try {
      await _membersCol(teamId).doc(m.playerId).set(m.toMap());
      final team = Team.getById(teamId);
      if (team != null) {
        team.updateCountSync(TeamMember.getByTeamId(teamId).length);
        await _teamsCol.doc(teamId).update({'teamCount': team.teamCount});
      }
    } catch (_) {}
    return m;
  }

  Future<void> updatePlayerName(
    String ownerUid,
    String teamId,
    String playerId,
    String newName,
  ) async {
    try {
      await _membersCol(teamId).doc(playerId).update({'teamName': newName});
      final existing = TeamMember.getByPlayerId(playerId);
      if (existing != null) {
        final updated = TeamMember(
          playerId: existing.playerId,
          teamId: existing.teamId,
          teamName: newName,
          role: existing.role,
        );
        TeamMember.addToCache(updated);
      }
    } catch (_) {}
  }

  Future<void> deletePlayer(
    String ownerUid,
    String teamId,
    String playerId,
  ) async {
    try {
      await _membersCol(teamId).doc(playerId).delete();
      TeamMember.removeFromCache(playerId);
      final team = Team.getById(teamId);
      if (team != null) {
        team.updateCountSync(TeamMember.getByTeamId(teamId).length);
        await _teamsCol.doc(teamId).update({'teamCount': team.teamCount});
      }
    } catch (_) {}
  }

  // ── Match ──────────────────────────────────────────────────────────────────

  Future<Match> createMatch({
    required String tournamentId,
    required String teamId1,
    required String teamId1Name,
    required String teamId1OwnerUid,
    required String teamId2,
    required String teamId2Name,
    required String teamId2OwnerUid,
    required String tossWonBy,
    required int batBowlFlag,
    required int noballFlag,
    required int wideFlag,
    required int overs,
  }) async {
    final match = MatchStorage.createMatch(
      teamId1: teamId1,
      teamId2: teamId2,
      overs: overs,
      tossWonBy: tossWonBy,
      batBowlFlag: batBowlFlag,
      isNoballAllowed: noballFlag == 1,
      isWideAllowed: wideFlag == 1,
      teamId1Name: teamId1Name,
      teamId1OwnerUid: teamId1OwnerUid,
      teamId2Name: teamId2Name,
      teamId2OwnerUid: teamId2OwnerUid,
      tournamentId: tournamentId,
    );

    _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(match.matchId)
        .set({
          ...match.toMap(),
          'tournamentId': tournamentId,
          'teamId1Name': teamId1Name,
          'teamId1OwnerUid': teamId1OwnerUid,
          'teamId2Name': teamId2Name,
          'teamId2OwnerUid': teamId2OwnerUid,
          'noballFlag': noballFlag,
          'wideFlag': wideFlag,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .catchError((_) {});

    return match;
  }

  // ── Tournament helpers ─────────────────────────────────────────────────────

  Future<void> addTeamToTournament({
    required String tournamentId,
    required String teamId,
  }) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .set({'teamId': teamId, 'addedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}
