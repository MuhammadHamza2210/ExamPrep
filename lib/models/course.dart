class Course {
  final String id;
  final String departmentId;
  final String universityId;
  final String name;
  final String code; // e.g. CS301
  final int semester; // 1..8
  final int creditHours;

  /// True for subjects a student added themselves (not in the shipped curriculum).
  final bool isCustom;

  const Course({
    required this.id,
    required this.departmentId,
    required this.universityId,
    required this.name,
    required this.code,
    required this.semester,
    this.creditHours = 3,
    this.isCustom = false,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        departmentId: json['departmentId'] as String,
        universityId: json['universityId'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        semester: json['semester'] as int? ?? 1,
        creditHours: json['creditHours'] as int? ?? 3,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'universityId': universityId,
        'name': name,
        'code': code,
        'semester': semester,
        'creditHours': creditHours,
        'isCustom': isCustom,
      };
}
