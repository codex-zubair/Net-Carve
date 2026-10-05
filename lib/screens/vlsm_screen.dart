import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/subnet.dart';
import '../core/vlsm.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Interactive VLSM planner: split a parent block either equally or by a list
/// of host requirements.
class VlsmScreen extends StatefulWidget {
  const VlsmScreen({super.key});

  @override
  State<VlsmScreen> createState() => _VlsmScreenState();
}

class _VlsmScreenState extends State<VlsmScreen> {
  final _parentController = TextEditingController(text: '192.168.0.0/24');
  final _equalCountController = TextEditingController(text: '4');
  final _reqNameController = TextEditingController();
  final _reqHostsController = TextEditingController();
  final List<HostRequirement> _requirements = [];

  VlsmMode _mode = VlsmMode.equalSplit;
  String? _error;
  VlsmPlan? _plan;

  @override
  void dispose() {
    _parentController.dispose();
    _equalCountController.dispose();
    _reqNameController.dispose();
    _reqHostsController.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _error = null;
      _plan = null;
      SubnetInfo parent;
      try {
        parent = SubnetCalculator.parseCidr(_parentController.text.trim());
      } on FormatException catch (e) {
        _error = 'Parent block: ${e.message}';
        return;
      } on ArgumentError catch (e) {
        _error = 'Parent block: ${e.message}';
        return;
      }

      try {
        if (_mode == VlsmMode.equalSplit) {
          final count = int.tryParse(_equalCountController.text.trim());
          if (count == null) {
            _error = 'Subnet count must be a number.';
            return;
          }
          _plan = VlsmPlanner.equalSplit(parent, count);
        } else {
          if (_requirements.isEmpty) {
            _error = 'Add at least one host requirement.';
            return;
          }
          _plan = VlsmPlanner.fromHostRequirements(parent, _requirements);
        }
      } on ArgumentError catch (e) {
        _error = e.message;
      }
    });
  }

  void _addRequirement() {
    final name = _reqNameController.text.trim();
    final hosts = int.tryParse(_reqHostsController.text.trim());
    if (name.isEmpty || hosts == null || hosts < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Enter a name and a host count of at least 1.'),
        ),
      );
      return;
    }
    setState(() {
      _requirements.add(HostRequirement(name, hosts));
      _reqNameController.clear();
      _reqHostsController.clear();
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
            'VLSM Planner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Carve a parent block into correctly sized, non-overlapping subnets.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent block',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _parentController,
                  autocorrect: false,
                  style: AppTheme.mono(size: 15, weight: FontWeight.w600),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9./\s]')),
                  ],
                  decoration: const InputDecoration(hintText: '10.0.0.0/24'),
                ),
                const SizedBox(height: 16),
                SegmentedButton<VlsmMode>(
                  segments: const [
                    ButtonSegment(
                      value: VlsmMode.equalSplit,
                      label: Text('Equal split'),
                      icon: Icon(Icons.grid_view_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: VlsmMode.hostRequirements,
                      label: Text('By hosts'),
                      icon: Icon(Icons.tune_rounded, size: 16),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    _plan = null;
                    _error = null;
                  }),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.accent.withValues(alpha: 0.18)
                          : AppColors.surfaceHi,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_mode == VlsmMode.equalSplit)
                  _equalSplitControls()
                else
                  _hostControls(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _run();
                    },
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Generate plan'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorBox(_error!),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 20),
            _PlanView(plan: _plan!),
          ],
        ],
      ),
    );
  }

  Widget _equalSplitControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of subnets (power of two)',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _equalCountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTheme.mono(size: 15, weight: FontWeight.w600),
          decoration: const InputDecoration(hintText: '4'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in const [2, 4, 8, 16, 32, 64])
              ActionChip(
                label: Text('$n'),
                onPressed: () =>
                    setState(() => _equalCountController.text = '$n'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _hostControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Host requirements',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _reqNameController,
                style: AppTheme.mono(size: 14),
                decoration: const InputDecoration(hintText: 'Subnet name'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _reqHostsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTheme.mono(size: 14),
                decoration: const InputDecoration(hintText: 'Hosts'),
                onSubmitted: (_) => _addRequirement(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _addRequirement,
              icon: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        if (_requirements.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _requirements.length; i++)
                InputChip(
                  label: Text(
                    '${_requirements[i].name} · ${_requirements[i].hosts}',
                  ),
                  onDeleted: () => setState(() => _requirements.removeAt(i)),
                  deleteIconColor: AppColors.textFaint,
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Common host counts',
          style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in const [2, 6, 14, 30, 62, 126, 254])
              ActionChip(
                label: Text('$h hosts'),
                onPressed: () {
                  setState(() {
                    _reqNameController.text = _reqNameController.text.isEmpty
                        ? 'Subnet ${_requirements.length + 1}'
                        : _reqNameController.text;
                    _reqHostsController.text = '$h';
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
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

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final VlsmPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel('Plan'),
            const Spacer(),
            Text(
              '${plan.allocations.length} subnets  ·  '
              '${(plan.utilisation * 100).toStringAsFixed(1)}% used',
              style: AppTheme.mono(size: 11.5, color: AppColors.accentSoft),
            ),
          ],
        ),
        if (plan.unallocated.isNotEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.amber,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Could not allocate',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final item in plan.unallocated)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        for (final allocation in plan.allocations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AllocationTile(allocation: allocation),
          ),
        const SizedBox(height: 4),
        Text(
          'Free: ${formatCount(plan.freeAddresses)} of '
          '${formatCount(plan.parent.totalAddresses)} addresses remain in '
          '${plan.parent.cidr}.',
          style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({required this.allocation});

  final VlsmAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final subnet = allocation.subnet;
    return PanelCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  allocation.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              InfoBadge('/${subnet.prefix}', color: AppColors.blue),
            ],
          ),
          const SizedBox(height: 10),
          CopyText(value: subnet.cidr, size: 15, bold: true),
          const SizedBox(height: 8),
          _miniRow('Mask', subnet.netmask.dotted),
          _miniRow('Range', subnet.range),
          _miniRow('Hosts', formatCount(subnet.usableHosts)),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: CopyText(value: value, size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
