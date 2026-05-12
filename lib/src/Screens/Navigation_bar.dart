import 'package:flutter/material.dart';

class Navigation_bar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Navigation_bar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // Define unique colors for each icon when pressed
  Color _getSelectedColor(int index) {
    switch (index) {
      case 0: // Venue
        return Colors.orange;
      case 1: // History
        return Colors.purple;
      case 2: // Home
        return Colors.green;
      case 3: // Bluetooth/Connection
        return Colors.lightBlueAccent; // Sky blue
      case 4: // Alerts
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  // Define unique background colors for each icon when pressed
  Color _getBackgroundColor(int index) {
    switch (index) {
      case 0: // Venue
        return Colors.orange.withOpacity(0.3);
      case 1: // History
        return Colors.purple.withOpacity(0.3);
      case 2: // Home
        return Colors.green.withOpacity(0.3);
      case 3: // Bluetooth/Connection
        return Colors.lightBlueAccent.withOpacity(0.3); // Sky blue background
      case 4: // Alerts
        return Colors.red.withOpacity(0.3);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: _getSelectedColor(currentIndex),
            unselectedItemColor: Colors.white.withOpacity(0.5),
            selectedFontSize: 12,
            unselectedFontSize: 10,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              // Index 0 - Venue
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.stadium, 0),
                label: 'Venue',
              ),
              // Index 1 - History
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.history, 1),
                label: 'History',
              ),
              // Index 2 - Home (Center with elevated circle)
              BottomNavigationBarItem(
                icon: _buildCenterHomeIcon(),
                label: 'Home',
              ),
              // Index 3 - Connection (Bluetooth)
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.bluetooth, 3),
                label: 'Connection',
              ),
              // Index 4 - Alerts
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.notifications, 4),
                label: 'Alerts',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = currentIndex == index;
    final selectedColor = _getSelectedColor(index);
    final backgroundColor = _getBackgroundColor(index);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? backgroundColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: selectedColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? selectedColor : Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildCenterHomeIcon() {
    final isSelected = currentIndex == 2;
    final selectedColor = _getSelectedColor(2); // Green for home
    
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
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: selectedColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Icon(
        Icons.home_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}