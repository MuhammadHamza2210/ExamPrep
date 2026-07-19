import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/department.dart';
import '../models/exam_type.dart';
import '../models/note.dart';
import '../models/study_plan.dart';
import '../models/topic.dart';
import '../models/university.dart';
import 'curriculum.dart';
import 'local_storage.dart';
import 'seed_data.dart';
import 'supabase_repo.dart';

/// Set in main() via overrides once Hive + the seed asset are loaded.
final localStorageProvider = Provider<LocalStorage>(
  (ref) => throw UnimplementedError('localStorageProvider must be overridden'),
);

final appSeedProvider = Provider<AppSeed>(
  (ref) => throw UnimplementedError('appSeedProvider must be overridden'),
);

/// Immutable snapshot of everything browsable in the app.
class AppData {
  final List<University> universities;
  final List<Department> departments;
  final List<Course> courses;
  final List<Note> notes;
  final List<Topic> topics;
  final List<String> downloadedNoteIds;
  final Set<String> userNoteIds;
  final Map<String, StudyPlan> studyPlans;

  /// noteId -> this user's own rating; topicId -> this user's vote.
  final Map<String, int> myRatings;
  final Map<String, bool> myVotes;

  const AppData({
    required this.universities,
    required this.departments,
    required this.courses,
    required this.notes,
    required this.topics,
    required this.downloadedNoteIds,
    required this.userNoteIds,
    required this.studyPlans,
    required this.myRatings,
    required this.myVotes,
  });

  StudyPlan? planFor(String courseId) => studyPlans[courseId];

  int? myRatingFor(String noteId) => myRatings[noteId];
  bool? myVoteFor(String topicId) => myVotes[topicId];

  /// Active study plans, soonest exam first.
  List<StudyPlan> get upcomingPlans {
    final list = studyPlans.values.toList();
    list.sort((a, b) => a.examDate.compareTo(b.examDate));
    return list;
  }

  List<Note> get myUploads =>
      notes.where((n) => userNoteIds.contains(n.id)).toList();

  List<Note> get myDownloads =>
      notes.where((n) => downloadedNoteIds.contains(n.id)).toList();

  // ---- Queries ------------------------------------------------------------
  University? university(String id) =>
      universities.where((u) => u.id == id).firstOrNull;

  Course? course(String id) => courses.where((c) => c.id == id).firstOrNull;

  Department? department(String id) =>
      departments.where((d) => d.id == id).firstOrNull;

  List<Department> departmentsOf(String universityId) =>
      departments.where((d) => d.universityId == universityId).toList();

  /// Departments at a university available on a given campus. A department with
  /// an empty campus is shared across all campuses.
  List<Department> departmentsForCampus(String universityId, String campus) =>
      departments
          .where((d) =>
              d.universityId == universityId &&
              (d.campus.isEmpty || d.campus == campus))
          .toList();

  List<Course> coursesOf(String departmentId) =>
      courses.where((c) => c.departmentId == departmentId).toList();

  List<Course> coursesOfUniversity(String universityId) =>
      courses.where((c) => c.universityId == universityId).toList();

  /// Distinct semesters (1..8) that a department offers courses in.
  List<int> semestersOf(String departmentId) {
    final set = coursesOf(departmentId).map((c) => c.semester).toSet().toList()
      ..sort();
    return set;
  }

  /// Courses of a department in one semester — custom subjects listed last.
  List<Course> coursesOfSemester(String departmentId, int semester) {
    final list = courses
        .where((c) => c.departmentId == departmentId && c.semester == semester)
        .toList();
    list.sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? 1 : -1;
      return a.code.compareTo(b.code);
    });
    return list;
  }

  List<Note> notesOf(String courseId) {
    final list = notes.where((n) => n.courseId == courseId).toList();
    list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return list;
  }

  Note? note(String id) => notes.where((n) => n.id == id).firstOrNull;

  List<Topic> topicsOf(String courseId) {
    final list = topics.where((t) => t.courseId == courseId).toList();
    list.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));
    return list;
  }

  /// Highest-priority topics across the whole catalog (for the Home feed).
  List<Topic> get trendingTopics {
    final list = topics.where((t) => t.totalVotes > 0).toList();
    list.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));
    return list.take(6).toList();
  }
}

class AppDataNotifier extends Notifier<AppData> {
  late LocalStorage _storage;
  late AppSeed _seed;

  @override
  AppData build() {
    _storage = ref.watch(localStorageProvider);
    _seed = ref.watch(appSeedProvider);
    return _compose();
  }

  AppData _compose() {
    // Departments = shipped + user-added ones.
    final allDepartments = [..._seed.departments, ..._storage.customDepartments];

    // Courses = generated from each department's curriculum + user-added ones.
    final generated = <Course>[];
    for (final dept in allDepartments) {
      generated.addAll(generateCoursesForDepartment(dept));
    }
    final allCourses = [...generated, ..._storage.customCourses];

    // Notes & topics are shared content synced from Supabase, cached locally
    // for offline use. See sync().
    final myId = supabaseRepo.uid ?? '';
    final allNotes = _storage.cachedNotes;
    final userNoteIds = myId.isEmpty
        ? <String>{}
        : allNotes.where((n) => n.uploaderId == myId).map((n) => n.id).toSet();
    final allTopics = _storage.cachedTopics;

    return AppData(
      universities: _seed.universities,
      departments: allDepartments,
      courses: allCourses,
      notes: allNotes,
      topics: allTopics,
      downloadedNoteIds: _storage.downloads,
      userNoteIds: userNoteIds,
      studyPlans: _storage.studyPlans,
      myRatings: _storage.myRatings,
      myVotes: _storage.myVotes,
    );
  }

