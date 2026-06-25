import 'dart:convert';

import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' show parse;
import 'package:eschool_saas_staff/cubits/questionOnlineExam/questionOnlineExamCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/questionOnlineExam.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class OnlineExamResultQuestionsScreen extends StatefulWidget {
  final int examId;
  final String examName;

  const OnlineExamResultQuestionsScreen(
      {super.key, required this.examId, required this.examName});

  @override
  State<OnlineExamResultQuestionsScreen> createState() =>
      _OnlineExamResultQuestionsScreenState();
}

class UltraModernPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  UltraModernPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double spacing = 30;
    for (double i = -size.width; i < size.width * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    final secondPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double i = spacing; i < size.width; i += spacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        secondPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _OnlineExamResultQuestionsScreenState
    extends State<OnlineExamResultQuestionsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<QuestionOnlineExam> _filteredQuestions = [];
  bool _showSearch = false;

  late AnimationController _animationController;

  static Color get _primaryColor => AppColorPalette.primaryMaroon;
  static Color get _accentColor => AppColorPalette.secondaryMaroon;

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? htmlString;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return const Color.fromARGB(255, 5, 120, 214);
      case 'essay':
        return const Color.fromARGB(255, 19, 122, 22);
      case 'true_false':
        return const Color.fromARGB(255, 227, 136, 0);
      case 'short_answer':
        return Colors.purple;
      case 'numeric':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return Icons.radio_button_checked;
      case 'essay':
        return Icons.edit_note;
      case 'true_false':
        return Icons.check_circle;
      case 'short_answer':
        return Icons.short_text;
      case 'numeric':
        return Icons.numbers;
      default:
        return Icons.help;
    }
  }

  String _getTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return 'Pilihan Ganda';
      case 'essay':
        return 'Essay';
      case 'true_false':
        return 'Benar/Salah';
      case 'short_answer':
        return 'Jawaban Singkat';
      case 'numeric':
        return 'Numerik';
      default:
        return 'Lainnya';
    }
  }

  String _getQuestionTitle(QuestionOnlineExam question) {
    // First try to get the title
    if (question.title != null && question.title!.trim().isNotEmpty) {
      return question.title!;
    }

    // If no title, try to extract first part of question as title
    if (question.question.isNotEmpty) {
      String questionText = parseHtmlString(question.question);

      // Take first sentence or first 50 characters as title
      List<String> sentences = questionText.split(RegExp(r'[.!?]'));
      if (sentences.isNotEmpty && sentences[0].trim().isNotEmpty) {
        String firstSentence = sentences[0].trim();
        if (firstSentence.length > 50) {
          return '${firstSentence.substring(0, 47)}...';
        }
        return firstSentence;
      }

      // Fallback to first 50 characters
      if (questionText.length > 50) {
        return '${questionText.substring(0, 47)}...';
      }
      return questionText;
    }

    // Final fallback
    return 'Soal ${question.questionId}';
  }

  @override
  void initState() {
    super.initState();
    context.read<QuestionOnlineExamCubit>().getOnlineExamResultQuestions(
          examId: widget.examId,
          search: _searchController.text,
        );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: "Soal Ujian Online",
        icon: Icons.assessment,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showAddButton: false,
        showArchiveButton: false,
        showFilterButton: false,
        showHelperButton: false,
      ),
      body: BlocBuilder<QuestionOnlineExamCubit, QuestionOnlineExamState>(
        builder: (context, state) {
          if (state is QuestionOnlineExamLoading) {
            return _buildShimmerLoading();
          }
          if (state is QuestionOnlineExamSuccess) {
            return _buildContent(state.questions);
          }
          if (state is QuestionOnlineExamFailure) {
            return CustomErrorWidget(
              message: ErrorMessageUtils.getReadableErrorMessage(state.message),
              onRetry: () {
                context
                    .read<QuestionOnlineExamCubit>()
                    .getOnlineExamResultQuestions(
                      examId: widget.examId,
                      search: _searchController.text,
                    );
              },
              primaryColor: _primaryColor,
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildContent(List<QuestionOnlineExam> questions) {
    _showSearch = questions.length > 5;

    if (_filteredQuestions.isEmpty || _searchController.text.isEmpty) {
      _filteredQuestions = questions;
    }

    return Column(
      children: [
        if (_showSearch)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _filterQuestions(query, questions),
              decoration: InputDecoration(
                hintText: 'Cari soal...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        Expanded(
          child: _filteredQuestions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final question = _filteredQuestions[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 400 + (index * 50)),
                      child: _buildQuestionCard(question),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _filterQuestions(String query, List<QuestionOnlineExam> questions) {
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = questions;
      } else {
        _filteredQuestions = questions.where((question) {
          final title = _getQuestionTitle(question).toLowerCase();
          final questionText = question.question.toLowerCase();
          return title.contains(query.toLowerCase()) ||
              questionText.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildQuestionCard(QuestionOnlineExam question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.toNamed(
                "/OnlineExamResultAnswerScreen/${widget.examId}/${question.questionId}/${base64.encode(utf8.encode(widget.examName))}/${question.type}"),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _getTypeColor(question.type).withValues(alpha: 0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getTypeColor(question.type),
                            Color.lerp(_getTypeColor(question.type),
                                Colors.black, 0.2)!,
                            _getTypeColor(question.type)
                                .withValues(alpha: 0.85),
                          ],
                          stops: const [0.2, 0.6, 0.9],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: UltraModernPatternPainter(
                              primaryColor:
                                  Colors.white.withValues(alpha: 0.12),
                              secondaryColor:
                                  Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              height: 180,
                              width: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                  stops: const [0.1, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.4),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      Icon(
                                        _getTypeIcon(question.type),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _getTypeName(question.type),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: _getTypeColor(question.type)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 1),
                                    spreadRadius: -3,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.shade100,
                                        size: 20,
                                      ),
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.shade300,
                                        size: 17,
                                      ),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${question.marks} poin',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 22,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getQuestionTitle(question),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.4),
                                        offset: const Offset(0, 2),
                                        blurRadius: 5,
                                      ),
                                      Shadow(
                                        color: _getTypeColor(question.type)
                                            .withValues(alpha: 0.6),
                                        offset: const Offset(0, 1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _getTypeColor(question.type),
                                      _getTypeColor(question.type)
                                          .withValues(alpha: 0.6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getTypeColor(question.type)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Konten Pertanyaan",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              parseHtmlString(question.question),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.5,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: _getTypeColor(question.type)
                                    .withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(question.type)
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(question.type)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(question.type)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 1.5,
                                          color: _getTypeColor(question.type),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: _getTypeColor(question.type),
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 18),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilihan Jawaban',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${question.options.length} opsi tersedia',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(question.type)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: _getTypeColor(question.type),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.question_mark_rounded,
                size: 70, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada soal tersedia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada soal yang terdapat pada ujian ini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
              ),
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
