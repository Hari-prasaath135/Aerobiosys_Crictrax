import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/InitialTeamPage.dart';
import 'team_members.dart';
import '../../models/team_storage.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';


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

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF140088),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const TeamNameScreen(),
    );
  }
}

class TeamNameScreen extends StatefulWidget {
  const TeamNameScreen({super.key});

  @override
  State<TeamNameScreen> createState() => _TeamNameScreenState();
}

class _TeamNameScreenState extends State<TeamNameScreen> {
  List<Team> teams = [];
  int _selectedIndex = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => isLoading = true);
    final loadedTeams = await TeamStorage.getTeams();
    if (mounted) {
      setState(() {
        teams = loadedTeams;
        isLoading = false;
      });
    }
  }

  bool _isValidTeamName(String name) {
    if (name.trim().isEmpty) return false;
    return !RegExp(r'\d').hasMatch(name);
  }

 void _onBottomNavTap(int index) {
  if (index == 0) {
    // Navigate back to Toss page (InitialTeamPage)
    Navigator.pop(context);
  } else if (index == 1) {
    // Already on Teams page
    setState(() {
      _selectedIndex = 1;
    });
  }
}

  void _showAddTeamModal() {
    final TextEditingController teamNameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Team Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.065,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: teamNameController,
                  autofocus: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Team Name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF5C5C5E),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF2B7790),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String teamName = teamNameController.text
                          .trim()
                          .toUpperCase();

                      if (teamName.isEmpty) {
                        // Show SnackBar BEFORE popping dialog for empty name
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a team name!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Don't pop the dialog
                      }

                      if (!_isValidTeamName(teamName)) {
                        // Show SnackBar BEFORE popping dialog for invalid name
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Team name should not contain numbers!',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Don't pop the dialog
                      }

                      // Check for duplicate team names
                      bool teamExists = teams.any(
                        (team) =>
                            team.name.toLowerCase() == teamName.toLowerCase(),
                      );
                      if (teamExists) {
                        // Show SnackBar BEFORE popping dialog for duplicate
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Team name already exists!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Don't pop the dialog
                      }

                      // Close dialog FIRST
                      Navigator.of(dialogContext).pop();

                      // Dispose controller
                      teamNameController.dispose();

                      // Add team to storage
                      final newTeam = Team(name: teamName, players: []);
                      await TeamStorage.addTeam(newTeam);

                      // Reload teams
                      await _loadTeams();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7790),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width * 0.04,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editTeam(int index) {
    final TextEditingController editController = TextEditingController(
      text: teams[index].name,
    );
    final String oldTeamName = teams[index].name;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Team Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.065,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: editController,
                  autofocus: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Team Name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF5C5C5E),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF2B7790),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String teamName = editController.text
                          .trim()
                          .toUpperCase();

                      if (teamName.isEmpty || !_isValidTeamName(teamName)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid team name!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Don't pop the dialog
                      }

                      // Check for duplicate (excluding current team)
                      bool teamExists = teams.any(
                        (team) =>
                            team.name.toLowerCase() == teamName.toLowerCase() &&
                            team.name != oldTeamName,
                      );
                      if (teamExists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Team name already exists!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Don't pop the dialog
                      }

                      // Close dialog FIRST
                      Navigator.of(dialogContext).pop();

                      // Dispose controller
                      editController.dispose();

                      // Update team in storage
                      final updatedTeam = Team(
                        name: teamName,
                        players: teams[index].players,
                      );
                      await TeamStorage.updateTeam(oldTeamName, updatedTeam);

                      // Reload teams
                      await _loadTeams();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7790),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width * 0.04,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteTeam(int index) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3C3C3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Team',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: Text(
            'Are you sure you want to delete "${teams[index].name}"?',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Delete from storage
                await TeamStorage.deleteTeam(teams[index].name);

                // Reload teams
                await _loadTeams();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF39375F),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.casino_outlined,
            activeIcon: Icons.casino,
            label: 'Toss',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            label: 'Teams',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isActive)
            Positioned(
              top: -35,
              child: AnimatedContainer(
  duration: const Duration(milliseconds: 400), // Changed from 300
  curve: Curves.easeInOutCubic,
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E46A6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4E46A6).withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(activeIcon, color: Colors.white, size: 30),
                ),
              ),
            ),

          AnimatedContainer(
  duration: const Duration(milliseconds: 400), // Changed from 300
  curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isActive)
                  Icon(icon, color: const Color(0xFFB0B3C6), size: 24),
                if (!isActive) const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFB0B3C6),
                    fontSize: isActive ? 13 : 11,
                    fontFamily: 'Poppins',
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: Scaffold(
        extendBody: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF140088), Colors.black],
              stops: [0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2B7790)),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(w * 0.04),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Cricket ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: w * 0.1,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Scorer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: w * 0.05,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.support_agent,
                                      color: Colors.white,
                                      size: w * 0.065,
                                    ),
                                    SizedBox(width: w * 0.025),
                                    Icon(
                                      Icons.sports_cricket,
                                      color: Colors.white.withOpacity(0.9),
                                      size: w * 0.065,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: teams.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 100,
                                      ),
                                      child: Text(
                                        'No teams added yet.\nTap + to add a team.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: w * 0.045,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(
                                      left: w * 0.04,
                                      right: w * 0.04,
                                      top: w * 0.02,
                                      bottom: 100,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Teams',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: w * 0.06,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: w * 0.04),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: teams.length,
                                            itemBuilder: (context, index) {
                                              return InkWell(
                                                onTap: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TeamMembersScreen(
                                                            teamName:
                                                                teams[index]
                                                                    .name,
                                                          ),
                                                    ),
                                                  );
                                                  await _loadTeams();
                                                },
                                                child: Container(
                                                  key: ValueKey('team_$index'),
                                                  margin: EdgeInsets.only(
                                                    bottom: w * 0.04,
                                                  ),
                                                  padding: EdgeInsets.all(
                                                    w * 0.045,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        const Color(
                                                          0xFF2B7790,
                                                        ).withOpacity(0.3),
                                                        const Color(
                                                          0xFF1E1E1E,
                                                        ).withOpacity(0.8),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF2B7790,
                                                      ).withOpacity(0.5),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF2B7790,
                                                        ).withOpacity(0.2),
                                                        blurRadius: 15,
                                                        offset: const Offset(
                                                          0,
                                                          5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          w * 0.025,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF2B7790,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Image.asset(
                                                          'assets/images/costumer.png',
                                                          width: w * 0.06,
                                                          height: w * 0.06,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: w * 0.03),

                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              teams[index].name,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize:
                                                                    w * 0.05,
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${teams[index].players.length} players',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.6,
                                                                    ),
                                                                fontSize:
                                                                    w * 0.035,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      GestureDetector(
                                                        onTap: () =>
                                                            _editTeam(index),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                w * 0.02,
                                                              ),
                                                          child: Icon(
                                                            Icons.edit_outlined,
                                                            color: const Color(
                                                              0xFF2B7790,
                                                            ),
                                                            size: w * 0.055,
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(width: w * 0.02),

                                                      GestureDetector(
                                                        onTap: () =>
                                                            _deleteTeam(index),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                w * 0.02,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors.red,
                                                            size: w * 0.055,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTeamModal,
          backgroundColor: const Color(0xFF2B7790),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}
