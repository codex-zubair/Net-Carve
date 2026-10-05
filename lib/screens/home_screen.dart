import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/ipv4.dart';
import '../core/subnet.dart';
import '../state/calculator_state.dart';
import '../theme/app_theme.dart';
import '../widgets/binary_view.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final state = context.read<CalculatorState>();
    _controller = TextEditingController(text: state.input);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncFromState() {
    final state = context.read<CalculatorState>();
    if (_controller.text != state.input) {
      _controller.text = state.input;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalculatorState>();
    // Keep the text field aligned when a preset/history item is applied.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());

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
          const _Header(),
          const SizedBox(height: 20),
          _InputCard(controller: _controller),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: state.error!),
          ],
          const SizedBox(height: 16),
          _Presets(
            onSelected: (preset) {
              context.read<CalculatorState>().applyPreset(preset);
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 18),
          if (state.result != null)
            _ResultView(info: state.result!)
          else
            const _EmptyHint(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const BrandLogo(size: 34),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Offline · Ad-free',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IPv4 address or CIDR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9./\s]')),
            ],
            style: AppTheme.mono(size: 17, weight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '192.168.1.0/24',
              prefixIcon: Icon(
                Icons.travel_explore_rounded,
                color: AppColors.textFaint,
              ),
            ),
            onChanged: (value) =>
                context.read<CalculatorState>().updateInput(value),
            onSubmitted: (_) => context.read<CalculatorState>().commit(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    context.read<CalculatorState>().commit();
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Calculate & Save'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Clear',
                onPressed: () {
                  controller.clear();
                  context.read<CalculatorState>().updateInput('');
                },
                icon: const Icon(Icons.backspace_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Presets extends StatelessWidget {
  const _Presets({required this.onSelected});

  final ValueChanged<CidrPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Quick presets'),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CalculatorState.presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final preset = CalculatorState.presets[i];
              return ActionChip(
                onPressed: () => onSelected(preset),
                avatar: const Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: AppColors.accent,
                ),
                label: Text(preset.label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.info});

  final SubnetInfo info;

  @override
  Widget build(BuildContext context) {
    final network = info.network;
    final isPrivate = network.isPrivate;
    final isReserved = network.isReserved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Result'),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CopyText(value: info.cidr, size: 24, bold: true),
              const SizedBox(height: 4),
              Text(
                'Network block  ·  /${info.prefix}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoBadge(
                    isPrivate ? 'Private (RFC 1918)' : 'Public',
                    color: isPrivate ? AppColors.amber : AppColors.success,
                  ),
                  InfoBadge(network.addressClass.label),
                  if (isReserved)
                    const InfoBadge(
                      'Reserved / not routable',
                      color: AppColors.danger,
                    ),
                  if (info.isPointToPoint)
                    const InfoBadge(
                      'Point-to-point /31',
                      color: AppColors.violet,
                    ),
                  if (info.isHostRoute)
                    const InfoBadge('Host route /32', color: AppColors.violet),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Address details'),
        PanelCard(
          child: Column(
            children: [
              InfoRow(label: 'Network', value: network.dotted),
              const Divider(height: 1),
              InfoRow(label: 'Broadcast', value: info.broadcast.dotted),
              const Divider(height: 1),
              InfoRow(label: 'Subnet mask', value: info.netmask.dotted),
              const Divider(height: 1),
              InfoRow(label: 'Wildcard', value: info.wildcard.dotted),
              const Divider(height: 1),
              InfoRow(
                label: 'First host',
                value: info.firstHost?.dotted ?? '—',
              ),
              const Divider(height: 1),
              InfoRow(label: 'Last host', value: info.lastHost?.dotted ?? '—'),
              const Divider(height: 1),
              InfoRow(label: 'Gateway*', value: info.firstHost?.dotted ?? '—'),
              const Divider(height: 1),
              InfoRow(label: 'Range', value: info.range, copyable: false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Capacity'),
        PanelCard(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Usable hosts',
                  value: formatCount(info.usableHosts),
                  color: AppColors.accent,
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.divider),
              Expanded(
                child: _Stat(
                  label: 'Total addresses',
                  value: formatCount(info.totalAddresses),
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.divider),
              Expanded(
                child: _Stat(label: 'Prefix', value: '/${info.prefix}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Binary'),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network address',
                style: AppTheme.mono(size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              BinaryView(value: network.value, prefix: info.prefix),
              const SizedBox(height: 18),
              Text(
                'Subnet mask',
                style: AppTheme.mono(size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              BinaryView(
                value: info.netmask.value,
                prefix: info.prefix,
                showColonLabels: false,
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _LegendDot(color: AppColors.accent, label: 'Network bits'),
                  SizedBox(width: 16),
                  _LegendDot(color: AppColors.textFaint, label: 'Host bits'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '* Gateway is shown as the conventional first usable host. '
          'NetCarve performs no network requests — every value is computed '
          'locally from integer binary math.',
          style: TextStyle(
            color: AppColors.textFaint,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color = AppColors.text,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.mono(size: 17, weight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textFaint, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
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
              message,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 34,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter an address like 10.0.0.0/16 or tap a preset.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
