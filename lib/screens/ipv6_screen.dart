import 'package:flutter/material.dart';

import '../core/ipv6.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Offline IPv6 explorer: parse, canonicalise and classify an address, then
/// show its block boundaries for a chosen prefix.
class Ipv6Screen extends StatefulWidget {
  const Ipv6Screen({super.key});

  @override
  State<Ipv6Screen> createState() => _Ipv6ScreenState();
}

class _Ipv6ScreenState extends State<Ipv6Screen> {
  final _controller = TextEditingController(
    text: '2001:db8:85a3::8a2e:370:7334',
  );
  int _prefix = 64;
  Ipv6Address? _address;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    setState(() {
      try {
        _address = Ipv6Address.parse(_controller.text);
        _error = null;
      } on FormatException catch (e) {
        _address = null;
        _error = e.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPadding,
          14,
          AppTheme.screenPadding,
          24,
        ),
        children: [
          const Text(
            'IPv6 Explorer',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Parse, canonicalise and classify a 128-bit address entirely offline.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IPv6 address',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: AppTheme.mono(size: 15, weight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '2001:db8::1',
                    prefixIcon: Icon(
                      Icons.language_rounded,
                      color: AppColors.textFaint,
                    ),
                  ),
                  onChanged: (_) => _parse(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '/$_prefix',
                      style: AppTheme.mono(
                        size: 15,
                        weight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _prefix.toDouble(),
                        min: 0,
                        max: 128,
                        divisions: 128,
                        label: '/$_prefix',
                        onChanged: (v) => setState(() => _prefix = v.round()),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in const [48, 56, 64, 96, 128])
                      ActionChip(
                        label: Text('/$p'),
                        onPressed: () => setState(() => _prefix = p),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_address != null) ...[
            const SizedBox(height: 18),
            const SectionLabel('Address'),
            PanelCard(
              child: Column(
                children: [
                  InfoRow(label: 'Compressed', value: _address!.compressed),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Full form',
                    value: _address!.expanded,
                    valueSize: 12,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Type',
                    value: _address!.type.label,
                    copyable: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Block boundaries'),
            PanelCard(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Network',
                    value: _address!.networkForPrefix(_prefix).compressed,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Last address',
                    value: _address!.lastForPrefix(_prefix).compressed,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Prefix length',
                    value: '/$_prefix',
                    copyable: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textFaint,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _prefix == 64
                          ? 'A /64 is the standard LAN size — 2^64 addresses, '
                                'reserved per subnet even for point-to-point links.'
                          : 'This block contains 2^${128 - _prefix} addresses.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
