import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/iterable_ext.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';
import '../../models/course.dart';
import 'add_course_sheet.dart';

class CoursesScreen extends ConsumerWidget {
  final String departmentId;
  final int semester;
  const CoursesScreen({
    super.key,
    required this.departmentId,
    required this.semester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final dept = data.department(departmentId);
    final courses = data.coursesOfSemester(departmentId, semester);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('${dept?.name ?? 'Courses'} · Sem $semester')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAddSubject(context, ref, dept?.universityId),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Add subject',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text('Semester $semester courses',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Missing a subject? Tap “Add subject” to add it and share notes.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              ...courses.mapIndexed((i, c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CourseCard(course: c, data: data)
                        .animate()
                        .fadeIn(delay: (40 * i).ms)
                        .slideY(begin: 0.12, end: 0),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddSubject(BuildContext context, WidgetRef ref, String? uniId) {
    if (uniId == null) return;
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCourseSheet(
        departmentId: departmentId,
        universityId: uniId,
        semester: semester,
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final AppData data;
  const _CourseCard({required this.course, required this.data});

  @override
  Widget build(BuildContext context) {
    final noteCount = data.notesOf(course.id).length;
    final topicCount = data.topicsOf(course.id).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/course/${course.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.code,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (course.isCustom)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Added by student',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  const Spacer(),
                  Text('${course.creditHours} CH',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(course.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat(LucideIcons.fileText, '$noteCount notes'),
                  const SizedBox(width: 16),
                  _stat(LucideIcons.trendingUp, '$topicCount topics'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      );
}
