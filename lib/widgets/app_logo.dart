import 'package:flutter/material.dart';

/// App Logo Widget - Use anywhere in the app
/// 
/// Usage:
/// AppLogo(size: 100)
/// AppLogo.large()  // 120px
/// AppLogo.medium() // 80px
/// AppLogo.small()  // 50px

class AppLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const AppLogo({
    Key? key,
    this.size = 80,
    this.primaryColor,
    this.accentColor,
  }) : super(key: key);

  const AppLogo.large({
    Key? key,
    this.primaryColor,
    this.accentColor,
  })  : size = 120,
        super(key: key);

  const AppLogo.medium({
    Key? key,
    this.primaryColor,
    this.accentColor,
  })  : size = 80,
        super(key: key);

  const AppLogo.small({
    Key? key,
    this.primaryColor,
    this.accentColor,
  })  : size = 50,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF1976D2);
    final accent = accentColor ?? const Color(0xFF4CAF50);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Receipt/Document shape
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            right: size * 0.15,
            bottom: size * 0.25,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Receipt lines
                  _buildReceiptLine(size * 0.5),
                  _buildReceiptLine(size * 0.4),
                  _buildReceiptLine(size * 0.45),
                  _buildReceiptLine(size * 0.35),
                ],
              ),
            ),
          ),
          // Rupee symbol circle at bottom
          Positioned(
            bottom: size * 0.1,
            left: size * 0.5 - size * 0.12,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: size * 0.02),
              ),
              child: Center(
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(double width) {
    return Container(
      width: width,
      height: size * 0.02,
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.6),
        borderRadius: BorderRadius.circular(size * 0.01),
      ),
    );
  }
}

/// App Logo with Text - Use in splash screen or about page
class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final double fontSize;

  const AppLogoWithText({
    Key? key,
    this.logoSize = 100,
    this.fontSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        SizedBox(height: logoSize * 0.2),
        Text(
          'Transaction Manager',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: logoSize * 0.05),
        Text(
          'Manage your transactions',
          style: TextStyle(
            fontSize: fontSize * 0.5,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Animated App Logo - Use in splash screen
class AnimatedAppLogo extends StatefulWidget {
  final double size;

  const AnimatedAppLogo({
    Key? key,
    this.size = 120,
  }) : super(key: key);

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: AppLogo(size: widget.size),
          ),
        );
      },
    );
  }
}
