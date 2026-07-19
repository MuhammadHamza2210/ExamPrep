import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/iterable_ext.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';
import '../../data/curriculum.dart';
import '../../data/providers.dart';

class SemestersScreen extends ConsumerWidget {
  final String departmentId;
  const SemestersScreen({super.key, required this.departmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final dept = data.department(departmentId);
    // Every program has 8 semesters — always show them so students can browse
    // (and add subjects to) any semester, even in a freshly-added department.
    final semesters = List.generate(8, (i) => i + 1);
    final user = ref.watch(authControllerProvider);
    final mySemester = user?.semester;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(dept?.name ?? 'Semesters')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text('Semesters',
                  style: Theme.of(context).textTheme.titleLarge),
              if (dept != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    kProgramTitle[dept.program] ?? dept.name,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.32,
                children: semesters.mapIndexed((i, sem) {
                  final count =
                      data.coursesOfSemester(departmentId, sem).length;
                  return _SemesterCard(
                    semester: sem,
                    courseCount: count,
                    isCurrent: sem == mySemester,
                    onTap: () => context.push('/semester/$departmentId/$sem'),
                  )
                      .animate()
                      .fadeIn(delay: (45 * i).ms)
                      .scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          curve: Curves.easeOut);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final int courseCount;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SemesterCard({
    required this.semester,
    required this.courseCount,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF20202E), const Color(0xFF171720)]
                  : [Colors.white, const Color(0xFFF1EFFF)],
            ),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.10),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Big watermark number for a premium, graphic feel.
              Positioned(
                right: -6,
                bottom: -16,
                child: Text(
                  '$semester',
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.heroGradient),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text('$semester',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                        ),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('You',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Semester $semester',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$courseCount ${courseCount == 1 ? 'course' : 'courses'}',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(LucideIcons.arrowRight,
                              size: 15, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
