import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:prompt_generator/config/theme.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String loadingText;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText = 'Generating...',
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: widget.isLoading,
          child: AnimatedOpacity(
            opacity: widget.isLoading ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: widget.child,
          ),
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPulsingCircle(),
                    const SizedBox(height: 28),
                    _buildAnimatedText(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPulsingCircle() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sineValue = math.sin(_controller.value * 2 * math.pi);
        final scale = 0.85 + (0.2 * ((sineValue + 1) / 2));
        final glowOpacity = 0.2 + (0.3 * ((sineValue + 1) / 2));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                startAngle: _controller.value * 2 * math.pi,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.tertiary,
                  AppColors.primary,
                ],
                stops: const [0.0, 0.33, 0.66, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(glowOpacity),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: AppColors.secondary.withOpacity(glowOpacity * 0.5),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary.withOpacity(0.7 + (0.3 * ((sineValue + 1) / 2))),
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sineValue = math.sin(_controller.value * 2 * math.pi);
        final opacity = 0.5 + (0.5 * ((sineValue + 1) / 2));

        return Opacity(
          opacity: opacity,
          child: Text(
            widget.loadingText,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}
