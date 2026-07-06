import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SkeletonCard extends StatefulWidget {
  final bool isDark;
  final double? height;

  const SkeletonCard({super.key, required this.isDark, this.height});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height ?? 100,
        decoration: BoxDecoration(
          color: Color.lerp(
            widget.isDark ? const Color(0xFF162436) : AppTheme.darkText,
            widget.isDark ? const Color(0xFF1E3554) : const Color(0xFFF1F5F9),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
