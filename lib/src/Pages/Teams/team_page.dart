import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/team_members_page.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/utils/name_formatter.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = const Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
}

class NewTeamsPage extends StatefulWidget {
  const NewTeamsPage({super.key});

  @override
  State<NewTeamsPage> createState() => _NewTeamsPageState();
}

class _NewTeamsPageState extends State<NewTeamsPage> {
  final _fs = FirestoreService.instance;
  List<Team> teams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final loadedTeams = await _fs.getMyTeams();
      if (mounted) {
        setState(() {
          teams = loadedTeams;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Error loading teams: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _createNewTeam() async {
    final teamName = await _showTeamNameDialog();
    if (teamName == null || teamName.trim().isEmpty) return;
    final formatted = formatTeamName(teamName); 
    final trimmed = teamName.trim();
    final capitalized =
        trimmed.isEmpty ? trimmed : trimmed[0].toUpperCase() + trimmed.substring(1);

    try {
      final team = await _fs.createTeam(formatted);
      setState(() => teams.add(team));
      _showSnackBar('Team "$formatted" created!', Colors.green);
    } catch (e) {
      _showSnackBar('$e', Colors.red);
    }
  }

  Future<String?> _showTeamNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2026),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Team',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Enter Team Name',
                  hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E), fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF00C4FF), width: 2)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (_) =>
                    Navigator.of(dialogContext).pop(controller.text),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: Colors.white70, fontFamily: 'Poppins')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C4FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteTeam(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Delete Team',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${team.teamName}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _fs.deleteTeam(team.teamId);
                setState(
                    () => teams.removeWhere((t) => t.teamId == team.teamId));
                _showSnackBar('Team "${team.teamName}" deleted', Colors.orange);
              } catch (e) {
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF283593),
                Color(0xFF1A237E),
                Color(0xFF000000)
              ],
              stops: [0.0, 0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00C4FF)))
                      : teams.isEmpty
                          ? _buildEmptyState()
                          : _buildTeamsList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewTeam,
          backgroundColor: const Color(0xFF00C4FF),
          child: const Icon(Icons.add, size: 32),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Teams',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600)),
          Row(
            children: const [
              SizedBox(width: 10),
              Icon(Icons.support_agent, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Opacity(
                  opacity: 0.90,
                  child: Icon(Icons.settings, color: Colors.white, size: 26)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No teams yet',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 20,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text('Tap + to create a team',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) => _buildTeamCard(teams[index]),
    );
  }

  Widget _buildTeamCard(Team team) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TeamMembersPage(team: team)),
        ).then((_) => _loadTeams());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00C4FF).withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group,
                    color: Color(0xFF00C4FF), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.teamName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                    team.teamCount > 0
                        ? Text('${team.teamCount} players',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Poppins'))
                        : Text('Tap to add players',
                            style: TextStyle(
                                color:
                                    const Color(0xFF00C4FF).withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteTeam(team),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.sports_cricket,
                label: 'Toss',
                isSelected: false,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                icon: Icons.group,
                label: 'Teams',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C4FF).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF00C4FF)
                    : Colors.white70,
                size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF00C4FF)
                        : Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}