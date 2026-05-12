import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart';
import 'package:TURF_TOWN_/src/views/history_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/tournament_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/playerselection_page.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/match_history.dart';
import 'package:TURF_TOWN_/src/models/match_storage.dart';
import 'package:TURF_TOWN_/src/models/player_storage.dart';

class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}
void main() => runApp(const FigmaToCodeApp());

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A237E),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const TeamPage(),
    );
  }
}

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final TextEditingController oversController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool additionalSettings = false;
  
  String? team1Id;
  String? team2Id;
  String? tossWinnerTeamId;
  String? tossDecision; // 'bat' or 'bowl'
  
  // Add these new variables for match settings
  bool allowNoball = true;
  bool allowWide = true;
  
  List<Team> allTeams = [];
  bool isLoadingTeams = true;
  
  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = Team.getAll();
      setState(() {
        allTeams = teams;
        isLoadingTeams = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTeams = false;
      });
      _showSnackBar('Error loading teams: $e', Colors.red);
    }
  }

  

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  void dispose() {
    oversController.dispose();
    super.dispose();
  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Reload teams whenever the page comes into focus
  _loadTeams();
}

  void _startMatch() {
  // Validate all fields
  if (team1Id == null || team2Id == null) {
    _showSnackBar('Please select both teams', Colors.red);
    return;
  }

  if (team1Id == team2Id) {
    _showSnackBar('Teams cannot be the same', Colors.red);
    return;
  }

  if (tossWinnerTeamId == null) {
    _showSnackBar('Please select toss winner', Colors.red);
    return;
  }

  if (tossDecision == null) {
    _showSnackBar('Please select toss decision', Colors.red);
    return;
  }

  if (oversController.text.trim().isEmpty) {
    _showSnackBar('Please enter number of overs', Colors.red);
    return;
  }

  final overs = int.tryParse(oversController.text.trim());
  if (overs == null || overs <= 0) {
    _showSnackBar('Please enter a valid number of overs', Colors.red);
    return;
  }

  // Create match in database
  try {
    final match = MatchStorage.createMatch(
      teamId1: team1Id!,
      teamId2: team2Id!,
      tossWonBy: tossWinnerTeamId!,
      chooseToBat: tossDecision == 'bat',
      allowNoball: allowNoball,
      allowWide: allowWide,
      overs: overs, // Add this line
    );

     _showSnackBar('Match ${match.matchId} created successfully!', Colors.green);
    
    // Get team names for navigation
    final team1 = Team.getById(team1Id!);
    final team2 = Team.getById(team2Id!);
    
    // Determine batting and bowling teams based on toss decision
    String battingTeamName;
    String bowlingTeamName;
    
    if (tossDecision == 'bat') {
      // Toss winner bats first
      battingTeamName = tossWinnerTeamId == team1Id ? team1!.teamName : team2!.teamName;
      bowlingTeamName = tossWinnerTeamId == team1Id ? team2!.teamName : team1!.teamName;
    } else {
      // Toss winner bowls first (opponent bats)
      battingTeamName = tossWinnerTeamId == team1Id ? team2!.teamName : team1!.teamName;
      bowlingTeamName = tossWinnerTeamId == team1Id ? team1!.teamName : team2!.teamName;
    }
    
    // Navigate to SelectPlayersPage
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SelectPlayersPage(
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      totalOvers: overs,
      matchId: match.matchId, // 🔥 ADD THIS
    ),
  ),
);
    
  } catch (e) {
    _showSnackBar('Error creating match: $e', Colors.red);
  }
}
  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      }
    },
    child: GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left (velocity is negative) -> go to Teams page
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          Navigator.push(
            context,
            SmoothPageRoute(page: const NewTeamsPage()),
          ).then((_) => _loadTeams());
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        drawer: _buildDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
              stops: [0.0, 0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: _buildHeader(MediaQuery.of(context).size.width),
                ),
                Expanded(
                  child: isLoadingTeams
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C4FF),
                          ),
                        )
                      : _buildTossPage(),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    ),
  );
}

  Widget _buildTossPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.only(
                  left: w * 0.04,
                  right: w * 0.04,
                  top: w * 0.02,
                  bottom: w * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamsSection(w),
                    SizedBox(height: h * 0.025),
                    _buildTossDetailsSection(w),
                    SizedBox(height: h * 0.025),
                    _buildOversSection(w),
                    SizedBox(height: h * 0.04),
                    _buildBottomRow(w),
                    SizedBox(height: h * 0.025),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildDrawer() {
  return Drawer(
    backgroundColor: const Color(0xFF1C2026),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF283593), Color(0xFF1A237E)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.sports_cricket, color: Color(0xFF00C4FF), size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Cricket Scorer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your cricket matches',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // Home
        ListTile(
          leading: const Icon(Icons.home, color: Color(0xFF00C4FF)),
          title: const Text('Home', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
              (route) => false,
            );
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // New Match (Current Page)
        ListTile(
          leading: const Icon(Icons.add_circle, color: Color(0xFF00C4FF)),
          title: const Text('New Match', style: TextStyle(color: Colors.white)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C4FF), width: 1),
            ),
            child: const Text(
              'Current',
              style: TextStyle(
                color: Color(0xFF00C4FF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // Teams
        ListTile(
          leading: const Icon(Icons.group, color: Colors.white),
          title: const Text('Teams', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'Manage teams & players',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              SmoothPageRoute(page: const NewTeamsPage()),
            );
            _loadTeams();
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // Tournaments  ← THIS WAS MISSING
        ListTile(
          leading: const Icon(Icons.emoji_events, color: Colors.white),
          title: const Text(
            'Tournaments',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Create & manage tournaments',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TournamentPage(),
              ),
            );
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // History
        ListTile(
          leading: const Icon(Icons.history, color: Colors.white),
          title: const Text('Match History', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'View past & paused matches',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          trailing: _buildMatchCountBadge(),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // Statistics (Future feature)
        ListTile(
          leading: Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.5)),
          title: Text('Statistics', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          subtitle: Text(
            'Coming soon',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Statistics feature coming soon!'),
                backgroundColor: Color(0xFF00C4FF),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        // Settings
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'App preferences',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          onTap: () {
            Navigator.pop(context);
            _showSettingsDialog();
          },
        ),

        const Divider(color: Colors.white24, height: 1),

        const SizedBox(height: 20),

        // App Version at bottom
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                'Cricket Scorer v1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 Turf Town',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// Helper method to build match count badge
Widget _buildMatchCountBadge() {
  final allMatches = MatchHistory.getAll();
  final count = allMatches.length;
  
  if (count == 0) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF00C4FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// Settings Dialog
void _showSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C2026),
      title: const Row(
        children: [
          Icon(Icons.settings, color: Color(0xFF00C4FF)),
          SizedBox(width: 12),
          Text('Settings', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white70),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
              },
              activeColor: const Color(0xFF00C4FF),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.white70),
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement theme toggle
              },
              activeColor: const Color(0xFF00C4FF),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.vibration, color: Colors.white70),
            title: const Text('Vibration', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement vibration toggle
              },
              activeColor: const Color(0xFF00C4FF),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF00C4FF)),
          ),
        ),
      ],
    ),
  );
}

