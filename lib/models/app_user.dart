class AppUser {
  final String id;
  final String name;
  final String email;
  final String universityId;
  final String campus;
  final String degreeProgram;
  final int semester;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.universityId,
    required this.campus,
    required this.degreeProgram,
    required this.semester,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? universityId,
    String? campus,
    String? degreeProgram,
    int? semester,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        universityId: universityId ?? this.universityId,
        campus: campus ?? this.campus,
        degreeProgram: degreeProgram ?? this.degreeProgram,
        semester: semester ?? this.semester,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        universityId: json['universityId'] as String,
        campus: json['campus'] as String? ?? '',
        degreeProgram: json['degreeProgram'] as String,
        semester: json['semester'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'universityId': universityId,
        'campus': campus,
        'degreeProgram': degreeProgram,
        'semester': semester,
      };
}
