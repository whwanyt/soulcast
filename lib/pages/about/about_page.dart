import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/constants/app_links.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// 关于我们页面：品牌介绍、版本信息与相关入口。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _packageInfo = info);
  }

  Future<void> _openLink(String url) async {
    final translations = context.t.about;
    if (url.trim().isEmpty) {
      await SmartDialog.showToast(translations.linkComingSoon);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      await SmartDialog.showToast(translations.linkComingSoon);
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      await SmartDialog.showToast(translations.linkComingSoon);
    }
  }

  void _openLicenses() {
    final translations = context.t;
    final info = _packageInfo;
    showLicensePage(
      context: context,
      applicationName: translations.appName,
      applicationVersion: info == null
          ? null
          : '${info.version} (${info.buildNumber})',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Image.asset(
            'assets/page_app_icon.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.square(dimension: 48),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final about = translations.about;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = _packageInfo;
    final versionLabel = info == null
        ? '—'
        : '${info.version} (${info.buildNumber})';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(about.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      child: Image.asset(
                        'assets/page_app_icon.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const SizedBox.square(dimension: 88),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      translations.appName,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      about.tagline,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              clipBehavior: Clip.antiAlias,
              child: _AboutInfoTile(
                leading: LucideIcons.info,
                title: about.version,
                subtitle: versionLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AboutActionTile(
                    onTap: () => _openLink(AppLinks.website),
                    leading: LucideIcons.globe,
                    title: about.website,
                    subtitle: about.websiteSubtitle,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  _AboutActionTile(
                    onTap: () => _openLink(AppLinks.terms),
                    leading: LucideIcons.fileText,
                    title: about.terms,
                    subtitle: about.termsSubtitle,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  _AboutActionTile(
                    onTap: () => _openLink(AppLinks.privacy),
                    leading: LucideIcons.shield,
                    title: about.privacy,
                    subtitle: about.privacySubtitle,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  _AboutActionTile(
                    onTap: () => _openLink(AppLinks.feedback),
                    leading: LucideIcons.messageCircle,
                    title: about.feedback,
                    subtitle: about.feedbackSubtitle,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  _AboutActionTile(
                    onTap: _openLicenses,
                    leading: LucideIcons.scale,
                    title: about.licenses,
                    subtitle: about.licensesSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              about.copyright,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoTile extends StatelessWidget {
  const _AboutInfoTile({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final IconData leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(leading, size: 22, color: colorScheme.onSurface),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutActionTile extends StatelessWidget {
  const _AboutActionTile({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final IconData leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(leading, size: 22, color: colorScheme.onSurface),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
