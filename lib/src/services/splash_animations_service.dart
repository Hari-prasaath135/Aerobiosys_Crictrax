import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/utils/animation_constants.dart';

class SplashAnimationsService {
  // Animation Controllers
  late AnimationController cricketController;
  late AnimationController badmintonController;
  late AnimationController footballController;

  // Morphing Animations
  late Animation<double> cricketMorph;
  late Animation<double> badmintonMorph;
  late Animation<double> footballMorph;

  // Shadow Animations
  late Animation<double> cricketShadow;
  late Animation<double> badmintonShadow;
  late Animation<double> footballShadow;

  // Rotation animations for visual effect
  late Animation<double> cricketRotation;
  late Animation<double> badmintonRotation;
  late Animation<double> footballRotation;

  /// Initialize all animation controllers
  void initialize(TickerProvider vsync) {
    // Cricket Ball Animation
    cricketController = AnimationController(
      duration: AnimationConstants.cricketDuration,
      vsync: vsync,
    );

    cricketMorph = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: cricketController,
        curve: AnimationConstants.cricketCurve,
      ),
    );

    cricketShadow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: cricketController, curve: Curves.easeInOutQuad),
    );

    cricketRotation = Tween<double>(begin: 0.0, end: 6.28).animate(
      CurvedAnimation(parent: cricketController, curve: Curves.linear),
    );

    // Badminton Shuttlecock Animation
    badmintonController = AnimationController(
      duration: AnimationConstants.badmintonDuration,
      vsync: vsync,
    );

    badmintonMorph = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: badmintonController,
        curve: AnimationConstants.badmintonCurve,
      ),
    );

    badmintonShadow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: badmintonController, curve: Curves.easeInOutQuad),
    );

    badmintonRotation = Tween<double>(begin: 0.0, end: 3.14).animate(
      CurvedAnimation(parent: badmintonController, curve: Curves.easeInOutSine),
    );

    // Football Animation
    footballController = AnimationController(
      duration: AnimationConstants.footballDuration,
      vsync: vsync,
    );

    footballMorph = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: footballController,
        curve: AnimationConstants.footballCurve,
      ),
    );

    footballShadow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: footballController, curve: Curves.easeInOutQuad),
    );

    footballRotation = Tween<double>(begin: 0.0, end: 6.28).animate(
      CurvedAnimation(parent: footballController, curve: Curves.linear),
    );
  }

  /// Start all animations with staggered timing
  void startAnimations() {
    // Start cricket immediately
    cricketController.repeat();

    // Start badminton with delay (only if not already animating)
    Future.delayed(AnimationConstants.badmintonDelay, () {
      if (!badmintonController.isAnimating && badmintonController.duration != null) {
        badmintonController.repeat();
      }
    });

    // Start football with delay (only if not already animating)
    Future.delayed(AnimationConstants.footballDelay, () {
      if (!footballController.isAnimating && footballController.duration != null) {
        footballController.repeat();
      }
    });
  }

  /// Pause all animations
  void pauseAnimations() {
    cricketController.stop();
    badmintonController.stop();
    footballController.stop();
  }

  /// Resume all animations
  void resumeAnimations() {
    if (!cricketController.isAnimating) {
      cricketController.repeat();
    }
    if (!badmintonController.isAnimating) {
      badmintonController.repeat();
    }
    if (!footballController.isAnimating) {
      footballController.repeat();
    }
  }

  /// Reset all animations to start
  void reset() {
    cricketController.reset();
    badmintonController.reset();
    footballController.reset();
  }

  /// Dispose all animation controllers
  void dispose() {
    cricketController.dispose();
    badmintonController.dispose();
    footballController.dispose();
  }

  /// Get current morph value for cricket (0.0 to 1.0)
  double getCricketMorphValue() => cricketMorph.value;

  /// Get current morph value for badminton (0.0 to 1.0)
  double getBadmintonMorphValue() => badmintonMorph.value;

  /// Get current morph value for football (0.0 to 1.0)
  double getFootballMorphValue() => footballMorph.value;

  /// Get current shadow value for cricket (0.0 to 1.0)
  double getCricketShadowValue() => cricketShadow.value;

  /// Get current shadow value for badminton (0.0 to 1.0)
  double getBadmintonShadowValue() => badmintonShadow.value;

  /// Get current shadow value for football (0.0 to 1.0)
  double getFootballShadowValue() => footballShadow.value;

  /// Get current rotation value
  double getCricketRotation() => cricketRotation.value;
  double getBadmintonRotation() => badmintonRotation.value;
  double getFootballRotation() => footballRotation.value;

  /// Get Animation objects for use with AnimatedBuilder
  Animation<double> getCricketMorphAnimation() => cricketMorph;
  Animation<double> getBadmintonMorphAnimation() => badmintonMorph;
  Animation<double> getFootballMorphAnimation() => footballMorph;

  Animation<double> getCricketShadowAnimation() => cricketShadow;
  Animation<double> getBadmintonShadowAnimation() => badmintonShadow;
  Animation<double> getFootballShadowAnimation() => footballShadow;

  Animation<double> getCricketRotationAnimation() => cricketRotation;
  Animation<double> getBadmintonRotationAnimation() => badmintonRotation;
  Animation<double> getFootballRotationAnimation() => footballRotation;
}
