
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/subject.dart';
import 'package:flutter/foundation.dart';

class Assignment {
  Assignment({
    required this.id,
    required this.classSectionId,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.dueDate,
    required this.startDate,
    required this.endDate,
    required this.points,
    required this.minPoints,
    required this.maxFile,
    required this.resubmission,
    required this.extraDaysForResubmission,
    required this.sessionYearId,
    required this.createdAt,
    required this.classSection,
    required this.studyMaterial,
    required this.subject,
    required this.text,
    required this.acceptedFile,
  });

  final int id;
  final int classSectionId;
  final int subjectId;
  final String name;
  final String description;
  final DateTime dueDate;
  final DateTime startDate;
  final DateTime endDate;
  final int points;
  final int minPoints;
  final int maxFile;
  final int resubmission;
  final int extraDaysForResubmission;
  final int sessionYearId;
  final String createdAt;
  final ClassSection classSection;
  final List<StudyMaterial> studyMaterial;
  final Subject subject;
  final String text; // Changed from bool to String to match API
  final List<String> acceptedFile;

  /// Safely convert a dynamic value to int (handles bool, int, String, null)
  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    debugPrint("DATA ABIS HIT");
    debugPrint(json.toString());
    return Assignment(
      id: _toInt(json['id']),
      classSectionId: _toInt(json['class_section_id']),
      subjectId: _toInt(json['subject_id']),
      name: json['name'] ?? "",
      description: json["instructions"] ?? "",
      dueDate: DateTime.parse(json['due_date'] ?? DateTime.now().toString()),
      startDate:
          DateTime.parse(json['start_date'] ?? DateTime.now().toString()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toString()),
      points: _toInt(json["points"]),
      minPoints: _toInt(json["min_points"]),
      maxFile: _toInt(json["max_file"]),
      resubmission: _toInt(json['resubmission']),
      extraDaysForResubmission: _toInt(json["extra_days_for_resubmission"]),
      sessionYearId: _toInt(json['session_year_id']),
      createdAt: json['created_at'] ?? "",
      classSection: ClassSection.fromJson(json['class_section'] ?? {}),
      studyMaterial: ((json['file'] ?? []) as List)
          .map((e) => StudyMaterial.fromJson(Map.from(e)))
          .toList(),
      subject: Subject.fromJson(json['subject'] ?? {}),
      text: json['text']?.toString() ?? "0",
      acceptedFile: List<String>.from(json['filetypes'] ?? []),
    );
  }
}
