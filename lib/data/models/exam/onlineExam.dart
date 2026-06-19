class OnlineExam {
  final int id;
  final int classSectionId;
  final int classSubjectId;
  final int status;
  final String title;
  final String examKey;
  final int duration; // Add duration field
  final DateTime startDate;
  final DateTime endDate;
  final String subjectName;
  final String classSectionName;

  OnlineExam({
    required this.id,
    required this.classSectionId,
    required this.classSubjectId,
    required this.title,
    required this.examKey,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.subjectName,
    required this.classSectionName,
  });

  factory OnlineExam.fromJson(Map<String, dynamic> json) {
    // Handle nested class_section safely
    int classSectionId = 0;
    String classSectionName = '';
    if (json['class_section'] != null && json['class_section'] is Map) {
      classSectionId = json['class_section']['id'] ?? 0;
      classSectionName = json['class_section']['full_name'] ?? json['class_section']['name'] ?? '';
    } else if (json['class_section_id'] != null) {
      classSectionId = int.tryParse(json['class_section_id'].toString()) ?? 0;
      classSectionName = json['class_section_name']?.toString() ?? '';
    }

    // Handle nested class_subject safely
    int classSubjectId = 0;
    String subjectName = '';
    if (json['class_subject'] != null && json['class_subject'] is Map) {
      classSubjectId = json['class_subject']['id'] ?? 0;
      subjectName = json['class_subject']['subject']?['name'] ?? json['class_subject']['name'] ?? '';
    } else if (json['class_subject_id'] != null) {
      classSubjectId = int.tryParse(json['class_subject_id'].toString()) ?? 0;
      subjectName = json['subject_name']?.toString() ?? '';
    }

    // Safe date parsing
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null || dateStr.toString().isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return OnlineExam(
      id: json['id'] ?? 0,
      classSectionId: classSectionId,
      classSubjectId: classSubjectId,
      title: json['title'] ?? '',
      examKey: json['exam_key']?.toString() ?? '',
      duration: json['duration'] ?? 0,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      subjectName: subjectName,
      classSectionName: classSectionName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_section_id': classSectionId,
      'class_subject_id': classSubjectId,
      'title': title,
      'exam_key': examKey.toString(),
      'duration': duration,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  OnlineExam copyWith({
    int? id,
    int? classSectionId,
    int? classSubjectId,
    int? status,
    String? title,
    String? examKey,
    int? duration,
    DateTime? startDate,
    DateTime? endDate,
    String? subjectName,
    String? classSectionName,
  }) {
    return OnlineExam(
      id: id ?? this.id,
      classSectionId: classSectionId ?? this.classSectionId,
      classSubjectId: classSubjectId ?? this.classSubjectId,
      status: status ?? this.status,
      title: title ?? this.title,
      examKey: examKey ?? this.examKey,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      subjectName: subjectName ?? this.subjectName,
      classSectionName: classSectionName ?? this.classSectionName,
    );
  }
}

class Question {
  final int id;
  final int onlineExamId;
  final int questionId;
  final int marks;

  Question({
    required this.id,
    required this.onlineExamId,
    required this.questionId,
    required this.marks,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      onlineExamId: json['online_exam_id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      marks: json['marks'] ?? 0,
    );
  }
}

class ClassSection {
  final int id;
  final String name;
  final String fullName;

  ClassSection({
    required this.id,
    required this.name,
    required this.fullName,
  });

  factory ClassSection.fromJson(Map<String, dynamic> json) {
    return ClassSection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }
}
