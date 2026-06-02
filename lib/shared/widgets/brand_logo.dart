import 'package:adondeamos/app/app_theme.dart';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.wordmarkColor = AppTheme.ink,
    this.subtitle,
  });

  final double size;
  final bool showWordmark;
  final Color wordmarkColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final mark = BrandMark(size: size);

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adondeamos',
              style: TextStyle(
                color: wordmarkColor,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: size * 0.03),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.deepBrandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.22),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BrandGlyphPainter()),
      ),
    );
  }
}

class _BrandGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.surface.withValues(alpha: 0.9);

    final route = Path()
      ..moveTo(size.width * 0.28, size.height * 0.66)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.45,
        size.width * 0.36,
        size.height * 0.22,
        size.width * 0.54,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.44,
        size.width * 0.62,
        size.height * 0.70,
        size.width * 0.80,
        size.height * 0.76,
      );

    canvas.drawPath(route, routePaint);

    final pinPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.surface;

    final pin = Path()
      ..moveTo(size.width * 0.55, size.height * 0.20)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.20,
        size.width * 0.32,
        size.height * 0.30,
        size.width * 0.32,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.58,
        size.width * 0.55,
        size.height * 0.78,
        size.width * 0.55,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.78,
        size.width * 0.78,
        size.height * 0.58,
        size.width * 0.78,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.30,
        size.width * 0.68,
        size.height * 0.20,
        size.width * 0.55,
        size.height * 0.20,
      )
      ..close();

    canvas.drawPath(pin, pinPaint);

    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.blueEnergy;

    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.42),
      size.width * 0.105,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
