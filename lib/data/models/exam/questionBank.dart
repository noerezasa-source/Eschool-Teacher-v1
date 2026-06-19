class BankSoal {
  final int id;
  final int teacherId;
  final int subjectId;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int soalCount;

  BankSoal({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.soalCount,
  });

  BankSoal copyWith({
    int? id,
    int? teacherId,
    int? subjectId,
    String? name,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? soalCount,
  }) {
    return BankSoal(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      soalCount: soalCount ?? this.soalCount,
    );
  }

  factory BankSoal.fromJson(Map<String, dynamic> json) {
    // Robust parsing for soalCount to handle types and different keys
    int parseCount(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    // Try multiple possible keys for the question count
    int count = parseCount(json['soal_count']);
    if (count == 0) {
      count = parseCount(json['questions_count'] ?? 
                         json['total_questions'] ?? 
                         json['soals_count'] ?? 0);
    }
    
    // Fallback if the API includes questions list in the bank object
    if (count == 0 && json['soal'] is List) {
      count = (json['soal'] as List).length;
    }

    return BankSoal(
      id: json['id'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      soalCount: count,
    );
  }
}
