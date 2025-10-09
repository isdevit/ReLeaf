import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_screen.dart';
import 'auth/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  // Updated color palette to complement black logo
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color leafGreen = Color(0xFF66BB6A);

  // List of rotating taglines
  final List<String> taglines = [
    'Challenge Yourself. Change the World.',
    'Wellness Meets Sustainability—Every Single Day.',
    'Do Good. Feel Good. Repeat.',
    'Eco Habits. Healthy Living. One App.',
    'Every Action Counts—For You and the Earth.',
    'Gamify Your Goodness.',
    'Smarter Habits. Greener Future.',
    'Well-Being with a Purpose.',
    'Track Growth—Yours and the Planet\'s.',
  ];

  String currentTagline = '';

  @override
  void initState() {
    super.initState();
    _loadTagline();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  Future<void> _loadTagline() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('tagline_index') ?? 0;
    
    // Get next tagline in sequence (cycles back to 0 after reaching the end)
    final nextIndex = (lastIndex + 1) % taglines.length;
    
    setState(() {
      currentTagline = taglines[nextIndex];
    });
    
    // Save the current index for next time
    await prefs.setInt('tagline_index', nextIndex);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryWhite,
              lightGray,
              primaryWhite,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 0.5,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentGreen.withOpacity(0.05),
                            accentGreen.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -120,
              left: -120,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_animationController.value * 0.3,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            softGreen.withOpacity(0.04),
                            softGreen.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Floating leaf elements
            Positioned(
              top: 120,
              left: 50,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      20 * (_animationController.value - 0.5),
                      10 * (_animationController.value - 0.5),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Icon(
                        Icons.eco,
                        size: 24,
                        color: leafGreen.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 200,
              right: 80,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      -15 * (_animationController.value - 0.5),
                      15 * (_animationController.value - 0.5),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Icon(
                        Icons.local_florist,
                        size: 20,
                        color: accentGreen.withOpacity(0.25),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with enhanced styling for black logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: softGreen.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: lightGray,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Image.asset(
                                'assets/images/releaf_logo_transparent.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name and tagline with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  softGreen,
                                  accentGreen,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'BREATHE',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkGray.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BETTER',
                            style: TextStyle(
                              fontSize: 14,
                              color: softGreen,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Dynamic tagline that changes each time
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              currentTagline,
                              style: TextStyle(
                                fontSize: 16,
                                color: darkGray.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Enhanced loading indicator
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: softGreen.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(softGreen),
                              backgroundColor: accentGreen.withOpacity(0.2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Enhanced bottom decorative leaf pattern
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Transform.rotate(
                            angle: (index - 3) * 0.3,
                            child: Icon(
                              index % 2 == 0 ? Icons.eco : Icons.local_florist,
                              size: index == 3 ? 20 : 16,
                              color: index == 3
                                  ? softGreen.withOpacity(0.6)
                                  : leafGreen.withOpacity(0.4),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),

            // Subtle version text at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Version 1.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGray.withOpacity(0.4),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}