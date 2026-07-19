import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser user;
  const EditProfileSheet({super.key, required this.user});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _degree;
  late String _universityId;
  String? _campus;
  late int _semester;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _degree = TextEditingController(text: widget.user.degreeProgram);
    _universityId = widget.user.universityId;
    _campus = widget.user.campus.isEmpty ? null : widget.user.campus;
    _semester = widget.user.semester;
  }

  @override
  void dispose() {
    _name.dispose();
    _degree.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      AppSnack.show(context, 'Name cannot be empty', success: false);
      return;
    }
    if (_campus == null) {
      AppSnack.show(context, 'Please select your campus', success: false);
      return;
    }
    setState(() => _saving = true);
    final updated = widget.user.copyWith(
      name: _name.text.trim(),
      universityId: _universityId,
      campus: _campus,
      degreeProgram: _degree.text.trim(),
      semester: _semester,
    );
    await ref.read(authControllerProvider.notifier).updateProfile(updated);
    Haptics.success();
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnack.show(context, 'Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final universities = ref.watch(appDataProvider).universities;
    final selectedUni = universities.where((u) => u.id == _universityId);
    final campuses = selectedUni.isEmpty ? <String>[] : selectedUni.first.campuses;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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
              Text('Edit profile',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Full name',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _universityId,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'University',
                  prefixIcon: Icon(LucideIcons.building2, size: 20),
                ),
                items: universities
                    .map((u) => DropdownMenuItem(
                          value: u.id,
                          child:
                              Text(u.shortName, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _universityId = v ?? _universityId;
                  _campus = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _campus,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Campus',
                  prefixIcon: Icon(LucideIcons.mapPin, size: 20),
                ),
                items: campuses
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: campuses.isEmpty
                    ? null
                    : (v) => setState(() => _campus = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _degree,
                decoration: const InputDecoration(
                  hintText: 'Degree program (e.g. BS CS)',
                  prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _semester,
                decoration: const InputDecoration(
                  hintText: 'Semester',
                  prefixIcon: Icon(LucideIcons.calendar, size: 20),
                ),
                items: List.generate(8, (i) => i + 1)
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text('Semester $s')))
                    .toList(),
                onChanged: (v) => setState(() => _semester = v ?? _semester),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save changes',
                icon: LucideIcons.check,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
