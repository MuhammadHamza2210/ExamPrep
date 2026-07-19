import 'package:flutter/material.dart';

/// The kind of exam a note or topic vote relates to.
enum ExamType {
  quiz,
  midterm,
  finalExam;

  /// Human-friendly label shown in the UI.
  String get label => switch (this) {
        ExamType.quiz => 'Quiz',
        ExamType.midterm => 'Midterm',
        ExamType.finalExam => 'Final',
      };

  /// Accent colour used for chips / tags.
  Color get color => switch (this) {
        ExamType.quiz => const Color(0xFF3B82F6),
        ExamType.midterm => const Color(0xFFF59E0B),
        ExamType.finalExam => const Color(0xFFEF4444),
      };

  /// Stable string used for JSON storage.
  String get key => name;

  static ExamType fromKey(String? value) {
    return ExamType.values.firstWhere(
      (e) => e.key == value,
      orElse: () => ExamType.finalExam,
    );
  }
}
