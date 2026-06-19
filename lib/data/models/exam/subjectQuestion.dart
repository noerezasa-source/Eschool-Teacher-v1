import 'question.dart';
import 'package:flutter/foundation.dart';

class SubjectQuestion {
  final int? id;
  final int teacherId;
  final int subjectId;
  final String name;
  final int soalCount;
  final List<QuestionBank> banks;
  final int bankSoalCount;
  final String subjectWithName;
  final Subject subject;

  SubjectQuestion({
    this.id,
    required this.teacherId,
    required this.subjectId,
    required this.name,
    required this.soalCount,
    this.banks = const [],
    required this.bankSoalCount,
    required this.subjectWithName,
    required this.subject,
  });

  factory SubjectQuestion.fromJson(Map<String, dynamic> json) {
    try {
      final subject = json['subject'] ?? json; // Fallback to root json if no nested subject

      // Robust parsing helper
      int parseCount(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return SubjectQuestion(
        id: json['id'] ?? subject['id'] ?? json['subject_id'],
        teacherId: json['teacher_id'] ?? 0,
        subjectId: subject['id'] ?? json['subject_id'] ?? 0,
        name: subject['name'] ?? '',
        // Use soal_count as primary for total questions, fallback to bank_soal_count if needed
        soalCount: parseCount(json['soal_count'] ?? json['bank_soal_count'] ?? 0),
        banks: [],
        bankSoalCount: parseCount(json['bank_soal_count'] ?? 0),
        subjectWithName: json['subject_with_name'] ??
            "${subject['name']} (${subject['type'] ?? 'Theory'})",
        subject: Subject.fromJson(subject),
      );
    } catch (e) {
      debugPrint("Error parsing SubjectQuestion: ${json.toString()}");
      debugPrint("Error details: $e");
      rethrow;
    }
  }
}

class QuestionBank {
  final int? id;
  final String name;
  final int? subjectId;
  final List<Question> questions;

  QuestionBank({
    this.id,
    required this.name,
    this.subjectId,
    this.questions = const [],
  });

  factory QuestionBank.fromJson(Map<String, dynamic> json) {
    return QuestionBank(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      subjectId: json['subject_id'] as int?,
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList()
          : [],
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String type;
  final String nameWithType;

  Subject({
    required this.id,
    required this.name,
    required this.type,
    required this.nameWithType,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    try {
      return Subject(
        id: json['id'] ?? json['subject_id'] ?? 0,
        name: json['name'] ?? '',
        type: json['type'] ?? 'Theory',
        nameWithType: json['name_with_type'] ??
            "${json['name'] ?? ''} - ${json['type'] ?? 'Theory'}",
      );
    } catch (e) {
      debugPrint("Error parsing Subject: $json");
      debugPrint("Error details: $e");
      rethrow;
    }
  }
}
