import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visualises an IPv4 address or mask one octet (8 bits) at a time.
///
/// Network bits are drawn in the accent colour and host bits in a muted
/// colour, directly mirroring how a subnet mask partitions an address.
class BinaryView extends StatelessWidget {
  const BinaryView({
    super.key,
    required this.value,
    required this.prefix,
    this.showColonLabels = true,
  });

  /// The 32-bit value to render.
  final int value;

  /// The prefix length that decides which bits are "network".
  final int prefix;

  /// Whether to label the bit columns with their powers of two.
  final bool showColonLabels;

  @override
  Widget build(BuildContext context) {
    final octets = <List<int>>[];
    for (var o = 3; o >= 0; o--) {
      final octet = (value >> (o * 8)) & 0xFF;
      octets.add(List.generate(8, (b) => (octet >> (7 - b)) & 1));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 32 bit cells plus 4 octet gaps; each cell carries 1.2px of margin.
        final usable = constraints.maxWidth - 3 * 10;
        final cell = ((usable / 32) - 1.2).clamp(4.0, 22.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var o = 0; o < 4; o++) ...[
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var b = 0; b < 8; b++)
                          _Bit(
                            isOne: octets[o][b] == 1,
                            isNetwork: (o * 8 + b) < prefix,
                            width: cell,
                          ),
                      ],
                    ),
                  ),
                  if (o < 3) const SizedBox(width: 10),
                ],
              ],
            ),
            if (showColonLabels) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var o = 0; o < 4; o++) ...[
                    Expanded(
                      child: Text(
                        'octet ${o + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (o < 3) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Bit extends StatelessWidget {
  const _Bit({
    required this.isOne,
    required this.isNetwork,
    required this.width,
  });

  final bool isOne;
  final bool isNetwork;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = isNetwork ? AppColors.accent : AppColors.textFaint;
    return Container(
      width: width,
      height: width.clamp(18, 26),
      margin: const EdgeInsets.symmetric(horizontal: 0.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isOne
            ? color.withValues(alpha: isNetwork ? 0.22 : 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isOne
              ? color.withValues(alpha: 0.55)
              : AppColors.divider.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        isOne ? '1' : '0',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: (width * 0.55).clamp(7, 12),
          color: isOne ? color : AppColors.textFaint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
