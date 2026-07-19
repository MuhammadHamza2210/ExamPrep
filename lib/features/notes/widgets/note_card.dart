import 'package:flutter/material.dart';
import 'package:examprep/core/icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/exam_type_chip.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  const NoteCard({super.key, required this.note, required this.onTap});

  IconData get _icon {
    if (note.isImage) return LucideIcons.image;
    if (note.isPdf) return LucideIcons.fileText;
    if (note.hasFile) return LucideIcons.file;
    return LucideIcons.alignLeft;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'note-${note.id}',
      // Hero over a Material/glass card — flightShuttle keeps it simple.
      child: Material(
        type: MaterialType.transparency,
        child: GlassCard(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: note.examType.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: note.examType.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${note.uploaderName}'
                      '${note.chapter.isNotEmpty ? ' · ${note.chapter}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ExamTypeChip(type: note.examType, dense: true),
                        const SizedBox(width: 10),
                        StarDisplay(rating: note.averageRating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          note.ratingCount == 0
                              ? 'New'
                              : note.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
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
