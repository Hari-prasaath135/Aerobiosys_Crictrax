import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Team {
  final String name;
  final List<String> players;
  final String? captain;

  Team({
    required this.name,
    required this.players,
    this.captain,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'players': players,
    'captain': captain,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    name: json['name'],
    players: List<String>.from(json['players']),
    captain: json['captain'],
  );
}

class TeamStorage {
  static const String _teamsKey = 'teams_data';

  static Future<void> saveTeams(List<Team> teams) async {
    final prefs = await SharedPreferences.getInstance();
    final teamsJson = teams.map((team) => team.toJson()).toList();
    await prefs.setString(_teamsKey, jsonEncode(teamsJson));
  }

  static Future<List<Team>> getTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsString = prefs.getString(_teamsKey);
    
    if (teamsString == null || teamsString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> teamsJson = jsonDecode(teamsString);
      return teamsJson.map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // FIXED: Now uses consistent storage key and proper logic
  static Future<void> updateTeamCaptain(String teamName, String? captainName) async {
    final teams = await getTeams();
    final index = teams.indexWhere((team) => team.name == teamName);
    
    if (index != -1) {
      teams[index] = Team(
        name: teams[index].name,
        players: teams[index].players,
        captain: captainName,
      );
      
      await saveTeams(teams);
    }
  }

  static Future<void> addTeam(Team team) async {
    final teams = await getTeams();
    teams.add(team);
    await saveTeams(teams);
  }

  static Future<void> deleteTeam(String teamName) async {
    final teams = await getTeams();
    teams.removeWhere((team) => team.name == teamName);
    await saveTeams(teams);
  }

  static Future<void> updateTeam(String oldName, Team newTeam) async {
    final teams = await getTeams();
    final index = teams.indexWhere((team) => team.name == oldName);
    if (index != -1) {
      teams[index] = newTeam;
      await saveTeams(teams);
    }
  }
  
  static Future<void> addPlayerToTeam(String teamName, String playerName) async {
    final teams = await getTeams();
    final index = teams.indexWhere((team) => team.name == teamName);
    if (index != -1) {
      teams[index].players.add(playerName);
      await saveTeams(teams);
    }
  }

  static Future<void> removePlayerFromTeam(String teamName, String playerName) async {
    final teams = await getTeams();
    final index = teams.indexWhere((team) => team.name == teamName);
    if (index != -1) {
      teams[index].players.remove(playerName);
      
      // If the removed player was the captain, remove captain status
      if (teams[index].captain == playerName) {
        teams[index] = Team(
          name: teams[index].name,
          players: teams[index].players,
          captain: null,
        );
      }
      
      await saveTeams(teams);
    }
  }

  static Future<void> updatePlayerInTeam(String teamName, String oldPlayerName, String newPlayerName) async {
    final teams = await getTeams();
    final index = teams.indexWhere((team) => team.name == teamName);
    if (index != -1) {
      final playerIndex = teams[index].players.indexOf(oldPlayerName);
      if (playerIndex != -1) {
        teams[index].players[playerIndex] = newPlayerName;
        
        // If the updated player was the captain, update captain name too
        if (teams[index].captain == oldPlayerName) {
          teams[index] = Team(
            name: teams[index].name,
            players: teams[index].players,
            captain: newPlayerName,
          );
        }
        
        await saveTeams(teams);
      }
    }
  }

  static Future<Team?> getTeamByName(String teamName) async {
    final teams = await getTeams();
    try {
      return teams.firstWhere((team) => team.name == teamName);
    } catch (e) {
      return null;
    }
  }
}