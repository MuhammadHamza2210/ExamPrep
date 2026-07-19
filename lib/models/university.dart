class University {
  final String id;
  final String name;
  final String shortName;
  final String city;

  /// Cities where this university has a campus. Falls back to [city].
  final List<String> campuses;

  const University({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
    this.campuses = const [],
  });

  factory University.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as String;
    final rawCampuses = json['campuses'] as List?;
    return University(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String? ?? json['name'] as String,
      city: city,
      campuses: rawCampuses == null
          ? [city]
          : rawCampuses.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'city': city,
        'campuses': campuses,
      };
}
