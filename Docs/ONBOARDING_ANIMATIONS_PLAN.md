# Onboarding Screen - Morphing Sports Animation Effects with Shadows

**Version**: 1.0.0
**Date**: February 11, 2026
**Status**: Implementation Plan
**Animation Type**: Morphing/Transforming with Shadow Effects

---

## PROJECT OVERVIEW

Create catching animation effects for the TURF TOWN onboarding screen featuring:
- 🏏 Cricket (ball)
- 🏸 Badminton (shuttlecock)
- 🏈 Football

**Animation Style**: Morphing/Transforming with dynamic shadow effects
**Library**: Custom Flutter Animations (AnimationController + Tween)
**Screen Count**: Single unified onboarding screen
**Purpose**: App introduction showing sports capabilities

---

## DESIGN SPECIFICATIONS

### Animation Concept

**Morphing Effects**:
```
Cricket Ball → Rotating State → Shadow Expansion → Back to Original
Badminton → Morphing Shape → Shadow Transform → Swinging Motion
Football → Expanding State → Shadow Casting → Compression Effect
```

### Shadow Effects
- **Shadow Color**: Dark opacity gradients (black with transparency)
- **Shadow Movement**: Follows and leads the morphing shape
- **Shadow Blur**: Increases during expansion, decreases on compression
- **Shadow Spread**: Dynamic radius changes with animation

### Color Palette
```
Cricket:   Red (#FF0000), Dark Red (#8B0000)
Badminton: Blue (#0066FF), Light Blue (#ADD8E6)
Football:  Brown (#8B4513), Gold (#FFD700)
Shadows:   Black (0, 0, 0) with 0.3-0.6 opacity
Background: Gradient (light to dark)
```

---

## TECHNICAL ARCHITECTURE

### File Structure

```
lib/src/
├── services/
│   ├── splash_animations_service.dart        (NEW)
│   └── sports_animation_controller.dart      (NEW)
├── Pages/
│   └── splash_screen.dart                    (MODIFY)
├── widgets/
│   ├── morphing_sport_shape.dart             (NEW)
│   ├── animated_sport_item.dart              (NEW)
│   └── shadow_painter.dart                   (NEW)
└── utils/
    └── animation_constants.dart              (NEW)
```

### Core Components

#### 1. SplashAnimationsService (New)
**Purpose**: Manage all animation controllers and logic

```dart
class SplashAnimationsService {
  // Animation controllers
  late AnimationController cricketController;
  late AnimationController badmintonController;
  late AnimationController footballController;

  // Animation values
  late Animation<double> cricketMorph;
  late Animation<double> badmintonMorph;
  late Animation<double> footballMorph;

  // Shadow animations
  late Animation<double> cricketShadow;
  late Animation<double> badmintonShadow;
  late Animation<double> footballShadow;

  // Methods
  void initialize(TickerProvider vsync);
  void startAnimations();
  void pauseAnimations();
  void resumeAnimations();
  void dispose();
}
```

#### 2. MorphingSportShape (New Widget)
**Purpose**: Custom widget to render morphing sports items

```dart
class MorphingSportShape extends StatelessWidget {
  final String sportType;        // 'cricket', 'badminton', 'football'
  final Animation<double> morphValue;
  final Animation<double> shadowValue;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SportsShapePainter(
        sportType: sportType,
        morphValue: morphValue.value,
        shadowValue: shadowValue.value,
      ),
    );
  }
}
```

#### 3. ShadowPainter (New)
**Purpose**: Custom painter for shadow effects

```dart
class ShadowPainter extends CustomPainter {
  final double shadowValue;
  final Color shadowColor;
  final double blurRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw shadow with morphing blur and spread
  }

  @override
  bool shouldRepaint(ShadowPainter oldDelegate) => true;
}
```

---

## ANIMATION SEQUENCES

