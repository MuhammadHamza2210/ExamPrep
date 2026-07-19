import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/iterable_ext.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../models/note.dart';
import '../../models/topic.dart';
import '../notes/upload_note_sheet.dart';
import '../notes/widgets/note_card.dart';
import '../topics/add_topic_sheet.dart';
import '../topics/widgets/topic_widgets.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final course = data.course(courseId);

    if (course == null) {
      return const Scaffold(
        body: Center(child: Text('Course not found')),
      );
    }

    final notes = data.notesOf(courseId);
    final topics = data.topicsOf(courseId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => _openUpload(context, ref),
          icon: const Icon(LucideIcons.upload, size: 18),
          label: const Text('Upload',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.code,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Notes'),
                      Tab(text: 'Important Topics'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _NotesTab(
                        notes: notes,
                        onUpload: () => _openUpload(context, ref),
                      ),
                      _TopicsTab(courseId: courseId, topics: topics),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openUpload(BuildContext context, WidgetRef ref) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UploadNoteSheet(courseId: courseId),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final List<Note> notes;
  final VoidCallback onUpload;
  const _NotesTab({required this.notes, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return EmptyState(
        icon: LucideIcons.fileText,
        title: 'No notes yet',
        message: 'Be the first to share notes for this course.',
        action: SizedBox(
          width: 200,
          child: PrimaryButton(
            label: 'Upload notes',
            icon: LucideIcons.upload,
            onPressed: onUpload,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final note = notes[i];
        return NoteCard(
          note: note,
          onTap: () => context.push('/note/${note.id}'),
        ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _TopicsTab extends ConsumerWidget {
  final String courseId;
  final List<Topic> topics;
  const _TopicsTab({required this.courseId, required this.topics});

  void _openAddTopic(BuildContext context) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTopicSheet(courseId: courseId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topics.isEmpty) {
      return EmptyState(
        icon: LucideIcons.trendingUp,
        title: 'No topics tracked yet',
        message:
            'Be the first — add the topics that usually come in this exam so '
            'other students know what matters.',
        action: SizedBox(
          width: 260,
          child: PrimaryButton(
            label: 'Add important topic',
            icon: LucideIcons.plus,
            onPressed: () => _openAddTopic(context),
          ),
        ),
      );
    }

    void vote(String id, bool appeared) {
      Haptics.success();
      ref
          .read(appDataProvider.notifier)
          .markTopicAppeared(id, appeared: appeared);
      AppSnack.show(
        context,
        appeared ? 'Thanks! Vote recorded.' : 'Marked as "did not appear".',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Study plan',
                icon: LucideIcons.calendar,
                onPressed: () => context.push('/study-plan/$courseId'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openAddTopic(context),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add topic'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sorted by likelihood. Tap "Came in exam" after your paper to improve predictions for everyone.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35),
                ),
              ),
            ],
          ),
        ),
        TopicRadarChart(topics: topics),
        const SizedBox(height: 16),
        ...topics.mapIndexed((i, t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TopicTile(
                rank: i + 1,
                topic: t,
                myVote: ref.watch(appDataProvider).myVoteFor(t.id),
                onAppeared: () => vote(t.id, true),
                onNotAppeared: () => vote(t.id, false),
              ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.1, end: 0),
            )),
      ],
    );
  }
}
