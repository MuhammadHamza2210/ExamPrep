import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../models/course.dart';

/// Lets a student add a subject that isn't in the shipped curriculum
/// (e.g. an elective their campus offers), then jump in to share notes.
class AddCourseSheet extends ConsumerStatefulWidget {
  final String departmentId;
  final String universityId;
  final int semester;

  const AddCourseSheet({
    super.key,
    required this.departmentId,
    required this.universityId,
    required this.semester,
  });

  @override
  ConsumerState<AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends ConsumerState<AddCourseSheet> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      AppSnack.show(context, 'Enter the subject name', success: false);
      return;
    }
    setState(() => _saving = true);
    final Course course;
    try {
      course = await ref.read(appDataProvider.notifier).addCustomCourse(
            departmentId: widget.departmentId,
            universityId: widget.universityId,
            semester: widget.semester,
            name: _name.text,
            code: _code.text,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.show(context, 'Could not add subject. Check your connection.',
          success: false);
      return;
    }
    Haptics.success();
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnack.show(context, 'Subject added! Share your notes.');
    context.push('/course/${course.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text('Add a subject',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Adding to Semester ${widget.semester}. It will be visible to '
              'students browsing this semester.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Subject name (e.g. Artificial Intelligence)',
                prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Course code (optional, e.g. CS302)',
                prefixIcon: Icon(LucideIcons.hash, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add subject',
              icon: LucideIcons.plus,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