  // ---- Sync ---------------------------------------------------------------

  /// Pull shared notes + topics from Supabase into the local cache.
  Future<void> sync() async {
    if (!supabaseRepo.hasSession) return;
    try {
      final notes = await supabaseRepo.fetchNotes();
      final topics = await supabaseRepo.fetchTopics();
      final customCourses = await supabaseRepo.fetchCustomCourses();
      final customDepts = await supabaseRepo.fetchCustomDepartments();
      final myRatings = await supabaseRepo.fetchMyRatings();
      final myVotes = await supabaseRepo.fetchMyVotes();
      final plans = await supabaseRepo.fetchStudyPlans();
      await _storage.saveCachedNotes(notes);
      await _storage.saveCachedTopics(topics);
      await _storage.saveCustomCourses(customCourses);
      await _storage.saveCustomDepartments(customDepts);
      await _storage.saveMyRatings(myRatings);
      await _storage.saveMyVotes(myVotes);
      await _storage.saveStudyPlans(plans);
      state = _compose();
    } catch (_) {
      // Offline or transient error — keep showing the cached data.
    }
  }

  // ---- Mutations (shared content → Supabase) ------------------------------

  Future<void> addNote({
    required String courseId,
    required String uploaderName,
    required String title,
    required String chapter,
    required ExamType examType,
    required String textBody,
    String? localFilePath,
  }) async {
    await supabaseRepo.insertNote(
      courseId: courseId,
      uploaderName: uploaderName,
      title: title,
      chapter: chapter,
      examType: examType,
      textBody: textBody,
      localFilePath: localFilePath,
    );
    await sync();
  }

  /// Adds a student-created department/program to a university and returns it.
  /// If [program] has a matching curriculum, its courses are generated;
  /// otherwise ('custom') it starts empty for the student to fill in.
  Future<Department> addCustomDepartment({
    required String universityId,
    required String name,
    required String program,
    String campus = '',
  }) async {
    final dept = Department(
      id: 'customdept_${DateTime.now().microsecondsSinceEpoch}',
      universityId: universityId,
      name: name.trim(),
      program: program,
      campus: campus,
      isCustom: true,
    );
    await supabaseRepo.insertCustomDepartment(dept);
    await sync();
    return dept;
  }

  /// Adds a student-created subject to a department/semester and returns it.
  Future<Course> addCustomCourse({
    required String departmentId,
    required String universityId,
    required int semester,
    required String name,
    required String code,
  }) async {
    final course = Course(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      departmentId: departmentId,
      universityId: universityId,
      name: name.trim(),
      code: code.trim().isEmpty ? 'CUSTOM' : code.trim().toUpperCase(),
      semester: semester,
      isCustom: true,
    );
    await supabaseRepo.insertCustomCourse(course);
    await sync();
    return course;
  }

  Future<void> rateNote(String noteId, int stars) async {
    await supabaseRepo.rateNote(noteId, stars);
    await sync();
  }

  /// A student flags a topic as important for a course. It starts as
  /// "appeared once" so new students immediately see it as likely, and others
  /// can keep voting on it.
  Future<void> addImportantTopic(String courseId, String name) async {
    await supabaseRepo.insertTopic(courseId, name.trim());
    await sync();
  }

  Future<void> setStudyPlan(String courseId, DateTime examDate) async {
    final existing = _storage.studyPlans[courseId];
    final plan = existing == null
        ? StudyPlan(courseId: courseId, examDate: examDate)
        : existing.copyWith(examDate: examDate);
    await supabaseRepo.upsertStudyPlan(plan);
    await sync();
  }

  Future<void> deleteStudyPlan(String courseId) async {
    await supabaseRepo.deleteStudyPlan(courseId);
    await sync();
  }

  Future<void> toggleTopicStudied(String courseId, String topicId) async {
    final plan = _storage.studyPlans[courseId];
    if (plan == null) return;
    final checked = {...plan.checkedTopicIds};
    if (!checked.remove(topicId)) checked.add(topicId);
    await supabaseRepo.upsertStudyPlan(plan.copyWith(checkedTopicIds: checked));
    await sync();
  }

  /// Records one "this came in my exam" vote (appeared=true) or a "did not
  /// appear" vote (appeared=false). Both increment total exam instances.
  Future<void> markTopicAppeared(String topicId, {required bool appeared}) async {
    await supabaseRepo.voteTopic(topicId, appeared);
    await sync();
  }

  Future<void> markDownloaded(String noteId) async {
    final ids = _storage.downloads;
    if (!ids.contains(noteId)) {
      ids.add(noteId);
      await _storage.saveDownloads(ids);
      state = _compose();
    }
  }
}

final appDataProvider =
    NotifierProvider<AppDataNotifier, AppData>(AppDataNotifier.new);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
