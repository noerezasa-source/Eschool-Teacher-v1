import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/questionOnlineExam/questionOnlineExamCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/questionOnlineExam.dart';
import 'package:eschool_saas_staff/data/models/exam/BankOnlineQuestion.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart' as q;
import 'package:eschool_saas_staff/ui/screens/onlineExam/widgets/questionDetailWidget.dart';
import 'package:eschool_saas_staff/utils/system/questionUtils.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/painters/bankQuestionPainters.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import '../../../app/routes.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class QuestionOnlineExamScreen extends StatefulWidget {
  final int examId;

  const QuestionOnlineExamScreen({
    super.key,
    required this.examId,
  });

  @override
  State<QuestionOnlineExamScreen> createState() =>
      _QuestionOnlineExamScreenState();
}

class _QuestionOnlineExamScreenState extends State<QuestionOnlineExamScreen>
    with TickerProviderStateMixin {
  int? selectedBankId;
  bool _hasShownTooltip = false;
  final Set<int> _selectedQuestions = {};
  late AnimationController _animationController;
  // Theme colors - Softer Maroon palette
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon

  @override
  void initState() {
    super.initState();
    context.read<QuestionOnlineExamCubit>().getQuestions(widget.examId);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleQuestionSelection(int index) {
    setState(() {
      if (_selectedQuestions.contains(index)) {
        _selectedQuestions.remove(index);
      } else {
        _selectedQuestions.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style to ensure status bar has proper contrast
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for light background
    ));

    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Set the scaffold background to white/light grey
      // Use extendBodyBehindAppBar to extend content behind the app bar
      extendBodyBehindAppBar: true,
      appBar: CustomModernAppBar(
        title: 'Daftar Soal',
        icon: Icons.question_answer,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showAddButton: true,
        onAddPressed: () => Get.toNamed(Routes.bankSoalSelection,
            parameters: {'examId': widget.examId.toString()}),
        showArchiveButton: false,
        showFilterButton: false,
      ),
      body: Column(
        children: [
          // Add padding for content below custom appbar when using extendBodyBehindAppBar
          const SizedBox(height: 90),

          // Main Content
          Expanded(
            child:
                BlocBuilder<QuestionOnlineExamCubit, QuestionOnlineExamState>(
              builder: (context, state) {
                // Keep the existing state handling code
                if (state is QuestionOnlineExamLoading) {
                  return _buildLoadingState();
                }

                if (state is QuestionOnlineExamFailure) {
                  return CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.message),
                    onRetry: () => context
                        .read<QuestionOnlineExamCubit>()
                        .getQuestions(widget.examId),
                    primaryColor: _primaryColor,
                  );
                }

                if (state is QuestionOnlineExamSuccess) {
                  if (state.questions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildQuestionsList(state.questions);
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      // Keep the existing floating action button
      floatingActionButton: _selectedQuestions.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SlideInLeft(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedQuestions.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Batal (${_selectedQuestions.length})',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SlideInRight(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red[400]!,
                            Colors.red[700]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red[400]!.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final currentState =
                                context.read<QuestionOnlineExamCubit>().state;
                            if (currentState is QuestionOnlineExamSuccess) {
                              _showDeleteSelectedConfirmation(
                                  context, currentState.questions);
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Hapus Soal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return const SkeletonQuestionSubjectScreen(
      itemCount: 6,
      showSearch: false,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada soal untuk ujian ini',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Pilih Bank Soal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _selectBankSoal,
          ).animate().scale(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List<QuestionOnlineExam> questions) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                // Ubah dari GridView ke ListView
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    child: _buildQuestionCard(questions[index], index),
                  );
                },
              ),

              // Selection guide tooltip - new style matching bankQuestionScreen.dart
              if (!_hasShownTooltip)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: FadeIn(
                    duration: const Duration(seconds: 1),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: _primaryColor),
                            const SizedBox(width: 12.0),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ketuk kartu soal untuk memilih',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Tekan lama untuk melihat detail soal',
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16.0),
                              onPressed: () {
                                setState(() {
                                  _hasShownTooltip = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuestionOnlineExam question, int index) {
    bool isSelected = _selectedQuestions.contains(index);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Stack(
        children: [
          // Main Card with enhanced shadow and animation
          GestureDetector(
            onTap: () => _toggleQuestionSelection(index),
            onLongPress: () {
              // Show detailed question information
              HapticFeedback.heavyImpact();
              _showQuestionDetail(question, index);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: QuestionUtils.getTypeColor(question.type).withValues(alpha: 0.12),
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
                    // Stunning 3D Header with Parallax Effect
                    Container(
                      height: 160, // Increased for more impact
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            QuestionUtils.getTypeColor(question.type),
                            Color.lerp(
                                QuestionUtils.getTypeColor(question.type),
                                Colors.black,
                                0.2)!,
                            QuestionUtils.getTypeColor(question.type)
                                .withValues(alpha: 0.85),
                          ],
                          stops: const [0.2, 0.6, 0.9],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Advanced geometric pattern effect
                          CustomPaint(
                            painter: UltraModernPatternPainter(
                              primaryColor:
                                  Colors.white.withValues(alpha: 0.12),
                              secondaryColor:
                                  Colors.white.withValues(alpha: 0.06),
                            ),
                          ),

                          // Radial glow effect (adds depth)
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

                          // Glass-effect Type Badge with ultra-modern styling
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
                                      // Outer glow
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      // Icon with glow effect
                                      Icon(
                                        QuestionUtils.getTypeIcon(question.type),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    QuestionUtils.getTypeName(question.type),
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
                          ), // Premium Points Badge with floating effect
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: QuestionUtils.getTypeColor(question.type)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 3D star effect
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Badge versi soal
                          Positioned(
                            top: 70,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Versi ${question.version}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Question Title with cinematic styling
                          Positioned(
                            bottom: 22,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Decorative element
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
                                  'Soal ${index + 1}',
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
                                        color: QuestionUtils.getTypeColor(question.type)
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

                    // Question Content with premium styling
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title with modern accent
                          Row(
                            children: [
                              // Modern vertical line with gradient and glow
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      QuestionUtils.getTypeColor(question.type),
                                      QuestionUtils.getTypeColor(question.type)
                                          .withValues(alpha: 0.6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: QuestionUtils.getTypeColor(question.type)
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

                          // Question content with enhanced styling
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
                              QuestionUtils.parseHtmlString(question.question),
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

                          // Options Information with stunning styling
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
                                color: QuestionUtils.getTypeColor(question.type)
                                    .withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Animated pulse container (simulated with Stack)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: QuestionUtils.getTypeColor(question.type)
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: QuestionUtils.getTypeColor(question.type)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: QuestionUtils.getTypeColor(question.type)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: QuestionUtils.getTypeColor(question.type)
                                              .withValues(alpha: 0.6),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: QuestionUtils.getTypeColor(question.type),
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
                                // Selection indicator instead of arrow
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.15)
                                        : QuestionUtils.getTypeColor(question.type)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check
                                        : Icons.check_circle_outline,
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : QuestionUtils.getTypeColor(question.type),
                                    size: 18,
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
          // Selection indicator overlay
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectBankSoal() async {
    final result = await Get.toNamed(
      '/bank-soal-selection',
      parameters: {'examId': widget.examId.toString()},
    );

    if (result != null && result is BankSoalQuestion) {
      if (!mounted) return;
      setState(() {
        selectedBankId = result.id;
      });
      // Load questions from selected bank
      context.read<QuestionOnlineExamCubit>().loadQuestionsFromBank(
            widget.examId,
            result.id,
          );
    }
  }

  void _showDeleteSelectedConfirmation(
      BuildContext context, List<QuestionOnlineExam> questions) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use dialogContext instead of context
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Text(
              'Apakah Anda yakin ingin menghapus ${_selectedQuestions.length} soal yang dipilih?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close confirmation dialog
                Navigator.pop(dialogContext);

                try {
                  // Show loading dialog
                  _showDeleteLoadingDialog(context);

                  // Delete questions
                  await context.read<QuestionOnlineExamCubit>().deleteQuestions(
                        widget.examId,
                        _selectedQuestions,
                        questions,
                      );

                  if (!context.mounted) return;

                  // Pop loading dialog
                  Navigator.pop(context);

                  // Clear selection
                  setState(() {
                    _selectedQuestions.clear();
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Soal berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  // Pop loading dialog if showing
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus soal: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        ).animate().scale(
              duration: 200.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }

  void _showDeleteLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassmorphicContainer(
            width: 300,
            height: 180,
            borderRadius: 20,
            blur: 5,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom animated loading indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                        strokeWidth: 3,
                      ),
                      const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 30,
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .shake(
                            duration: 1500.ms,
                            hz: 2,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Menghapus Soal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ).animate().scale(
              duration: 300.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  // Show detailed question information in a modal dialog
  // ─── Show question detail dialog (delegates to QuestionDetailWidget) ──────

  /// Adapts a flat [QuestionOnlineExam] to the typed [q.Question] /
  /// [q.QuestionVersion] models so that [QuestionDetailWidget] can render it.
  void _showQuestionDetail(QuestionOnlineExam question, int index) {
    // Build a minimal QuestionVersion from the flat QuestionOnlineExam model.
    final fakeOptions = question.options.map<q.QuestionOption>((opt) {
      final isMap = opt is Map;
      final text = isMap
          ? (opt['option_text'] ?? opt['text'] ?? opt['option'] ?? '').toString()
          : opt.toString();
      final isAnswer = isMap
          ? (opt['is_answer'] == 1 || opt['isCorrect'] == true)
          : false;
      return q.QuestionOption(
        text: text,
        percentage: isAnswer ? 100 : 0,
        feedback: '',
      );
    }).toList();

    final fakeVersion = q.QuestionVersion(
      id: question.id,
      version: question.version ?? '1',
      question: question.question,
      name: question.title ?? 'Soal ${index + 1}',
      note: '',
      defaultPoint: question.marks,
      type: question.type,
      options: fakeOptions,
      orderType: 'numeric',
      image: null,
      selected: false,
    );

    final fakeQuestion = q.Question(
      id: question.questionId,
      bankSoalId: 0,
      subjectId: 0,
      createdAt: '',
      updatedAt: '',
      bankSoal: q.BankSoalInfo(id: 0, name: ''),
      marks: question.marks,
      versions: [fakeVersion],
      selected: false,
      defaultPoint: question.marks,
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: QuestionUtils.getTypeColor(question.type)
                    .withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: QuestionDetailWidget(
              question: fakeQuestion,
              version: fakeVersion,
              isLatestVersion: false,
            ),
          ),
        ),
      ),
    );
  }

}
