import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/exam_type_chip.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/star_rating.dart';
import '../../data/app_data.dart';
import '../../models/note.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final note = data.note(noteId);

    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    final course = data.course(note.courseId);

    Future<void> openFile() async {
      if (!note.hasFile) return;
      await ref.read(appDataProvider.notifier).markDownloaded(note.id);
      if (note.filePath.startsWith('http')) {
        final ok = await launchUrl(Uri.parse(note.filePath),
            mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          AppSnack.show(context, 'Could not open file', success: false);
        }
      } else {
        final result = await OpenFile.open(note.filePath);
        if (result.type != ResultType.done && context.mounted) {
          AppSnack.show(context, 'Could not open file', success: false);
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(course?.code ?? 'Note'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Hero(
                tag: 'note-${note.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ExamTypeChip(type: note.examType),
                            const Spacer(),
                            StarDisplay(rating: note.averageRating, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              note.ratingCount == 0
                                  ? 'New'
                                  : '${note.averageRating.toStringAsFixed(1)} (${note.ratingCount})',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(note.title,
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          'by ${note.uploaderName}'
                          '${note.chapter.isNotEmpty ? ' · ${note.chapter}' : ''}',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Viewer(note: note, onOpen: openFile),
              const SizedBox(height: 16),
              _RateCard(noteId: note.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _Viewer extends StatelessWidget {
  final Note note;
  final Future<void> Function() onOpen;
  const _Viewer({required this.note, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isRemote = note.filePath.startsWith('http');
    if (note.isImage) {
      if (isRemote) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(note.filePath, fit: BoxFit.cover),
        );
      }
      if (File(note.filePath).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(File(note.filePath), fit: BoxFit.cover),
        );
      }
    }

    if (note.hasFile) {
      return GlassCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: note.examType.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                note.isPdf ? LucideIcons.fileText : LucideIcons.file,
                size: 44,
                color: note.examType.color,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              note.fileExtension.toUpperCase().isEmpty
                  ? 'Attached file'
                  : '${note.fileExtension.toUpperCase()} file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(LucideIcons.download, size: 18),
                label: const Text('Open / Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pure text note
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alignLeft,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            note.textBody.isEmpty ? 'No content.' : note.textBody,
            style: const TextStyle(height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends ConsumerWidget {
  final String noteId;
  const _RateCard({required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRating = ref.watch(appDataProvider).myRatingFor(noteId) ?? 0;
    final rated = myRating > 0;
    return GlassCard(
      child: Column(
        children: [
          Text(
            rated ? 'You rated this' : 'Rate these notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            rated ? 'Tap a star to change your rating.' : 'How useful were they?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          StarInput(
            value: myRating,
            onChanged: (v) {
              Haptics.success();
              ref.read(appDataProvider.notifier).rateNote(noteId, v);
              AppSnack.show(context, 'Rating saved');
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