### Cricket Ball Animation (2.5s loop)
```
0.0s - 0.5s:  Morph to sphere (expand radius)
0.5s - 1.0s:  Rotate with shadow expanding
1.0s - 1.5s:  Shadow contracts, shape returns
1.5s - 2.5s:  Rest state with subtle pulse
2.5s - Loop:  Repeat
```

### Badminton Shuttlecock Animation (2.0s loop)
```
0.0s - 0.4s:  Morph to expanded form
0.4s - 0.8s:  Swing motion with shadow arc
0.8s - 1.2s:  Return swing with shadow follow
1.2s - 2.0s:  Compress and settle
2.0s - Loop:  Repeat
```

### Football Animation (2.2s loop)
```
0.0s - 0.6s:  Expand/compress vertical
0.6s - 1.2s:  Rotate with shadow casting
1.2s - 1.8s:  Return to original shape
1.8s - 2.2s:  Subtle bounce
2.2s - Loop:  Repeat
```

---

## IMPLEMENTATION STEPS

### Phase 1: Setup & Infrastructure (Task 1-2)
1. Create animation constants file
2. Create SplashAnimationsService
3. Define animation timings and curves

### Phase 2: Custom Painters (Task 3)
1. Create ShadowPainter for shadow effects
2. Create SportsShapePainter for cricket ball
3. Create SportsShapePainter for badminton shuttlecock
4. Create SportsShapePainter for football

### Phase 3: Animation Widgets (Task 4-6)
1. Create MorphingSportShape widget
2. Create AnimatedSportItem wrapper
3. Implement morphing logic using Tween

### Phase 4: Onboarding UI (Task 7)
1. Design layout for single screen
2. Position three sports items
3. Add title and description
4. Add navigation elements

### Phase 5: Integration (Task 8)
1. Integrate animations into splash_screen.dart
2. Add start/stop logic
3. Handle lifecycle properly

### Phase 6: Polish & Optimization (Task 9-11)
1. Add parallax background effect
2. Test on multiple devices
3. Optimize performance
4. Handle memory cleanup

---

## CODE EXAMPLES

### Animation Constants File

```dart
// lib/src/utils/animation_constants.dart

class AnimationConstants {
  // Cricket animation
  static const Duration cricketDuration = Duration(milliseconds: 2500);
  static const Curve cricketCurve = Curves.easeInOutQuad;
  static const double cricketStartRadius = 30.0;
  static const double cricketMaxRadius = 50.0;

  // Badminton animation
  static const Duration badmintonDuration = Duration(milliseconds: 2000);
  static const Curve badmintonCurve = Curves.easeInOutCubic;
  static const double badmintonStartHeight = 40.0;
  static const double badmintonMaxHeight = 60.0;

  // Football animation
  static const Duration footballDuration = Duration(milliseconds: 2200);
  static const Curve footballCurve = Curves.elasticInOut;
  static const double footballStartWidth = 45.0;
  static const double footballMaxWidth = 65.0;

  // Shadow effects
  static const double shadowBaseBlur = 5.0;
  static const double shadowMaxBlur = 20.0;
  static const double shadowBaseSpread = 0.0;
  static const double shadowMaxSpread = 15.0;
  static const Color shadowColor = Color.fromARGB(76, 0, 0, 0); // Black 30%
}
```

### SplashAnimationsService

```dart
// lib/src/services/splash_animations_service.dart

class SplashAnimationsService {
  late AnimationController cricketController;
  late AnimationController badmintonController;
  late AnimationController footballController;

  late Animation<double> cricketMorph;
  late Animation<double> badmintonMorph;
  late Animation<double> footballMorph;

  late Animation<double> cricketShadow;
  late Animation<double> badmintonShadow;
  late Animation<double> footballShadow;

  void initialize(TickerProvider vsync) {
    // Cricket animation
    cricketController = AnimationController(
      duration: AnimationConstants.cricketDuration,
      vsync: vsync,
    );

    cricketMorph = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: cricketController, curve: AnimationConstants.cricketCurve),
    );

    cricketShadow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: cricketController, curve: Curves.easeInOutQuad),
    );

    // Similar setup for badminton and football
    // ...

    // Start animations
    cricketController.repeat();
    badmintonController.repeat();
    footballController.repeat();
  }

  void dispose() {
    cricketController.dispose();
    badmintonController.dispose();
    footballController.dispose();
  }
}
```

