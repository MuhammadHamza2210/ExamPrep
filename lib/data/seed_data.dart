import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/department.dart';
import '../models/note.dart';
import '../models/topic.dart';
import '../models/university.dart';

/// Immutable bundle of the shipped catalog + seed contributions.
///
/// Courses are NOT stored here — they are generated per department from the
/// semester-wise curricula (see curriculum.dart).
class AppSeed {
  final List<University> universities;
  final List<Department> departments;
  final List<Note> notes;
  final List<Topic> topics;

  const AppSeed({
    required this.universities,
    required this.departments,
    required this.notes,
    required this.topics,
  });

  static Future<AppSeed> load() async {
    final raw = await rootBundle.loadString('assets/data/seed.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
        (json[key] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();

    return AppSeed(
      universities: parse('universities', University.fromJson),
      departments: parse('departments', Department.fromJson),
      notes: parse('notes', Note.fromJson),
      topics: parse('topics', Topic.fromJson),
    );
  }
}
