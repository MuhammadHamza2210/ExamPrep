import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../models/note.dart';
import '../models/study_plan.dart';
import '../models/topic.dart';

/// Thin wrapper over a single Hive box. Complex values are stored as JSON
/// strings so we never fight Hive's dynamic typing.
class LocalStorage {
  static const _boxName = 'examprep_box';
  final Box _box;

  LocalStorage._(this._box);

  static Future<LocalStorage> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(_boxName);
    return LocalStorage._(box);
  }

  // ---- Onboarding ---------------------------------------------------------
  bool get onboardingSeen => _box.get('onboardingSeen', defaultValue: false) as bool;
  Future<void> setOnboardingSeen(bool v) => _box.put('onboardingSeen', v);

  // ---- Theme --------------------------------------------------------------
  String get themeMode => _box.get('themeMode', defaultValue: 'system') as String;
  Future<void> setThemeMode(String v) => _box.put('themeMode', v);

  // ---- Auth ---------------------------------------------------------------
  /// Registered users, keyed by lowercase email -> { password, user }.
  Map<String, dynamic> _registry() {
    final raw = _box.get('userRegistry') as String?;
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveRegistry(Map<String, dynamic> reg) =>
      _box.put('userRegistry', jsonEncode(reg));

  bool emailExists(String email) => _registry().containsKey(email.toLowerCase());

  Future<void> registerUser(AppUser user, String password) async {
    final reg = _registry();
    reg[user.email.toLowerCase()] = {
      'password': password,
      'user': user.toJson(),
    };
    await _saveRegistry(reg);
  }

  /// Returns the user if credentials match, else null.
  AppUser? verifyLogin(String email, String password) {
    final reg = _registry();
    final entry = reg[email.toLowerCase()] as Map<String, dynamic>?;
    if (entry == null) return null;
    if (entry['password'] != password) return null;
    return AppUser.fromJson(entry['user'] as Map<String, dynamic>);
  }

  AppUser? get currentUser {
    final raw = _box.get('currentUser') as String?;
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setCurrentUser(AppUser? user) async {
    if (user == null) {
      await _box.delete('currentUser');
    } else {
      await _box.put('currentUser', jsonEncode(user.toJson()));
      // keep registry copy fresh (e.g. after profile edits)
      final reg = _registry();
      final existing = reg[user.email.toLowerCase()] as Map<String, dynamic>?;
      if (existing != null) {
        existing['user'] = user.toJson();
        await _saveRegistry(reg);
      }
    }
  }

  // ---- User-uploaded notes ------------------------------------------------
  List<Note> get userNotes {
    final raw = _box.get('userNotes') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveUserNotes(List<Note> notes) =>
      _box.put('userNotes', jsonEncode(notes.map((e) => e.toJson()).toList()));

  // ---- User-added (custom) subjects ---------------------------------------
  List<Course> get customCourses {
    final raw = _box.get('customCourses') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCustomCourses(List<Course> courses) => _box.put(
      'customCourses', jsonEncode(courses.map((e) => e.toJson()).toList()));

  // ---- User-added (custom) departments ------------------------------------
  List<Department> get customDepartments {
    final raw = _box.get('customDepartments') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomDepartments(List<Department> departments) => _box.put(
      'customDepartments',
      jsonEncode(departments.map((e) => e.toJson()).toList()));

  // ---- Student-added important topics -------------------------------------
  List<Topic> get customTopics {
    final raw = _box.get('customTopics') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCustomTopics(List<Topic> topics) => _box.put(
      'customTopics', jsonEncode(topics.map((e) => e.toJson()).toList()));

  // ---- Offline cache of remote (Supabase) content -------------------------
  List<Note> get cachedNotes {
    final raw = _box.get('cachedNotes') as String?;
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCachedNotes(List<Note> notes) => _box.put(
      'cachedNotes', jsonEncode(notes.map((e) => e.toJson()).toList()));

  List<Topic> get cachedTopics {
    final raw = _box.get('cachedTopics') as String?;
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCachedTopics(List<Topic> topics) => _box.put(
      'cachedTopics', jsonEncode(topics.map((e) => e.toJson()).toList()));

  /// noteId -> this user's own star rating.
  Map<String, int> get myRatings {
    final raw = _box.get('myRatings') as String?;
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveMyRatings(Map<String, int> r) =>
      _box.put('myRatings', jsonEncode(r));

  /// topicId -> whether this user voted "appeared".
  Map<String, bool> get myVotes {
    final raw = _box.get('myVotes') as String?;
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> saveMyVotes(Map<String, bool> v) =>
      _box.put('myVotes', jsonEncode(v));

  // ---- Study plans (one per course, keyed by courseId) --------------------
  Map<String, StudyPlan> get studyPlans {
    final raw = _box.get('studyPlans') as String?;
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, StudyPlan.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveStudyPlans(Map<String, StudyPlan> plans) => _box.put(
      'studyPlans',
      jsonEncode(plans.map((k, v) => MapEntry(k, v.toJson()))));

  // ---- Rating deltas (noteId -> {sum, count}) -----------------------------
  Map<String, List<num>> get ratingDeltas {
    final raw = _box.get('ratingDeltas') as String?;
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as List).map((e) => e as num).toList()));
  }

  Future<void> saveRatingDeltas(Map<String, List<num>> deltas) =>
      _box.put('ratingDeltas', jsonEncode(deltas));

  // ---- Topic votes (topicId -> {appeared, total}) -------------------------
  Map<String, List<int>> get topicVotes {
    final raw = _box.get('topicVotes') as String?;
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as List).map((e) => e as int).toList()));
  }

  Future<void> saveTopicVotes(Map<String, List<int>> votes) =>
      _box.put('topicVotes', jsonEncode(votes));

  // ---- Downloads history --------------------------------------------------
  List<String> get downloads {
    final raw = _box.get('downloads') as String?;
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => e as String).toList();
  }

  Future<void> saveDownloads(List<String> ids) =>
      _box.put('downloads', jsonEncode(ids));
}
