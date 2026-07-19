import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/iterable_ext.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';
import '../../data/curriculum.dart';
import '../../data/providers.dart';
import 'add_department_sheet.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  final String universityId;
  const DepartmentsScreen({super.key, required this.universityId});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  String? _campus;

  void _openAddDepartment(BuildContext context) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDepartmentSheet(
        universityId: widget.universityId,
        campus: _campus ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final uni = data.university(widget.universityId);
    final user = ref.watch(authControllerProvider);
    final campuses = uni?.campuses ?? const <String>[];

    // Default the selected campus: the student's own campus if they study here,
    // otherwise the first campus.
    final selected = _campus ??
        (user != null &&
                user.universityId == widget.universityId &&
                campuses.contains(user.campus)
            ? user.campus
            : (campuses.isNotEmpty ? campuses.first : ''));

    final departments =
        data.departmentsForCampus(widget.universityId, selected);
    final showCampusPicker = campuses.length > 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(uni?.shortName ?? 'Departments')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAddDepartment(context),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Add department',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text('Departments',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                showCampusPicker
                    ? 'Choose a campus to see its departments.'
                    : 'Not listed? Tap “Add department” to add your program.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              if (showCampusPicker) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: campuses.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = campuses[i];
                      final active = c == selected;
                      return GestureDetector(
                        onTap: () {
                          Haptics.select();
                          setState(() => _campus = c);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    colors: AppColors.heroGradient)
                                : null,
                            color: active
                                ? null
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.mapPin,
                                  size: 14,
                                  color: active
                                      ? Colors.white
                                      : AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                c,
                                style: TextStyle(
                                  color:
                                      active ? Colors.white : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...departments.mapIndexed((i, d) {
                final courseCount = data.coursesOf(d.id).length;
                final programTitle = kProgramTitle[d.program] ?? d.name;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    onTap: () => context.push('/department/${d.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.folder,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(d.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                  ),
                                  if (d.isCustom) ...[
                                    const SizedBox(width: 8),
                                    _badge('Added', AppColors.accent),
                                  ] else if (d.campus.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    _badge(d.campus, AppColors.primary),
                                  ],
                                ],
                              ),
                              Text(
                                '$programTitle · $courseCount courses',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight,
                            size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (50 * i).ms)
                    .slideY(begin: 0.15, end: 0);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}