// About Dialog
void _showAboutDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C2026),
      title: const Row(
        children: [
          Icon(Icons.sports_cricket, color: Color(0xFF00C4FF), size: 28),
          SizedBox(width: 12),
          Text('About Cricket Scorer', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cricket Scorer',
            style: TextStyle(
              color: Color(0xFF00C4FF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'A comprehensive cricket scoring application to manage teams, track matches, and generate detailed scorecards.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildAboutRow(Icons.code, 'Developed by', 'Turf Town Team'),
          const SizedBox(height: 8),
          _buildAboutRow(Icons.calendar_today, 'Release Date', 'February 2026'),
          const SizedBox(height: 8),
          _buildAboutRow(Icons.email, 'Contact', 'support@turftown.com'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF00C4FF)),
          ),
        ),
      ],
    ),
  );
}

// Helper for About dialog rows
Widget _buildAboutRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, color: const Color(0xFF00C4FF), size: 16),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
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
            offset: const Offset(0, -2),
          ),
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
                isSelected: true,
                onTap: () {},
              ),
     _buildNavItem(
  icon: Icons.group,
  label: 'Teams',
  isSelected: false,
  onTap: () async {
    await Navigator.push(
      context,
      SmoothPageRoute(page: const NewTeamsPage()),  // Changed this line
    );
    _loadTeams();
  },
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C4FF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double w) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Icon(
            Icons.menu,
            color: Colors.white,
            size: w * 0.07,
          ),
        ),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Cricket ', style: _textStyle(w * 0.1)),
                  TextSpan(text: 'Scorer', style: _textStyle(w * 0.05)),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            _buildSvgIcon('assets/ix_support.svg', w * 0.065),
            SizedBox(width: w * 0.025),
            Opacity(
              opacity: 0.90,
              child: _buildSvgIcon('assets/Group.svg', w * 0.065),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Teams', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildTeamDropdown('Team 1', team1Id, w, (value) {
            setState(() => team1Id = value);
          }),
          SizedBox(height: w * 0.03),
          _buildTeamDropdown('Team 2', team2Id, w, (value) {
            setState(() => team2Id = value);
          }),
        ],
      ),
    );
  }

  Widget _buildTeamDropdown(String label, String? selectedTeamId, double w, Function(String?) onChanged) {
  return Row(
    children: [
      SizedBox(
        width: w * 0.2,
        child: Text(label, style: _textStyle(w * 0.034)),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => _showTeamSelectionDialog(label, selectedTeamId, onChanged),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF5C5C5E),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedTeamId != null
                        ? Team.getById(selectedTeamId)?.teamName ?? 'Select Team'
                        : 'Select Team',
                    style: _textStyle(
                      w * 0.034,
                      null,
                      selectedTeamId != null ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

void _showTeamSelectionDialog(String label, String? currentTeamId, Function(String?) onChanged) {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // ✅ Get fresh teams every time dialog rebuilds
        final freshTeams = Team.getAll();

        String? otherTeamId;
        if (label == 'Team 1') {
          otherTeamId = team2Id;
        } else if (label == 'Team 2') {
          otherTeamId = team1Id;
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF1C2026),
          title: Text('Select $label', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: freshTeams.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No teams available.\nPlease create teams first.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: freshTeams.length,
                    itemBuilder: (context, index) {
                      final team = freshTeams[index];
                      final isSelected = team.teamId == currentTeamId;
                      final isOtherTeam = team.teamId == otherTeamId;

                      final actualPlayerCount = PlayerStorage.getTeamPlayerCount(team.teamId);
                      final bool hasInvalidPlayerCount = actualPlayerCount < 2 || actualPlayerCount > 11;
                      final isDisabled = isOtherTeam || hasInvalidPlayerCount;

                      String subtitle;
                      if (isOtherTeam) {
                        subtitle = 'Already selected';
                      } else if (hasInvalidPlayerCount) {
                        if (actualPlayerCount < 2) {
                          subtitle = '$actualPlayerCount player${actualPlayerCount == 1 ? '' : 's'} (Minimum 2 required)';
                        } else {
                          subtitle = '$actualPlayerCount players (Maximum 11 allowed)';
                        }
                      } else {
                        subtitle = '$actualPlayerCount players';
                      }

                      return Opacity(
                        opacity: isDisabled ? 0.4 : 1.0,
                        child: ListTile(
                          enabled: !isDisabled,
                          title: Text(
                            team.teamName,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00C4FF) : Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: TextStyle(
                              color: isDisabled ? Colors.red.shade300 : Colors.white60,
                              fontSize: 12
                            ),
                          ),
                          leading: Icon(
                            Icons.group,
                            color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                              : isDisabled
                                  ? const Icon(Icons.block, color: Colors.red)
                                  : GestureDetector(
                                      onTap: () async {
                                        // ✅ Close this dialog first
                                        Navigator.pop(context);
                                        
                                        // ✅ Show add players dialog
                                        await _showAddPlayersDialogWithRefresh(team);
                                        
                                        // ✅ Reopen team selection dialog with updated data
                                        _showTeamSelectionDialog(label, currentTeamId, onChanged);
                                      },
                                      child: const Icon(Icons.add_circle_outline, color: Color(0xFF00C4FF)),
                                    ),
                          onTap: isDisabled ? null : () {
                            onChanged(team.teamId);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showAddPlayersDialogWithRefresh(Team team) async {
  TextEditingController playerNameController = TextEditingController();

  final existingPlayers = PlayerStorage.getPlayersByTeam(team.teamId);
  final existingPlayerNames = existingPlayers.map((p) => p.teamName.toLowerCase()).toSet();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C2026),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Player to ${team.teamName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final actualCount = PlayerStorage.getTeamPlayerCount(team.teamId);
                    return Text(
                      'Current: $actualCount/11 players',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    );
                  },
                ),
              ],
            ),
            content: TextField(
              controller: playerNameController,
              maxLength: 30,
              autofocus: true,
              style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Enter player name',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                filled: true,
                fillColor: const Color(0xFFD9D9D9),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) {
                _addPlayerAndUpdate(
                  playerNameController,
                  team,
                  existingPlayerNames,
                  setDialogState,
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _addPlayerAndUpdate(
                    playerNameController,
                    team,
                    existingPlayerNames,
                    setDialogState,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C4FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
void _showAddPlayersDialog(Team team) {
  // Don't store controller as final - let it be garbage collected
  TextEditingController playerNameController = TextEditingController();

  final existingPlayers = PlayerStorage.getPlayersByTeam(team.teamId);
  final existingPlayerNames = existingPlayers.map((p) => p.teamName.toLowerCase()).toSet();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C2026),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Player to ${team.teamName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final actualCount = PlayerStorage.getTeamPlayerCount(team.teamId);
                    return Text(
                      'Current: $actualCount/11 players',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    );
                  },
                ),
              ],
            ),
            content: TextField(
              controller: playerNameController,
              maxLength: 30,
              autofocus: true,
              style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Enter player name',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                filled: true,
                fillColor: const Color(0xFFD9D9D9),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) {
                _addPlayerAndUpdate(
                  playerNameController,
                  team,
                  existingPlayerNames,
                  setDialogState,
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _addPlayerAndUpdate(
                    playerNameController,
                    team,
                    existingPlayerNames,
                    setDialogState,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C4FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
  // ✅ NO DISPOSAL - Let Flutter's garbage collector handle it
  // This is safe because the controller will be automatically cleaned up
  // when there are no more references to it
}


void _addPlayerAndUpdate(
  TextEditingController controller,
  Team team,
  Set<String> existingPlayerNames,
  StateSetter setDialogState,
) {
  final playerName = controller.text.trim();

  // Validation
  if (playerName.isEmpty) {
    _showSnackBar('Please enter a player name', Colors.orange);
    return;
  }

  if (playerName.length < 2) {
    _showSnackBar('Player name must be at least 2 characters', Colors.orange);
    return;
  }

  final actualPlayerCount = PlayerStorage.getTeamPlayerCount(team.teamId);
  if (actualPlayerCount >= 11) {
    _showSnackBar('Maximum 11 players allowed', Colors.red);
    return;
  }

  final lowerPlayerName = playerName.toLowerCase();

  if (existingPlayerNames.contains(lowerPlayerName)) {
    _showSnackBar('Player "$playerName" already exists in this team', Colors.red);
    return;
  }

  try {
    // Add single player to team
    PlayerStorage.addPlayer(team.teamId, playerName);

    // Get actual count from database after adding
    final newCount = PlayerStorage.getTeamPlayerCount(team.teamId);
    team.updateCount(newCount);

    // Show success message
    _showSnackBar('Player "$playerName" added to ${team.teamName}', Colors.green);

    // Clear input field
    controller.clear();

    // Refresh the dialog state to update the counter
    setDialogState(() {
      existingPlayerNames.add(lowerPlayerName);
    });

    // ✅ CRITICAL: Update the main page state immediately
    if (mounted) {
      setState(() {
        // This triggers a rebuild of the main page
        // The team selection dialog will show updated counts
      });
    }
  } catch (e) {
    _showSnackBar('Error adding player: $e', Colors.red);
  }
}

  Widget _buildTossDetailsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Toss Details', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildTossWinnerDropdown(w),
          SizedBox(height: w * 0.03),
          _buildTossDecisionDropdown(w),
        ],
      ),
    );
  }

  Widget _buildTossWinnerDropdown(double w) {
    return Row(
      children: [
        SizedBox(
          width: w * 0.2,
          child: Text('Winner', style: _textStyle(w * 0.034)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (team1Id == null || team2Id == null) {
                _showSnackBar('Please select both teams first', Colors.orange);
                return;
              }
              _showTossWinnerDialog(w);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF5C5C5E),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tossWinnerTeamId != null
                          ? Team.getById(tossWinnerTeamId!)?.teamName ?? 'Select Winner'
                          : 'Select Winner',
                      style: _textStyle(
                        w * 0.034,
                        null,
                        tossWinnerTeamId != null ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTossWinnerDialog(double w) {
    final tossTeams = [
      if (team1Id != null) Team.getById(team1Id!),
      if (team2Id != null) Team.getById(team2Id!),
    ].whereType<Team>().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Select Toss Winner', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tossTeams.map((team) {
            final isSelected = team.teamId == tossWinnerTeamId;
            return ListTile(
              title: Text(
                team.teamName,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00C4FF) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              leading: Icon(
                Icons.emoji_events,
                color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossWinnerTeamId = team.teamId);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTossDecisionDropdown(double w) {
    return Row(
      children: [
        SizedBox(
          width: w * 0.2,
          child: Text('Decision', style: _textStyle(w * 0.034)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (tossWinnerTeamId == null) {
                _showSnackBar('Please select toss winner first', Colors.orange);
                return;
              }
              _showTossDecisionDialog(w);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF5C5C5E),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tossDecision != null
                          ? tossDecision == 'bat' ? 'Bat First' : 'Bowl First'
                          : 'Select Decision',
                      style: _textStyle(
                        w * 0.034,
                        null,
                        tossDecision != null ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTossDecisionDialog(double w) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Select Toss Decision', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Bat First',
                style: TextStyle(
                  color: tossDecision == 'bat' ? const Color(0xFF00C4FF) : Colors.white,
                  fontWeight: tossDecision == 'bat' ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              leading: Icon(
                Icons.sports_cricket,
                color: tossDecision == 'bat' ? const Color(0xFF00C4FF) : Colors.white70,
              ),
              trailing: tossDecision == 'bat'
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossDecision = 'bat');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Bowl First',
                style: TextStyle(
                  color: tossDecision == 'bowl' ? const Color(0xFF00C4FF) : Colors.white,
                  fontWeight: tossDecision == 'bowl' ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              leading: Icon(
                Icons.sports_baseball,
                color: tossDecision == 'bowl' ? const Color(0xFF00C4FF) : Colors.white70,
              ),
              trailing: tossDecision == 'bowl'
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossDecision = 'bowl');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOversSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildLabeledTextField('Overs', 'Enter the overs', w),
    );
  }

 Widget _buildBottomRow(double w) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // No-ball Toggle
      Row(
        children: [
          Icon(
            Icons.sports_cricket,
            color: Colors.white70,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.03),
          SizedBox(
            width: w * 0.2,
            child: Text('No-ball', style: _textStyle(w * 0.034)),
          ),
          Switch(
            value: allowNoball,
            onChanged: (value) {
              setState(() => allowNoball = value);
            },
            activeColor: const Color(0xFF00C4FF),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
      
      SizedBox(height: w * 0.02),
      
      // Wide Toggle
      Row(
        children: [
          Icon(
            Icons.sports_baseball,
            color: Colors.white70,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.03),
          SizedBox(
            width: w * 0.2,
            child: Text('Wide', style: _textStyle(w * 0.034)),
          ),
          Switch(
            value: allowWide,
            onChanged: (value) {
              setState(() => allowWide = value);
            },
            activeColor: const Color(0xFF00C4FF),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
      
      SizedBox(height: w * 0.04),
      
      // Start Match Button (Centered)
      Center(
        child: GestureDetector(
          onTap: _startMatch,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: w * 0.035),
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start Match', style: _textStyle(w * 0.042, FontWeight.w600)),
                SizedBox(width: w * 0.025),
                _buildSvgIcon('assets/mdi_cricket.svg', w * 0.062),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
  Widget _buildLabeledTextField(String label, String placeholder, double w) {
    return Row(
      children: [
        SizedBox(
          width: w * 0.26,
          child: Text(label, style: _textStyle(w * 0.034)),
        ),
        Expanded(
          child: TextField(
            controller: oversController,
            keyboardType: TextInputType.number,
            style: _textStyle(w * 0.034, null, Colors.black),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: _textStyle(w * 0.034, null, const Color(0xFF9E9E9E)),
              filled: true,
              fillColor: const Color(0xFFD9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSvgIcon(String path, double size, {bool colored = true}) {
    return SvgPicture.asset(
path,
  width: size,
  height: size,
  colorFilter: colored ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
);}
TextStyle _textStyle(double size, [FontWeight? weight, Color? color]) {
return TextStyle(
color: color ?? Colors.white,
fontSize: size,
fontFamily: 'Poppins',
fontWeight: weight ?? FontWeight.w400,
);
}
}