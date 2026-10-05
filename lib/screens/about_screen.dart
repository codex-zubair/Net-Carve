import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// About / company screen hosting the B2B "clean code" Showcase hook.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open $url'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPadding,
          24,
          AppTheme.screenPadding,
          24,
        ),
        children: [
          Center(
            child: Column(
              children: [
                const BrandLogo(size: 48, showText: false),
                const SizedBox(height: 14),
                const Text(
                  AppInfo.name,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppInfo.tagline,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    'v${AppInfo.version} · by ${AppInfo.company}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _ShowcaseCard(onOpen: _open),
          const SizedBox(height: 18),
          const SectionLabel('Why NetCarve is different'),
          const PanelCard(
            child: Column(
              children: [
                _Feature(
                  icon: Icons.wifi_off_rounded,
                  title: 'Completely offline',
                  body:
                      'No internet permission, no network calls. It works in '
                      'air-gapped data centres and secure facilities.',
                ),
                _Feature(
                  icon: Icons.block_rounded,
                  title: 'No ads, no trackers',
                  body:
                      'Zero advertising SDKs, zero analytics. Your input never '
                      'leaves the device.',
                ),
                _Feature(
                  icon: Icons.speed_rounded,
                  title: 'Exact binary math',
                  body:
                      'IPv4/IPv6 parsing and VLSM planning from integer bit '
                      'operations — correct for every prefix length.',
                ),
                _Feature(
                  icon: Icons.grid_view_rounded,
                  title: 'VLSM planner',
                  body:
                      'Carve a parent block into equal or right-sized, '
                      'non-overlapping subnets in one tap.',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Legal & links'),
          PanelCard(
            padding: 8,
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _open(context, AppInfo.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.code_rounded,
                  label: 'Source code on GitHub',
                  onTap: () => _open(context, AppInfo.githubUrl),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.mail_outline_rounded,
                  label: AppInfo.contactEmail,
                  onTap: () => _open(context, 'mailto:${AppInfo.contactEmail}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              '© ${DateTime.now().year} ${AppInfo.company}. MIT licensed.\n'
              'Built as a demonstration of world-class native software.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.onOpen});

  final Future<void> Function(BuildContext, String) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.blue.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.accent,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'View our clean code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The complete, unminified source for NetCarve is open on GitHub. '
            'See exactly how Across Cloud LLC designs and ships production '
            'native software.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onOpen(context, AppInfo.githubUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('View our Clean Code on GitHub'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textMuted, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textFaint,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
