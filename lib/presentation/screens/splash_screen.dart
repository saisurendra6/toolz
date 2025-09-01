import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolz/app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _textController;
  late AnimationController _blobController;
  late AnimationController _loadingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _blobAnimation;
  late Animation<double> _loadingAnimation;

  // Random color generation
  late List<Color> _gradientColors;
  late List<Color> _blobColors;
  late Color _accentColor;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate random colors
    _generateRandomColors();

    // Hide system UI for immersive splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initAnimations();
    _startAnimationSequence();
  }

  void _generateRandomColors() {
    // Predefined color palettes for better combinations
    final colorPalettes = [
      // Purple-Blue palette
      [
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        const Color(0xFF4facfe),
        const Color(0xFF00f2fe),
      ],
      // Green-Teal palette
      [
        const Color(0xFF11998e),
        const Color(0xFF38ef7d),
        const Color(0xFF20bf6b),
        const Color(0xFF26de81),
      ],
      // Orange-Red palette
      [
        const Color(0xFFf093fb),
        const Color(0xFFf5576c),
        const Color(0xFFfc4a1a),
        const Color(0xFFf7b733),
      ],
      // Deep Blue palette
      [
        const Color(0xFF2196F3),
        const Color(0xFF21CBF3),
        const Color(0xFF2196F3),
        const Color(0xFF3F51B5),
      ],
      // Indigo-Purple palette
      [
        const Color(0xFF3F51B5),
        const Color(0xFF673AB7),
        const Color(0xFF9C27B0),
        const Color(0xFF6366f1),
      ],
      // Teal-Cyan palette
      [
        const Color(0xFF009688),
        const Color(0xFF00BCD4),
        const Color(0xFF4DD0E1),
        const Color(0xFF26C6DA),
      ],
      // Dark theme palette
      [
        const Color(0xFF1a1a2e),
        const Color(0xFF16213e),
        const Color(0xFF0f3460),
        const Color(0xFF533483),
      ],
      // Sunset palette
      [
        const Color(0xFFFF6B6B),
        const Color(0xFF4ECDC4),
        const Color(0xFF45B7D1),
        const Color(0xFF96CEB4),
      ],
    ];

    // Pick a random palette
    final selectedPalette =
        colorPalettes[_random.nextInt(colorPalettes.length)];
    _gradientColors = List.from(selectedPalette);

    // Generate blob colors based on the palette
    _blobColors = [
      _gradientColors[0].withOpacity(0.2),
      _gradientColors[1].withOpacity(0.15),
      _gradientColors[2].withOpacity(0.1),
      _gradientColors[3].withOpacity(0.12),
      Colors.white.withOpacity(0.08),
    ];

    // Pick a random accent color for the 'Z'
    final accentColors = [
      const Color(0xFF00f2fe), // Electric blue
      const Color(0xFF26de81), // Bright green
      const Color(0xFFf7b733), // Golden yellow
      const Color(0xFFff6b6b), // Coral red
      const Color(0xFF4ecdc4), // Turquoise
      const Color(0xFF45b7d1), // Sky blue
      const Color(0xFF96ceb4), // Mint green
      const Color(0xFFa8e6cf), // Light mint
      const Color(0xFFffeaa7), // Light yellow
      const Color(0xFFfd79a8), // Light pink
    ];

    _accentColor = accentColors[_random.nextInt(accentColors.length)];
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _blobController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _blobAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _blobController, curve: Curves.linear),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    _textController.forward();
    _blobController.repeat();

    await Future.delayed(const Duration(milliseconds: 800));
    _loadingController.repeat(reverse: true);

    // Navigate to home after splash duration
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    _blobController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated blobs/shapes with random colors
            AnimatedBuilder(
              animation: _blobAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    _buildFloatingBlob(
                      size: 120,
                      color: _blobColors[0],
                      offset: Offset(
                        size.width * 0.2 + 30 * math.sin(_blobAnimation.value),
                        size.height * 0.3 + 20 * math.cos(_blobAnimation.value),
                      ),
                    ),
                    _buildFloatingBlob(
                      size: 80,
                      color: _blobColors[1],
                      offset: Offset(
                        size.width * 0.8 +
                            25 * math.cos(_blobAnimation.value * 1.5),
                        size.height * 0.2 +
                            15 * math.sin(_blobAnimation.value * 1.5),
                      ),
                    ),
                    _buildFloatingBlob(
                      size: 60,
                      color: _blobColors[2],
                      offset: Offset(
                        size.width * 0.1 +
                            20 * math.sin(_blobAnimation.value * 0.8),
                        size.height * 0.7 +
                            25 * math.cos(_blobAnimation.value * 0.8),
                      ),
                    ),
                    _buildFloatingBlob(
                      size: 100,
                      color: _blobColors[3],
                      offset: Offset(
                        size.width * 0.7 +
                            35 * math.cos(_blobAnimation.value * 0.6),
                        size.height * 0.8 +
                            30 * math.sin(_blobAnimation.value * 0.6),
                      ),
                    ),
                    _buildFloatingBlob(
                      size: 90,
                      color: _blobColors[4],
                      offset: Offset(
                        size.width * 0.5 +
                            28 * math.sin(_blobAnimation.value * 1.2),
                        size.height * 0.1 +
                            22 * math.cos(_blobAnimation.value * 1.2),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/title
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'tool',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            offset: const Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Z',
                                      style: TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            _accentColor, // Random accent color
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            offset: const Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Tagline
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        '⚡ Your Gen Z Productivity Vibe ⚡',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _loadingAnimation.value,
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _accentColor, // Use random accent color for loading
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Loading the magic... 🚀',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom decoration
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon('💬'),
                        const SizedBox(width: 15),
                        _buildSocialIcon('🔔'),
                        const SizedBox(width: 15),
                        _buildSocialIcon('⚡'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Made with 💙 for productivity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBlob({
    required double size,
    required Color color,
    required Offset offset,
  }) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String emoji) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
