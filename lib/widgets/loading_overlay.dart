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
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: widget.isLoading,
          child: AnimatedOpacity(
            opacity: widget.isLoading ? 0.25 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: widget.child,
          ),
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOrbitLoader(),
                    const SizedBox(height: 36),
                    _buildShimmerText(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrbitLoader() {
    return SizedBox(
      width: 100,
      height: 100,
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing outer ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final scale = 0.88 + 0.12 * _pulseController.value;
                  final opacity = 0.15 + 0.1 * _pulseController.value;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: opacity),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Inner static ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              // Three orbiting dots
              ..._buildOrbitingDots(),
              // Center dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOrbitingDots() {
    const orbitRadius = 30.0;
    final dots = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final phaseOffset = (i / 3) * 2 * math.pi;
      final angle = _orbitController.value * 2 * math.pi + phaseOffset;
      final x = orbitRadius * math.cos(angle);
      final y = orbitRadius * math.sin(angle);

      // Dot size pulses with orbit position to give depth
      final depthScale = 0.7 + 0.3 * ((math.sin(angle) + 1) / 2);
      final opacity = 0.5 + 0.5 * ((math.sin(angle + math.pi) + 1) / 2);

      dots.add(
        Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: depthScale,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3 * opacity),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return dots;
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerPos = _shimmerController.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.white38,
                Colors.white,
                Colors.white70,
                Colors.white38,
              ],
              stops: [
                (shimmerPos - 0.4).clamp(0.0, 1.0),
                shimmerPos.clamp(0.0, 1.0),
                (shimmerPos + 0.1).clamp(0.0, 1.0),
                (shimmerPos + 0.4).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.loadingText,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }
}
