import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../data/providers.dart';
import '../../models/exam_type.dart';

class UploadNoteSheet extends ConsumerStatefulWidget {
  final String courseId;
  const UploadNoteSheet({super.key, required this.courseId});

  @override
  ConsumerState<UploadNoteSheet> createState() => _UploadNoteSheetState();
}

class _UploadNoteSheetState extends ConsumerState<UploadNoteSheet> {
  final _title = TextEditingController();
  final _chapter = TextEditingController();
  final _text = TextEditingController();
  ExamType _examType = ExamType.finalExam;
  String? _filePath;
  String? _fileName;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    _title.dispose();
    _chapter.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
        });
        Haptics.select();
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(context, 'Could not open file picker', success: false);
      }
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      AppSnack.show(context, 'Please give your note a title', success: false);
      return;
    }
    if ((_filePath == null) && _text.text.trim().isEmpty) {
      AppSnack.show(context, 'Attach a file or type some notes',
          success: false);
      return;
    }
    setState(() => _saving = true);
    final user = ref.read(authControllerProvider);
    try {
      await ref.read(appDataProvider.notifier).addNote(
            courseId: widget.courseId,
            uploaderName: user?.name ?? 'Student',
            title: _title.text.trim(),
            chapter: _chapter.text.trim(),
            examType: _examType,
            textBody: _text.text.trim(),
            localFilePath: _filePath,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.show(context, 'Upload failed. Please try again.',
          success: false);
      return;
    }
    Haptics.success();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: _done ? _successView() : _formView(),
      ),
    );
  }

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 44),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text('Note uploaded!',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Thanks for helping your fellow students.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _formView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Upload notes',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'Title (e.g. Trees cheat sheet)',
              prefixIcon: Icon(LucideIcons.type, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chapter,
            decoration: const InputDecoration(
              hintText: 'Chapter / topic (optional)',
              prefixIcon: Icon(LucideIcons.bookmark, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Text('Exam type',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: ExamType.values.map((t) {
              final selected = t == _examType;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    Haptics.select();
                    setState(() => _examType = t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.color.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? t.color
                            : AppColors.textSecondary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        color: selected ? t.color : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(
                      _fileName == null
                          ? LucideIcons.paperclip
                          : LucideIcons.checkCircle,
                      color: AppColors.primary,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'Attach a PDF or image (optional)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _fileName == null
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_fileName != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _fileName = null;
                        _filePath = null;
                      }),
                      child: const Icon(LucideIcons.x,
                          size: 18, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Or type your notes here…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Share note',
            icon: LucideIcons.upload,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
