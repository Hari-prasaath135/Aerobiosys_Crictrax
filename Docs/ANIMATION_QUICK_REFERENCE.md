# Scoreboard Animation System - Quick Reference

## How Animations Work

### 1. Animation Trigger Flow
```
Game Event (4 runs, wicket, runout, etc.)
        ↓
recordNormalBall() method
        ↓
Animation trigger method (_triggerBoundaryAnimation, etc.)
        ↓
AnimationController.forward(from: 0.0)
        ↓
AnimatedBuilder rebuilds UI
        ↓
Animation completes and fades
```

### 2. Animation Trigger Points

**Boundary Animation (Confetti)**
```dart
// Triggered in recordNormalBall() when:
if (runs == 4 || runs == 6) {
  _triggerBoundaryAnimation(batsmanId);
}
```

**Wicket Animation (Lightning)**
```dart
// Triggered in recordNormalBall() when:
if (isWicket) {
  _triggerWicketAnimation();
  if (batsman.runs == 0) {
    _triggerDuckAnimation(batsmanId);
  }
}
```

**Runout Highlight (Border Flash)**
```dart
// Triggered in _checkForRunouts() when:
if (batsman.isOut && batsman.dismissalType == 'runout') {
  _triggerRunoutHighlight(batsman.playerId);
}
```

## Animation Controllers

### Setup (in _initializeAnimations)
```dart
// Create controller
AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)

// Create animation with Tween
Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(parent: controller, curve: Curves.easeOut)
)

// Start animation
controller.forward(from: 0.0)
```

### Cleanup (in dispose)
```dart
_boundaryAnimationController.dispose();
_wicketAnimationController.dispose();
_duckAnimationController.dispose();
_runoutHighlightController.dispose();
super.dispose();
```

## Visual Reference

### Boundary Animation (Confetti)
```
Time: 0ms          Time: 500ms        Time: 1000ms
🎉🎉🎉             🎉    🎉           (faded out)
  🎉🎉             🎉
🎉  🎉           🎉
  🎉
```

### Wicket Animation (Lightning)
```
Time: 0ms          Time: 450ms        Time: 900ms
┌─────┐           ╱─────╲            ┌─────┐
│  ⚡ │    →      │  ⚡  │      →     │  ⚡ │
└─────┘           ╲─────╱            └─────┘
(red circle)    (rotated 180°)       (faded)
```

### Duck Animation
```
Time: 0ms          Time: 500ms        Time: 1000ms
(invisible)        🦆(at scale 0.5)   (faded out)

```

### Runout Highlight
```
Time: 0ms                Time: 400ms            Time: 800ms
┃ Batsman Row ┃          ┃ Batsman Row ┃       ┃ Batsman Row ┃
┃ 50 (25) 4|6┃           ┃ 50 (25) 4|6 ┃       ┃ 50 (25) 4|6 ┃
                        (red border)           (faded)
                        opacity: 0.8           opacity: 0.0
```

## Key Methods Reference

### Animation Triggers
```dart
void _triggerBoundaryAnimation(String batsmanId)
  // Generates confetti and plays animation
  // Call when: runs == 4 || runs == 6

void _triggerWicketAnimation()
  // Plays lightning rotation animation
  // Call when: isWicket == true

void _triggerDuckAnimation(String batsmanId)
  // Plays duck emoji scale+fade animation
  // Call when: isOut && runs == 0

void _triggerRunoutHighlight(String batsmanId)
  // Plays red border flash
  // Call when: dismissalType == 'runout'
```

### Helper Methods
```dart
void _generateConfetti()
  // Creates 20 confetti particles with random properties
  // Called by _triggerBoundaryAnimation()

void _checkForRunouts()
  // Detects runouts on auto-refresh and triggers highlight
  // Called every 2 seconds by _startAutoRefresh()

void _initializeAnimations()
  // Sets up all animation controllers and tweens
  // Called in initState()
```

### Widget Methods
```dart
Widget _buildFoursSixesCell(String count, String type, bool isHighlighted)
  // Renders highlighted 4s and 6s cells
  // Returns: Container with blue/orange background

Widget _buildDuckAnimationWidget(String batsmanId)
  // Renders duck animation overlay
  // Returns: Stack with duck emoji animation

Widget _buildBatsmanRow(Batsman batsman, {required bool isCurrent})
  // Enhanced to include runout highlight and duck animation
  // Returns: AnimatedBuilder with all row content
```

## State Variables Used

```dart
// Animation Controllers
late AnimationController _boundaryAnimationController;
late AnimationController _wicketAnimationController;
late AnimationController _duckAnimationController;
late AnimationController _runoutHighlightController;

// Animation Values
late Animation<double> _boundaryScale;
late Animation<double> _boundaryOpacity;
late Animation<double> _wicketRotation;
late Animation<double> _duckScale;
late Animation<double> _duckOpacity;
late Animation<Color?> _runoutBorderColor;

// State Flags
String? _lastDuckBatsman;           // Tracks which batsman has duck animation
String? _lastRunoutBatsman;         // Tracks which batsman has runout highlight
bool _showBoundaryConfetti;         // Show/hide confetti overlay
final List<ConfettiPiece> _confettiPieces;  // Confetti particle list
bool _showRunoutHighlight;          // Show/hide runout border
```

## Duration Reference

| Animation | Duration | Purpose |
|-----------|----------|---------|
| Confetti (4s/6s) | 1000ms | Celebratory boundary effect |
| Lightning (Wicket) | 900ms | Quick dramatic effect |
| Duck emoji | 1000ms | Clear dismissal indication |
| Runout border | 800ms | Quick highlight flash |

## Common Modifications

### Change Confetti Duration
```dart
_boundaryAnimationController = AnimationController(
  duration: const Duration(milliseconds: 1500),  // Change to 1500ms
  vsync: this,
);
```

### Change Wicket Animation Color
```dart
// In wicket animation overlay, change:
border: Border.all(color: Colors.orange, width: 3)  // From Colors.red
```

### Change Confetti Colors
```dart
// In _generateConfetti(), modify color list:
color: [Colors.purple, Colors.pink, Colors.cyan][random.nextInt(3)]
```

### Disable an Animation
```dart
// In recordNormalBall(), comment out trigger:
// _triggerBoundaryAnimation(batsmanId);  // Disable boundary animation
```

## Debugging Tips

### Check if animation is triggering
```dart
// Add print statements
void _triggerBoundaryAnimation(String batsmanId) {
  print('Boundary animation triggered for batsman: $batsmanId');
  _generateConfetti();
  _boundaryAnimationController.forward(from: 0.0);
}
```

### Check animation state
```dart
// In AnimatedBuilder
print('Animation value: ${_boundaryScale.value}');
print('Animation status: ${_boundaryAnimationController.status}');
```

### Verify disposal
```dart
// Add to dispose
print('Disposing animation controllers');
_boundaryAnimationController.dispose();
// etc...
```

## Performance Tips

1. Use `IgnorePointer` on animation overlays to prevent blocking input
2. Use `mounted` check before `setState()` in delayed callbacks
3. Dispose all `AnimationController` instances in `dispose()`
4. Limit confetti particle count to 20 for performance
5. Use `const` for static widgets to prevent unnecessary rebuilds
