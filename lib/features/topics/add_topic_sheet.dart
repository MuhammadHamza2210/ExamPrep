import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';

/// Lets a student contribute an important topic to a course so future
/// students know what matters.
class AddTopicSheet extends ConsumerStatefulWidget {
  final String courseId;
  const AddTopicSheet({super.key, required this.courseId});

  @override
  ConsumerState<AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends ConsumerState<AddTopicSheet> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      AppSnack.show(context, 'Enter the topic name', success: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(appDataProvider.notifier)
          .addImportantTopic(widget.courseId, _name.text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.show(context, 'Could not add topic. Check your connection.',
          success: false);
      return;
    }
    Haptics.success();
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnack.show(context, 'Topic added — thanks for helping!');
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
            Text('Add an important topic',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Add a topic that tends to come in exams. It starts marked as '
              '“likely” so other students see it right away.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Topic name (e.g. Dynamic Programming)',
                prefixIcon: Icon(LucideIcons.trendingUp, size: 20),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add topic',
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