### MorphingSportShape Widget

```dart
// lib/src/widgets/morphing_sport_shape.dart

class MorphingSportShape extends StatelessWidget {
  final String sportType;
  final Animation<double> morphValue;
  final Animation<double> shadowValue;
  final Offset position;

  const MorphingSportShape({
    required this.sportType,
    required this.morphValue,
    required this.shadowValue,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: SizedBox(
        width: 150,
        height: 150,
        child: CustomPaint(
          painter: SportsShapePainter(
            sportType: sportType,
            morphValue: morphValue.value,
            shadowValue: shadowValue.value,
          ),
          child: Container(),
        ),
      ),
    );
  }
}
```

---

## ANIMATION TIMING & CURVES

| Sport | Duration | Start Delay | Curve | Loop |
|-------|----------|------------|-------|------|
| Cricket | 2500ms | 0ms | easeInOutQuad | Repeat |
| Badminton | 2000ms | 300ms | easeInOutCubic | Repeat |
| Football | 2200ms | 600ms | elasticInOut | Repeat |

---

## COLOR SPECIFICATIONS

### Cricket Ball
```
Primary: Red (#FF0000)
Shadow: Dark Red (#8B0000) with morph effect
Glow: Red with 0.3 opacity
```

### Badminton Shuttlecock
```
Primary: Blue (#0066FF)
Shadow: Dark Blue (#003399) with arc effect
Accent: Light Blue (#ADD8E6)
```

### Football
```
Primary: Brown (#8B4513)
Shadow: Dark Brown (#5C2E0F)
Accent: Gold (#FFD700)
```

---

## PERFORMANCE OPTIMIZATION

### Tips
1. Use `RepaintBoundary` for CustomPaint widgets
2. Optimize `shouldRepaint` to return false when unchanged
3. Use `const` constructors where possible
4. Batch paint operations
5. Use `Paint` object caching

### Memory Management
- Properly dispose animation controllers
- Remove animation listeners when not needed
- Use `AnimationListener` sparingly

---

## TESTING CHECKLIST

- [ ] Cricket ball morphs smoothly
- [ ] Badminton shadows follow motion
- [ ] Football expands/compresses correctly
- [ ] All shadows render properly
- [ ] Animations loop seamlessly
- [ ] No janky frames on 60fps devices
- [ ] Handles screen rotation
- [ ] Works on 4-inch to 6.5-inch screens
- [ ] Battery drain acceptable
- [ ] Memory usage stable

---

## TODO ITEMS (12 Tasks)

1. ✅ Design morphing shadow animation effects
2. ✅ Create splash_animations_service.dart
3. ✅ Build cricket ball morphing animation
4. ✅ Build badminton shuttlecock morphing animation
5. ✅ Build football morphing animation
6. ✅ Create CustomPainter for sports shapes and shadows
7. ✅ Implement onboarding screen UI layout
8. ✅ Integrate animations into splash_screen.dart
9. ✅ Add parallax background animation
10. ✅ Test animations on multiple devices
11. ✅ Optimize animation performance
12. ✅ Create documentation for animation system

---

## SUCCESS CRITERIA

✅ All three sports have smooth morphing animations
✅ Shadow effects follow and enhance animations
✅ Single unified onboarding screen
✅ Animations loop seamlessly
✅ 60 FPS performance on standard devices
✅ No memory leaks
✅ Works on all supported screen sizes
✅ Production-ready code quality

---

## NEXT STEPS

1. Review this plan
2. Ask any clarifying questions
3. Start with Phase 1 (Setup & Infrastructure)
4. Proceed to Phase 2 (Custom Painters)
5. Implement and test incrementally

---

**Ready to start building? Let's create some amazing animation effects!** 🎬🏏🏸🏈
