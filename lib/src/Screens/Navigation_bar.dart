import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:TURF_TOWN_/src/views/active_connections_page.dart';

class Navigation_bar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Navigation_bar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<Navigation_bar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<Navigation_bar>
    with SingleTickerProviderStateMixin {
  bool _showSemiCircle = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSemiCircle() {
    HapticFeedback.mediumImpact();
    setState(() => _showSemiCircle = !_showSemiCircle);
    if (_showSemiCircle) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _closeSemiCircle() {
    if (_showSemiCircle) {
      setState(() => _showSemiCircle = false);
      _animController.reverse();
    }
  }

  void _navigateToConnections() {
    _closeSemiCircle();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveConnectionsPage(),
      ),
    );
  }

  Color _getSelectedColor(int index) {
    switch (index) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.purple;
      case 2:
        return Colors.green;
      case 3:
        return Colors.amber;
      case 4:
   return const Color(0xFF00C4FF);
      default:
        return Colors.white;
    }
  }

  Color _getBackgroundColor(int index) {
    switch (index) {
      case 0:
        return Colors.orange.withOpacity(0.3);
      case 1:
        return Colors.purple.withOpacity(0.3);
      case 2:
        return Colors.green.withOpacity(0.3);
      case 3:
        return Colors.amber.withOpacity(0.3);
      case 4:
       return const Color(0xFF00C4FF).withOpacity(0.15);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ── Dismiss overlay when tapping outside semicircle ──────────
        if (_showSemiCircle)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: -600,
            child: GestureDetector(
              onTap: _closeSemiCircle,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

        // ── Main bottom nav bar ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E3F), Color(0xFF2A2A5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: widget.currentIndex,
                onTap: (index) {
             widget.onTap(index);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: _getSelectedColor(widget.currentIndex),
                unselectedItemColor: Colors.white.withOpacity(0.5),
                selectedFontSize: 12,
                unselectedFontSize: 10,
                elevation: 0,
                selectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.stadium, 0),
                    label: 'Venue',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.history, 1),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildCenterHomeIcon(),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.emoji_events, 3),
                    label: 'Tournaments',
                  ),
          BottomNavigationBarItem(
                 icon: _buildNavIcon(Icons.link_rounded, 4),
                    label: 'Connections',
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Semicircle menu above home button ─────────────────────────
        Positioned(
          bottom: 55,
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
            child: _showSemiCircle
                ? SizedBox(
                    width: 180,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Semicircle background
                        CustomPaint(
                          size: const Size(180, 110),
                          painter: _SemiCirclePainter(),
                        ),
                        // Connections button centered in arc
                        Positioned(
                          top: 16,
                          child: _buildSemiCircleButton(
                            icon: Icons.device_hub_rounded,
                            label: 'Connections',
                            color: const Color(0xFF00C4FF),
                            onTap: _navigateToConnections,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // ── Double-tap detector layered over the home icon ─────────────
        // translucent behavior: single taps pass straight through to the
        // BottomNavigationBar underneath (so normal Home navigation is
        // untouched); only a genuine double-tap is intercepted here.
     
      ],
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = widget.currentIndex == index;
    final selectedColor = _getSelectedColor(index);
    final backgroundColor = _getBackgroundColor(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: selectedColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected
            ? selectedColor
            : Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildCenterHomeIcon() {
    final isSelected = widget.currentIndex == 2;
    final selectedColor = _getSelectedColor(2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  selectedColor,
                  selectedColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF3D3D6B), Color(0xFF2A2A5E)],
              ),
     boxShadow: [
          if (isSelected)
            BoxShadow(
              color: selectedColor.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
   child: const Icon(
        Icons.home_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSemiCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1E3F),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Semicircle background painter ─────────────────────────────────────────

class _SemiCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF1A1A3E).withOpacity(0.97)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF00C4FF).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height)
      ..arcToPoint(
        Offset(size.width, size.height),
        radius: Radius.circular(size.width / 2),
        clockwise: false,
      )
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}