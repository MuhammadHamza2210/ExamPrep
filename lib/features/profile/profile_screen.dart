import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';
import '../../models/note.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openEdit(BuildContext context, AppUser user) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final data = ref.watch(appDataProvider);
    ref.watch(themeModeProvider); // rebuild when the theme changes
    final isDarkNow = Theme.of(context).brightness == Brightness.dark;
    final uni = user == null ? null : data.university(user.universityId);
    final uploads = data.myUploads;
    final downloads = data.myDownloads;
    final needsProfile = user != null && user.campus.isEmpty;

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 132),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.heroGradient),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Guest',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  if (user != null)
                    IconButton(
                      onPressed: () => _openEdit(context, user),
                      icon: const Icon(LucideIcons.edit,
                          color: AppColors.primary, size: 20),
                      tooltip: 'Edit profile',
                    ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            if (needsProfile) ...[
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => _openEdit(context, user),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete your profile — add your campus and semester '
                        'to see your courses.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.building2,
                    label: 'University',
                    value: uni?.shortName ?? '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.mapPin,
                    label: 'Campus',
                    value: (user?.campus.isNotEmpty ?? false)
                        ? user!.campus
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.calendar,
                    label: 'Semester',
                    value: user == null ? '—' : '${user.semester}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.bookOpen,
                    label: 'Degree',
                    value: user?.degreeProgram ?? '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsTile(
              icon: isDarkNow ? LucideIcons.moon : LucideIcons.sun,
              title: 'Dark mode',
              trailing: Switch(
                value: isDarkNow,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  Haptics.select();
                  ref
                      .read(themeModeProvider.notifier)
                      .set(v ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            const SizedBox(height: 24),
            _ContentSection(
              icon: LucideIcons.upload,
              title: 'My Uploads',
              notes: uploads,
              emptyText: 'You haven\'t uploaded any notes yet.',
            ),
            const SizedBox(height: 16),
            _ContentSection(
              icon: LucideIcons.download,
              title: 'My Downloads',
              notes: downloads,
              emptyText: 'Notes you open will appear here.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Haptics.medium();
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Note> notes;
  final String emptyText;
  const _ContentSection({
    required this.icon,
    required this.title,
    required this.notes,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${notes.length}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          if (notes.isEmpty) ...[
            const SizedBox(height: 12),
            Text(emptyText,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ] else
            ...notes.take(4).map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: () => context.push('/note/${n.id}'),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileText,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
