class Department {
  final String id;
  final String universityId;
  final String name;

  /// Curriculum key (cs, bahria_cs, bahria_se, ee, bba, econ, math, custom, …)
  /// used to generate the semester-wise course list. See curriculum.dart.
  final String program;

  /// Campus this department belongs to. Empty means it's offered at every
  /// campus of the university.
  final String campus;

  /// True for departments a student added themselves.
  final bool isCustom;

  const Department({
    required this.id,
    required this.universityId,
    required this.name,
    required this.program,
    this.campus = '',
    this.isCustom = false,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id'] as String,
        universityId: json['universityId'] as String,
        name: json['name'] as String,
        program: json['program'] as String? ?? 'cs',
        campus: json['campus'] as String? ?? '',
        isCustom: json['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'universityId': universityId,
        'name': name,
        'program': program,
        'campus': campus,
        'isCustom': isCustom,
      };
}
