import 'exam_type.dart';

/// A shared study resource. Content may be a picked file (PDF/image) and/or
/// plain text typed by the uploader.
class Note {
  final String id;
  final String courseId;
  final String uploaderId;
  final String uploaderName;
  final String title;
  final String chapter;
  final ExamType examType;

  /// Local file path (or future cloud URL). Empty for pure-text notes.
  final String filePath;

  /// Optional plain-text body.
  final String textBody;

  final double ratingSum;
  final int ratingCount;
  final DateTime uploadedAt;

  const Note({
    required this.id,
    required this.courseId,
    this.uploaderId = '',
    required this.uploaderName,
    required this.title,
    required this.chapter,
    required this.examType,
    this.filePath = '',
    this.textBody = '',
    this.ratingSum = 0,
    this.ratingCount = 0,
    required this.uploadedAt,
  });

  double get averageRating => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  bool get hasFile => filePath.isNotEmpty;

  String get fileExtension {
    if (!hasFile) return '';
    final dot = filePath.lastIndexOf('.');
    if (dot == -1) return '';
    return filePath.substring(dot + 1).toLowerCase();
  }

  bool get isImage => const {'png', 'jpg', 'jpeg', 'gif', 'webp'}.contains(fileExtension);
  bool get isPdf => fileExtension == 'pdf';

  Note copyWith({double? ratingSum, int? ratingCount}) => Note(
        id: id,
        courseId: courseId,
        uploaderId: uploaderId,
        uploaderName: uploaderName,
        title: title,
        chapter: chapter,
        examType: examType,
        filePath: filePath,
        textBody: textBody,
        ratingSum: ratingSum ?? this.ratingSum,
        ratingCount: ratingCount ?? this.ratingCount,
        uploadedAt: uploadedAt,
      );

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        uploaderId: json['uploaderId'] as String? ?? '',
        uploaderName: json['uploaderName'] as String,
        title: json['title'] as String,
        chapter: json['chapter'] as String? ?? '',
        examType: ExamType.fromKey(json['examType'] as String?),
        filePath: json['filePath'] as String? ?? '',
        textBody: json['textBody'] as String? ?? '',
        ratingSum: (json['ratingSum'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'title': title,
        'chapter': chapter,
        'examType': examType.key,
        'filePath': filePath,
        'textBody': textBody,
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
        'uploadedAt': uploadedAt.toIso8601String(),
      };
}
