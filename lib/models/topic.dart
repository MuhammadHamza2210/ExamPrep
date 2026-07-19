/// A syllabus topic whose exam-appearance is crowd-sourced.
///
/// [timesAppeared] / [totalVotes] gives a raw frequency, but we also keep a
/// [weightedScore] that leans on recent exams (see AppData.markTopicAppeared).
class Topic {
  final String id;
  final String courseId;
  final String name;

  /// Number of exam instances where students said this topic appeared.
  final int timesAppeared;

  /// Total number of exam instances voted on.
  final int totalVotes;

  /// Weighted 0..1 score — recent votes count more. Falls back to the raw
  /// frequency when no weighting data exists.
  final double weightedScore;

  const Topic({
    required this.id,
    required this.courseId,
    required this.name,
    this.timesAppeared = 0,
    this.totalVotes = 0,
    double? weightedScore,
  }) : weightedScore = weightedScore ??
            (totalVotes == 0 ? 0 : timesAppeared / totalVotes);

  /// Raw frequency 0..1.
  double get frequency => totalVotes == 0 ? 0 : timesAppeared / totalVotes;

  /// Percentage 0..100 used for bars / labels.
  double get percent => weightedScore * 100;

  String get priorityLabel {
    if (totalVotes == 0) return 'No data yet';
    if (weightedScore >= 0.75) return 'Very likely';
    if (weightedScore >= 0.5) return 'Likely';
    if (weightedScore >= 0.25) return 'Possible';
    return 'Rare';
  }

  Topic copyWith({
    int? timesAppeared,
    int? totalVotes,
    double? weightedScore,
  }) =>
      Topic(
        id: id,
        courseId: courseId,
        name: name,
        timesAppeared: timesAppeared ?? this.timesAppeared,
        totalVotes: totalVotes ?? this.totalVotes,
        weightedScore: weightedScore ?? this.weightedScore,
      );

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        name: json['name'] as String,
        timesAppeared: json['timesAppeared'] as int? ?? 0,
        totalVotes: json['totalVotes'] as int? ?? 0,
        weightedScore: (json['weightedScore'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'name': name,
        'timesAppeared': timesAppeared,
        'totalVotes': totalVotes,
        'weightedScore': weightedScore,
      };
}
