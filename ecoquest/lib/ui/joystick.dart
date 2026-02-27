import 'dart:math';

import 'package:flutter/material.dart';

/// A virtual joystick widget that outputs a normalized direction offset.
///
/// Place this inside a [Stack] over the game canvas. It renders a
/// semi-transparent outer base with a draggable inner knob, clamped to
/// the base radius using trigonometry.
class VirtualJoystick extends StatefulWidget {
  /// Fires whenever the joystick direction changes.
  /// The [Offset] has x and y components in the range [-1.0, 1.0].
  final ValueChanged<Offset> onDirectionChanged;

  /// Radius of the outer base circle.
  final double baseRadius;

  /// Radius of the inner knob circle.
  final double knobRadius;

  const VirtualJoystick({
    super.key,
    required this.onDirectionChanged,
    this.baseRadius = 60,
    this.knobRadius = 25,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  /// Current knob offset from the center of the base.
  Offset _knobOffset = Offset.zero;

  void _handlePanStart(DragStartDetails details) {
    // Nothing special needed on start — updates happen in onPanUpdate.
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      // Accumulate the drag delta.
      Offset raw = _knobOffset + details.delta;

      final double distance = raw.distance;
      final double maxDistance = widget.baseRadius - widget.knobRadius;

      if (distance > maxDistance) {
        // Clamp: compute angle via atan2.
        final double angle = atan2(raw.dy, raw.dx);
        raw = Offset(cos(angle) * maxDistance, sin(angle) * maxDistance);
      }

      _knobOffset = raw;
    });

    // Normalize to [-1, 1].
    final double maxDistance = widget.baseRadius - widget.knobRadius;
    widget.onDirectionChanged(
      Offset(
        (_knobOffset.dx / maxDistance).clamp(-1.0, 1.0),
        (_knobOffset.dy / maxDistance).clamp(-1.0, 1.0),
      ),
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _knobOffset = Offset.zero;
    });
    widget.onDirectionChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.baseRadius * 2;
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: CustomPaint(
          painter: _JoystickPainter(
            baseRadius: widget.baseRadius,
            knobRadius: widget.knobRadius,
            knobOffset: _knobOffset,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final double baseRadius;
  final double knobRadius;
  final Offset knobOffset;

  _JoystickPainter({
    required this.baseRadius,
    required this.knobRadius,
    required this.knobOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Outer base — semi-transparent white.
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius, basePaint);

    // Base outline.
    final baseOutlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, baseRadius, baseOutlinePaint);

    // Inner knob — solid white with slight transparency.
    final knobPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + knobOffset, knobRadius, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.knobOffset != knobOffset;
}
