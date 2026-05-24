// firestore_service.dart
// Thin service used by TeamNameScreen and TeamPage.
// All heavy data lives in local in-memory caches backed by Firestore
// fire-and-forget writes — the app never blocks on Firestore.

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

  // ── Path helpers ──────────────────────────────────────────────────────────

  /// /users/{uid}/teams
  CollectionReference<Map<String, dynamic>> get _teamsCol =>
      _db.collection('users').doc(_uid).collection('teams');

  /// /users/{uid}/teams/{teamId}/members
  CollectionReference<Map<String, dynamic>> _membersCol(String teamId) =>
      _db.collection('users').doc(_uid).collection('teams').doc(teamId).collection('members');

  // ── Teams ──────────────────────────────────────────────────────────────────

  /// Returns teams owned by the current user, populating the Team cache.
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

  /// Creates a team in the local cache and persists to Firestore.
  Future<Team> createTeam({
    required String teamName,
    int teamCount = 0,
    String ownerName = '',
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

  // ── Players ────────────────────────────────────────────────────────────────

  /// Loads players for a team from Firestore into the TeamMember cache.
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

  /// Called by TeamMembersScreen and TeamMembersPage.
  /// Accepts ownerUid for compatibility but loads by teamId only.
  Future<List<TeamMember>> getPlayers(
      String ownerUid, String teamId) async {
    return getTeamPlayers(teamId);
  }

  /// Adds a player to a team in the local cache and persists to Firestore.
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
    } catch (_) {}
    return m;
  }

  /// Updates a player's display name in Firestore and local cache.
  Future<void> updatePlayerName(
    String ownerUid,
    String teamId,
    String playerId,
    String newName,
  ) async {
    try {
      await _membersCol(teamId).doc(playerId).update({'teamName': newName});
      // Update local cache
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

  /// Deletes a player from Firestore and local cache.
  Future<void> deletePlayer(
    String ownerUid,
    String teamId,
    String playerId,
  ) async {
    try {
      await _membersCol(teamId).doc(playerId).delete();
      TeamMember.removeFromCache(playerId);
      // Keep team count in sync
      final team = Team.getById(teamId);
      if (team != null) {
        team.updateCountSync(TeamMember.getByTeamId(teamId).length);
      }
    } catch (_) {}
  }

  // ── Match ──────────────────────────────────────────────────────────────────

  /// Creates a match synchronously in the local cache and fires-and-forgets
  /// the Firestore write. TeamPage calls this method.
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