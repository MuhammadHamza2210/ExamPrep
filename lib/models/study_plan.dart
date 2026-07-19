/// A student's personal cram plan for one course's exam.
class StudyPlan {
  final String courseId;
  final DateTime examDate;

  /// Ids of topics the student has ticked off as studied.
  final Set<String> checkedTopicIds;

  const StudyPlan({
    required this.courseId,
    required this.examDate,
    this.checkedTopicIds = const {},
  });

  StudyPlan copyWith({DateTime? examDate, Set<String>? checkedTopicIds}) =>
      StudyPlan(
        courseId: courseId,
        examDate: examDate ?? this.examDate,
        checkedTopicIds: checkedTopicIds ?? this.checkedTopicIds,
      );

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        courseId: json['courseId'] as String,
        examDate: DateTime.tryParse(json['examDate'] as String? ?? '') ??
            DateTime.now(),
        checkedTopicIds:
            ((json['checked'] as List?) ?? const []).map((e) => e as String).toSet(),
      );

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'examDate': examDate.toIso8601String(),
        'checked': checkedTopicIds.toList(),
      };
}
