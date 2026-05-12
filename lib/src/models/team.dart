import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'objectbox_helper.dart';


@Entity()
class Team {
  @Id()
  int id; // Auto-incremented
  
  @Unique()
  String teamId; // Primary key (UUID)
  
  String teamName;
  
  int teamCount; // Number of members
  
  Team({
    this.id = 0, 
    required this.teamId,
    required this.teamName,
    this.teamCount = 0,
  });

  // Static methods for database operations
  static const _uuid = Uuid();

  static Team create(String teamName) {
  final trimmedName = teamName.trim();
  
  // Validate team name
  if (trimmedName.isEmpty) {
    throw Exception('Team name cannot be empty');
  }
  
  if (trimmedName.length < 2) {
    throw Exception('Team name must be at least 2 characters');
  }
  
  if (trimmedName.length > 30) {
    throw Exception('Team name must be less than 30 characters');
  }
  
  final team = Team(
    teamId: _uuid.v4(),
    teamName: trimmedName,
    teamCount: 0,
  );
  ObjectBoxHelper.teamBox.put(team);
  return team;
}
static List<Team> getAll() {
    return ObjectBoxHelper.teamBox.getAll();
  }

  static Team? getByName(String teamName) {
    final query = ObjectBoxHelper.teamBox
        .query(Team_.teamName.equals(teamName))
        .build();
    final team = query.findFirst();
    query.close();
    return team;
  }

  static Team? getById(String teamId) {
    final query = ObjectBoxHelper.teamBox
        .query(Team_.teamId.equals(teamId))
        .build();
    final team = query.findFirst();
    query.close();
    return team;
  }

  static void deleteByName(String teamName) {
    final team = getByName(teamName);
    if (team != null) {
      ObjectBoxHelper.teamBox.remove(team.id);
    }
  }

  // Instance methods
  void save() {
    ObjectBoxHelper.teamBox.put(this);
  }

  void delete() {
    ObjectBoxHelper.teamBox.remove(id);
  }

  void updateName(String newName) {
    teamName = newName;
    save();
  }
  
  void updateCount(int count) {
    teamCount = count;
    save();
  }
}