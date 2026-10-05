import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../state/calculator_state.dart';
import '../theme/app_theme.dart';

/// Local-only calculation history.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalculatorState>();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              14,
              AppTheme.screenPadding,
              0,
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Saved on this device only.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (state.history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, state),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : state.history.isEmpty
                ? const _Empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenPadding,
                      8,
                      AppTheme.screenPadding,
                      24,
                    ),
                    itemCount: state.history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _HistoryTile(
                      entry: state.history[i],
                      onTap: () => _open(context, state, state.history[i]),
                      onDelete: () =>
                          state.removeHistory(state.history[i].cidr),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, CalculatorState state, HistoryEntry entry) {
    state.loadHistoryEntry(entry);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceTop,
          content: Text(
            'Loaded ${entry.cidr} into the calculator',
            style: AppTheme.mono(size: 12.5),
          ),
        ),
      );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CalculatorState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all saved calculations from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.clearHistory();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final valid = HistoryParser.isValid(entry.cidr);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.cidr,
                      style: AppTheme.mono(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _relativeTime(entry.timestamp),
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!valid)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${time.year}-${_two(time.month)}-${_two(time.day)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 44,
              color: AppColors.textFaint.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            const Text(
              'No saved calculations yet.\nTap "Calculate & Save" to keep a block.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
