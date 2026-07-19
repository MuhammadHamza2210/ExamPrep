import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../models/study_plan.dart';
import '../../models/topic.dart';
import '../topics/widgets/topic_widgets.dart';

/// Turns crowd-sourced topic likelihood into an actionable, prioritised
/// cram plan for one course's exam.
class StudyPlanScreen extends ConsumerWidget {
  final String courseId;
  const StudyPlanScreen({super.key, required this.courseId});

  static int daysLeft(DateTime exam) {
    final now = DateTime.now();
    final a = DateTime(exam.year, exam.month, exam.day);
    final b = DateTime(now.year, now.month, now.day);
    return a.difference(b).inDays;
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref,
      {DateTime? initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      await ref.read(appDataProvider.notifier).setStudyPlan(courseId, picked);
      Haptics.success();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final course = data.course(courseId);
    final plan = data.planFor(courseId);
    final topics = data.topicsOf(courseId); // sorted by likelihood desc

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(course?.code ?? 'Study Plan'),
        actions: [
          if (plan != null)
            IconButton(
              tooltip: 'Remove plan',
              icon: const Icon(LucideIcons.x),
              onPressed: () async {
                await ref
                    .read(appDataProvider.notifier)
                    .deleteStudyPlan(courseId);
                if (context.mounted) {
                  AppSnack.show(context, 'Study plan removed');
                }
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: plan == null
              ? _SetupView(
                  onPick: () => _pickDate(context, ref),
                  hasTopics: topics.isNotEmpty,
                )
              : _PlanView(
                  plan: plan,
                  topics: topics,
                  courseName: course?.name ?? '',
                  onChangeDate: () =>
                      _pickDate(context, ref, initial: plan.examDate),
                  onToggle: (id) => ref
                      .read(appDataProvider.notifier)
                      .toggleTopicStudied(courseId, id),
                  onOpenNotes: () => context.push('/course/$courseId'),
                ),
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  final VoidCallback onPick;
  final bool hasTopics;
  const _SetupView({required this.onPick, required this.hasTopics});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.calendar,
      title: 'Plan your exam prep',
      message: hasTopics
          ? 'Set your exam date and we\'ll build a prioritised list — highest-'
              'likelihood topics first, so you study what matters most.'
          : 'No topics tracked for this course yet. Add important topics first, '
              'then set your exam date.',
      action: SizedBox(
        width: 220,
        child: PrimaryButton(
          label: 'Set exam date',
          icon: LucideIcons.calendar,
          onPressed: onPick,
        ),
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final StudyPlan plan;
  final List<Topic> topics;
  final String courseName;
  final VoidCallback onChangeDate;
  final ValueChanged<String> onToggle;
  final VoidCallback onOpenNotes;

  const _PlanView({
    required this.plan,
    required this.topics,
    required this.courseName,
    required this.onChangeDate,
    required this.onToggle,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    final days = StudyPlanScreen.daysLeft(plan.examDate);
    final done = topics.where((t) => plan.checkedTopicIds.contains(t.id)).length;
    final progress = topics.isEmpty ? 0.0 : done / topics.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _CountdownCard(days: days, onChangeDate: onChangeDate)
            .animate()
            .fadeIn()
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Progress',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('$done / ${topics.length} topics',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              if (progress >= 1 && topics.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('All caught up — you\'ve got this! 🎉',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(LucideIcons.trendingUp,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Study these first',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: onOpenNotes,
              icon: const Icon(LucideIcons.fileText, size: 16),
              label: const Text('Notes'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Ordered by exam likelihood. Tick topics as you finish them.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 12),
        if (topics.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No topics yet for this course.'),
          )
        else
          ...topics.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final checked = plan.checkedTopicIds.contains(t.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlanTopicTile(
                rank: i + 1,
                topic: t,
                checked: checked,
                onToggle: () {
                  Haptics.light();
                  onToggle(t.id);
                },
              ),
            ).animate().fadeIn(delay: (35 * i).ms).slideX(begin: 0.05, end: 0);
          }),
      ],
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final int days;
  final VoidCallback onChangeDate;
  const _CountdownCard({required this.days, required this.onChangeDate});

  @override
  Widget build(BuildContext context) {
    final label = days < 0
        ? 'Exam passed'
        : days == 0
            ? 'Exam is today!'
            : days == 1
                ? '1 day to go'
                : '$days days to go';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Tap to change your exam date',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onChangeDate,
            icon: const Icon(LucideIcons.calendar, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PlanTopicTile extends StatelessWidget {
  final int rank;
  final Topic topic;
  final bool checked;
  final VoidCallback onToggle;
  const _PlanTopicTile({
    required this.rank,
    required this.topic,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(topic.weightedScore);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onToggle,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? AppColors.accent : Colors.transparent,
              border: Border.all(
                color: checked ? AppColors.accent : AppColors.textSecondary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: checked
                ? const Icon(LucideIcons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              topic.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? AppColors.textSecondary : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${topic.percent.round()}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
