import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';
import '../../data/providers.dart';
import '../../models/course.dart';
import '../../models/topic.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final user = ref.watch(authControllerProvider);
    final uni = user == null ? null : data.university(user.universityId);
    // Courses at the student's university for their current semester,
    // de-duplicated by name (gen-ed courses repeat across programs).
    final myCourses = <Course>[];
    if (user != null) {
      final seen = <String>{};
      for (final c in data.coursesOfUniversity(user.universityId)) {
        if (c.semester == user.semester && seen.add(c.name)) {
          myCourses.add(c);
        }
      }
    }
    final trending = data.trendingTopics;

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(appDataProvider.notifier).sync(),
          color: AppColors.primary,
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${user?.name.split(' ').first ?? 'there'} 👋',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        uni == null
                            ? 'Let\'s get you ready'
                            : (user!.campus.isNotEmpty
                                ? '${uni.shortName} · ${user.campus}'
                                : uni.shortName),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _Avatar(initials: user?.initials ?? '?'),
              ],
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            const SizedBox(height: 20),
            _SearchBar(onTap: () => context.push('/search')),
            if (data.upcomingPlans.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                icon: LucideIcons.calendar,
                title: 'Upcoming exams',
                subtitle: 'Your study plans',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.upcomingPlans.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final plan = data.upcomingPlans[i];
                    final course = data.course(plan.courseId);
                    return _ExamCountdownCard(
                      courseCode: course?.code ?? 'Course',
                      courseName: course?.name ?? '',
                      daysLeft: _daysLeft(plan.examDate),
                      onTap: () =>
                          context.push('/study-plan/${plan.courseId}'),
                    ).animate().fadeIn(delay: (70 * i).ms).slideX(begin: 0.2, end: 0);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SectionHeader(
              icon: LucideIcons.trendingUp,
              title: 'High-priority topics',
              subtitle: 'Most likely to appear',
            ),
            const SizedBox(height: 12),
            if (trending.isEmpty)
              _emptyHint(context, 'Topic predictions will show up here.')
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trending.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final t = trending[i];
                    final course = data.course(t.courseId);
                    return _TrendingCard(topic: t, course: course)
                        .animate()
                        .fadeIn(delay: (80 * i).ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                ),
              ),
            const SizedBox(height: 28),
            _SectionHeader(
              icon: LucideIcons.bookMarked,
              title: user == null
                  ? 'Your courses'
                  : 'Semester ${user.semester} courses',
              subtitle: 'Jump straight in',
            ),
            const SizedBox(height: 12),
            if (myCourses.isEmpty)
              _emptyHint(context,
                  'Set your semester in Profile to see your courses here.')
            else
              ...myCourses.take(6).mapIndexed(
                    (i, c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CourseRow(course: c)
                          .animate()
                          .fadeIn(delay: (60 * i).ms)
                          .slideY(begin: 0.15, end: 0),
                    ),
                  ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) => GlassCard(
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int i, E e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i, e);
      i++;
    }
  }
}

int _daysLeft(DateTime exam) {
  final now = DateTime.now();
  return DateTime(exam.year, exam.month, exam.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
}

class _ExamCountdownCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final int daysLeft;
  final VoidCallback onTap;
  const _ExamCountdownCard({
    required this.courseCode,
    required this.courseName,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = daysLeft < 0
        ? 'Passed'
        : daysLeft == 0
            ? 'Today'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.heroGradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.calendar, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(courseCode,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            Text(courseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(LucideIcons.search,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            'Search courses, topics…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Topic topic;
  final Course? course;
  const _TrendingCard({required this.topic, required this.course});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: GlassCard(
        onTap: course == null
            ? null
            : () => context.push('/course/${course!.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${topic.percent.round()}%',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  course?.code ?? '',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              topic.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              topic.priorityLabel,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  const _CourseRow({required this.course});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/course/${course.id}'),
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
            child: const Icon(LucideIcons.bookOpen,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  course.code,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
