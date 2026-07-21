import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../models/app_user.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../models/exam_type.dart';
import '../models/note.dart';
import '../models/study_plan.dart';
import '../models/topic.dart';

/// All network access to Supabase (auth + shared notes + crowd-sourced topics).
class SupabaseRepository {
  SupabaseClient get _c => Supabase.instance.client;

  String? get uid => _c.auth.currentUser?.id;
  bool get hasSession => _c.auth.currentSession != null;

  // ---- Auth ---------------------------------------------------------------
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String universityId,
    required String campus,
    required String degree,
    required int semester,
  }) async {
    final res = await _c.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) {
      throw 'Sign up failed. Check your email confirmation settings.';
    }
    await _c.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'university_id': universityId,
      'campus': campus,
      'degree': degree,
      'semester': semester,
    });
    return AppUser(
      id: user.id,
      name: name,
      email: email,
      universityId: universityId,
      campus: campus,
      degreeProgram: degree,
      semester: semester,
    );
  }

  Future<AppUser> signIn(String email, String password) async {
    final res =
        await _c.auth.signInWithPassword(email: email, password: password);
    final user = res.user!;
    final row =
        await _c.from('profiles').select().eq('id', user.id).maybeSingle();
    return _profileToUser(user.id, email, row);
  }

  Future<void> signOut() => _c.auth.signOut();

  /// The signed-in user's profile, or null if no session.
  Future<AppUser?> currentProfile() async {
    final user = _c.auth.currentUser;
    if (user == null) return null;
    final row =
        await _c.from('profiles').select().eq('id', user.id).maybeSingle();
    return _profileToUser(user.id, user.email ?? '', row);
  }

  Future<void> updateProfile(AppUser u) async {
    await _c.from('profiles').upsert({
      'id': u.id,
      'name': u.name,
      'university_id': u.universityId,
      'campus': u.campus,
      'degree': u.degreeProgram,
      'semester': u.semester,
    });
  }

  AppUser _profileToUser(String id, String email, Map<String, dynamic>? row) =>
      AppUser(
        id: id,
        name: (row?['name'] as String?) ?? '',
        email: email,
        universityId: (row?['university_id'] as String?) ?? '',
        campus: (row?['campus'] as String?) ?? '',
        degreeProgram: (row?['degree'] as String?) ?? '',
        semester: (row?['semester'] as int?) ?? 1,
      );

  // ---- Notes --------------------------------------------------------------
  Future<List<Note>> fetchNotes() async {
    final rows = await _c.from('notes').select().order('created_at');
    return (rows as List).map((r) => _rowToNote(r as Map<String, dynamic>)).toList();
  }

  Future<void> insertNote({
    required String courseId,
    required String uploaderName,
    required String title,
    required String chapter,
    required ExamType examType,
    required String textBody,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    var fileUrl = '';
    var fileExt = '';
    if (fileBytes != null && fileName != null && fileName.isNotEmpty) {
      final dot = fileName.lastIndexOf('.');
      fileExt = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      await _c.storage.from('notes').uploadBinary(path, fileBytes);
      fileUrl = _c.storage.from('notes').getPublicUrl(path);
    }
    await _c.from('notes').insert({
      'course_id': courseId,
      'uploader_id': uid,
      'uploader_name': uploaderName,
      'title': title,
      'chapter': chapter,
      'exam_type': examType.key,
      'file_url': fileUrl,
      'file_ext': fileExt,
      'text_body': textBody,
    });
  }

  /// One rating per user (upsert). A DB trigger keeps the note's aggregate.
  Future<void> rateNote(String noteId, int stars) => _c.from('note_ratings').upsert(
        {'note_id': noteId, 'user_id': uid, 'stars': stars},
        onConflict: 'note_id,user_id',
      );

  /// noteId -> the current user's own star rating.
  Future<Map<String, int>> fetchMyRatings() async {
    if (uid == null) return {};
    final rows =
        await _c.from('note_ratings').select('note_id,stars').eq('user_id', uid!);
    return {
      for (final r in (rows as List))
        r['note_id'] as String: r['stars'] as int
    };
  }

  Note _rowToNote(Map<String, dynamic> r) => Note(
        id: r['id'] as String,
        courseId: r['course_id'] as String,
        uploaderId: (r['uploader_id'] as String?) ?? '',
        uploaderName: (r['uploader_name'] as String?) ?? 'Student',
        title: r['title'] as String,
        chapter: (r['chapter'] as String?) ?? '',
        examType: ExamType.fromKey(r['exam_type'] as String?),
        filePath: (r['file_url'] as String?) ?? '',
        textBody: (r['text_body'] as String?) ?? '',
        ratingSum: ((r['rating_sum'] as num?) ?? 0).toDouble(),
        ratingCount: (r['rating_count'] as int?) ?? 0,
        uploadedAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  // ---- Topics -------------------------------------------------------------
  Future<List<Topic>> fetchTopics() async {
    final rows = await _c.from('topics').select().order('total_votes');
    return (rows as List)
        .map((r) => _rowToTopic(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertTopic(String courseId, String name) async {
    final row = await _c
        .from('topics')
        .insert({'course_id': courseId, 'name': name, 'created_by': uid})
        .select('id')
        .single();
    // The student flagging it counts as their first "appeared" vote.
    await voteTopic(row['id'] as String, true);
  }

  /// One vote per user (upsert). A DB trigger keeps the topic's aggregate.
  Future<void> voteTopic(String topicId, bool appeared) =>
      _c.from('topic_votes').upsert(
        {'topic_id': topicId, 'user_id': uid, 'appeared': appeared},
        onConflict: 'topic_id,user_id',
      );

  /// topicId -> whether the current user voted "appeared".
  Future<Map<String, bool>> fetchMyVotes() async {
    if (uid == null) return {};
    final rows = await _c
        .from('topic_votes')
        .select('topic_id,appeared')
        .eq('user_id', uid!);
    return {
      for (final r in (rows as List))
        r['topic_id'] as String: r['appeared'] as bool
    };
  }

  // ---- Shared custom courses & departments --------------------------------
  Future<List<Course>> fetchCustomCourses() async {
    final rows = await _c.from('custom_courses').select();
    return (rows as List)
        .map((r) => Course(
              id: r['id'] as String,
              departmentId: r['department_id'] as String,
              universityId: r['university_id'] as String,
              name: r['name'] as String,
              code: r['code'] as String,
              semester: r['semester'] as int,
              isCustom: true,
            ))
        .toList();
  }

  Future<void> insertCustomCourse(Course c) => _c.from('custom_courses').insert({
        'id': c.id,
        'department_id': c.departmentId,
        'university_id': c.universityId,
        'name': c.name,
        'code': c.code,
        'semester': c.semester,
        'created_by': uid,
      });

  Future<List<Department>> fetchCustomDepartments() async {
    final rows = await _c.from('custom_departments').select();
    return (rows as List)
        .map((r) => Department(
              id: r['id'] as String,
              universityId: r['university_id'] as String,
              name: r['name'] as String,
              program: r['program'] as String,
              campus: (r['campus'] as String?) ?? '',
              isCustom: true,
            ))
        .toList();
  }

  Future<void> insertCustomDepartment(Department d) =>
      _c.from('custom_departments').insert({
        'id': d.id,
        'university_id': d.universityId,
        'name': d.name,
        'program': d.program,
        'campus': d.campus,
        'created_by': uid,
      });

  // ---- Study plans (private per user) -------------------------------------
  Future<Map<String, StudyPlan>> fetchStudyPlans() async {
    if (uid == null) return {};
    final rows = await _c.from('study_plans').select().eq('user_id', uid!);
    final map = <String, StudyPlan>{};
    for (final r in (rows as List)) {
      final cid = r['course_id'] as String;
      map[cid] = StudyPlan(
        courseId: cid,
        examDate: DateTime.tryParse(r['exam_date'] as String? ?? '') ??
            DateTime.now(),
        checkedTopicIds:
            ((r['checked'] as List?) ?? const []).map((e) => e as String).toSet(),
      );
    }
    return map;
  }

  Future<void> upsertStudyPlan(StudyPlan p) => _c.from('study_plans').upsert({
        'user_id': uid,
        'course_id': p.courseId,
        'exam_date': p.examDate.toIso8601String().substring(0, 10),
        'checked': p.checkedTopicIds.toList(),
      });

  Future<void> deleteStudyPlan(String courseId) => _c
      .from('study_plans')
      .delete()
      .eq('user_id', uid!)
      .eq('course_id', courseId);

  Topic _rowToTopic(Map<String, dynamic> r) => Topic(
        id: r['id'] as String,
        courseId: r['course_id'] as String,
        name: r['name'] as String,
        timesAppeared: (r['times_appeared'] as int?) ?? 0,
        totalVotes: (r['total_votes'] as int?) ?? 0,
      );
}

final supabaseRepo = SupabaseRepository();
