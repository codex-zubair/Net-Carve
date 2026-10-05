import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The NetCarve wordmark + logo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 32, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: size),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'NetCarve',
            style: TextStyle(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.text,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size * 0.6, size * 0.6),
        painter: _CarvePainter(),
      ),
    );
  }
}

/// Draws a stylised network: one block carved into smaller blocks.
class _CarvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bgDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width * 0.14),
      ),
      paint,
    );

    final mid = size.width / 2;
    canvas.drawLine(Offset(mid, 0), Offset(mid, size.height), paint);
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
