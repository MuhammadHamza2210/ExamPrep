import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../data/curriculum.dart';
import '../../models/department.dart';

/// Lets a student add a whole department / degree program to a university.
/// They can base it on a shipped curriculum or start empty.
class AddDepartmentSheet extends ConsumerStatefulWidget {
  final String universityId;
  final String campus;
  const AddDepartmentSheet({
    super.key,
    required this.universityId,
    this.campus = '',
  });

  @override
  ConsumerState<AddDepartmentSheet> createState() => _AddDepartmentSheetState();
}

class _AddDepartmentSheetState extends ConsumerState<AddDepartmentSheet> {
  final _name = TextEditingController();
  String _program = kProgramTemplates.first.$1;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      AppSnack.show(context, 'Enter the department name', success: false);
      return;
    }
    setState(() => _saving = true);
    final Department dept;
    try {
      dept = await ref.read(appDataProvider.notifier).addCustomDepartment(
            universityId: widget.universityId,
            name: _name.text,
            program: _program,
            campus: widget.campus,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.show(context, 'Could not add department. Check your connection.',
          success: false);
      return;
    }
    Haptics.success();
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnack.show(context, 'Department added!');
    context.push('/department/${dept.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startsEmpty = _program == 'custom';

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
            Text('Add a department',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Add a program to this university. Pick a curriculum to pre-fill '
              'courses, or start empty and add your own.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Department name (e.g. Data Science)',
                prefixIcon: Icon(LucideIcons.folder, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _program,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Curriculum template',
                prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
              ),
              items: kProgramTemplates
                  .map((t) => DropdownMenuItem(
                        value: t.$1,
                        child: Text(t.$2, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _program = v ?? _program),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(startsEmpty ? LucideIcons.info : LucideIcons.checkCircle,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    startsEmpty
                        ? 'Starts empty — you can add subjects to each semester.'
                        : 'Pre-fills 8 semesters of standard courses.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add department',
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
