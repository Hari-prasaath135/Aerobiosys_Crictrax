// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/match_storage.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:uuid/uuid.dart';

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

  Future<Team> createTeam(
    String teamName, {
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

  Future<void> deleteTeam(String teamId) async {
    try {
      final membersSnap = await _membersCol(teamId).get();
      for (final doc in membersSnap.docs) {
        await doc.reference.delete();
        TeamMember.removeFromCache(doc.id);
      }
      await _teamsCol.doc(teamId).delete();
      Team.removeFromCache(teamId);
    } catch (_) {}
  }

  // ✅ NEW METHOD: Update team count in Firestore
  Future<void> updateTeamCount(String teamId, int newCount) async {
    try {
      await _teamsCol.doc(teamId).update({
        'teamCount': newCount,
      });
      
      // ✅ Also update the in-memory cache if you're using it
      final team = Team.getById(teamId);
      if (team != null) {
        team.updateCountSync(newCount);
      }
    } catch (e) {
      // Silently fail or log error
      print('❌ Error updating team count: $e');
    }
  }

  // ── Players ────────────────────────────────────────────────────────────────

  Future<List<TeamMember>> getTeamPlayers(String teamId) async {
    try {
      final snap = await _membersCol(teamId).get();
      final members = <TeamMember>[];
      for (final doc in snap.docs) {
        final m = TeamMember.fromMap({
          ...doc.data(),
          'teamOwnerUid': _uid,
        });
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
    String teamName = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Auto-fetch real team name from Firestore if caller didn't supply it
    String resolvedTeamName = teamName.trim();
    if (resolvedTeamName.isEmpty) {
      try {
        final teamDoc = await _db
            .collection('users')
            .doc(uid)
            .collection('teams')
            .doc(teamId)
            .get();
        resolvedTeamName = teamDoc.data()?['teamName'] as String? ?? '';
      } catch (_) {}
    }

    // ✅ Write directly to Firestore with correct field separation
    // Then build the in-memory object via fromMap
    final playerId = const Uuid().v4();
    final docData = {
      'playerId':     playerId,
      'teamId':       teamId,
      'playerName':   playerName.trim(),  // ✅ e.g. "markram"
      'teamName':     resolvedTeamName,   // ✅ e.g. "Srh"
      'role':         '',
      'teamOwnerUid': uid,
    };

    // ✅ Write to Firestore first — guaranteed correct fields
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(playerId)
          .set(docData);
    } catch (_) {}

    // ✅ Build in-memory object from the same map we just wrote
    // fromMap reads playerName correctly from the map above
    final member = TeamMember.fromMap(docData);
    return member;
  }

  Future<void> updatePlayerName(
    String ownerUid,
    String teamId,
    String playerId,
    String newName,
  ) async {
    try {
      // ✅ Update playerName field in Firestore
      await _membersCol(teamId).doc(playerId).update({
        'playerName': newName,
      });

      // ✅ Re-fetch the doc from Firestore to get the current teamName
      // This avoids any in-memory state issues with old model versions
      final docSnap = await _membersCol(teamId).doc(playerId).get();
      if (docSnap.exists) {
        final updated = TeamMember.fromMap({
          ...docSnap.data()!,
          'teamOwnerUid': _uid,
        });
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