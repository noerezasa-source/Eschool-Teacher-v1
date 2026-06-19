import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/subject.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class AssignmentSubmission {
  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.sessionYearId,
    required this.feedback,
    required this.points,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.assignment,
    required this.student,
    required this.file,
    required this.content,
  });
  late final int id;
  late final int assignmentId;
  late final int studentId;
  late final int sessionYearId;
  late final String feedback;
  late final int points;
  late final int status;
  late final String createdAt;
  late final String updatedAt;
  late final ReviewAssignment assignment;
  late final ReviewAssignmentStudent student;
  late final List<StudyMaterial> file;
  late final String content;

  AssignmentSubmissionStatus get submissionStatus =>
      Utils.getAssignmentSubmissionStatusFromTypeId(typeId: status);

  AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    assignmentId = json['assignment_id'] ?? 0;
    studentId = json['student_id'] ?? 0;
    sessionYearId = json['session_year_id'] ?? 0;
    feedback = json['feedback'] ?? "";
    points = json['points'] ?? 0;
    status = json['status'] ?? 0;
    createdAt = json['created_at'] ?? "";
    updatedAt = json['updated_at'] ?? "";
    assignment = ReviewAssignment.fromJson(json['assignment'] ?? {});
    student = ReviewAssignmentStudent.fromJson(json['student'] ?? {});
    file = List.from(json['file'] ?? [])
        .map((e) => StudyMaterial.fromJson(e))
        .toList();
    content = json['content'] ?? "";
  }

  AssignmentSubmission copyWith({
    int? status,
    String? feedback,
    int? points,
    int? id,
  }) {
    return AssignmentSubmission(
        id: id ?? this.id,
        assignmentId: assignmentId,
        studentId: studentId,
        sessionYearId: sessionYearId,
        feedback: feedback ?? this.feedback,
        points: points ?? this.points,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        assignment: assignment,
        student: student,
        file: file,
        content: content);
  }
}

class ReviewAssignment {
  ReviewAssignment({
    required this.id,
    required this.classSectionId,
    required this.classSubjectId,
    required this.name,
    required this.description,
    required this.dueDate,
    required this.points,
    required this.resubmission,
    required this.extraDaysForResubmission,
    required this.sessionYearId,
    required this.createdAt,
    required this.subject,
  });
  late final int id;
  late final int classSectionId;
  late final int classSubjectId;
  late final String name;
  late final String description;
  late final String dueDate;
  late final int points;
  late final int resubmission;
  late final int extraDaysForResubmission;
  late final int sessionYearId;
  late final String createdAt;
  late final String text;
  late final Subject subject;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  ReviewAssignment.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    classSectionId = _toInt(json['class_section_id']);
    classSubjectId = _toInt(json['class_subject_id']);
    name = json['name'] ?? "";
    description = json['description'] ?? "";
    dueDate = json['due_date'] ?? "";
    points = _toInt(json['points']);
    resubmission = _toInt(json['resubmission']);
    extraDaysForResubmission = _toInt(json['extra_days_for_resubmission']);
    sessionYearId = _toInt(json['session_year_id']);
    createdAt = json['created_at'] ?? "";
    text = json['text']?.toString() ?? "0";
    subject = Subject.fromJson(json['class_subject']?['subject'] ?? {});
  }
}

class ReviewAssignmentStudent {
  ReviewAssignmentStudent({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.image,
  });
  late final int id;
  late final int userId;
  late final String firstName;
  late final String lastName;
  late final String image;

  String get fullName => "$firstName $lastName";

  ReviewAssignmentStudent.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    userId = json['user_id'] ?? 0;
    firstName = json['first_name'] ?? "";
    lastName = json['last_name'] ?? "";
    image = json['image'] ?? "";
  }
}

///[Assignment submission status converter for application]
enum AssignmentSubmissionFilters {
  all,
  submitted,
  resubmitted,
  accepted,
  rejected,
}

class AssignmentSubmissionStatus {
  //0 - Submitted
  //1 - Accepted
  //2 - Rejected
  //3 - Resubmitted
  final int typeStatusId;
  final String titleKey;
  final AssignmentSubmissionFilters filter;
  final Color color;

  AssignmentSubmissionStatus(
      {required this.typeStatusId,
      required this.titleKey,
      required this.filter,
      required this.color});

  @override
  String toString() {
    return titleKey;
  }

  @override
  bool operator ==(covariant AssignmentSubmissionStatus other) {
    return other.typeStatusId == typeStatusId;
  }

  @override
  int get hashCode {
    return typeStatusId.hashCode;
  }
}
