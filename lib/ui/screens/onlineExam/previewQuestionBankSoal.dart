// Dart imports
import 'dart:ui';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports
import 'package:animate_do/animate_do.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

// App imports
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/data/models/exam/BankOnlineQuestion.dart';
import 'package:eschool_saas_staff/data/repositories/exam/onlineExamRepository.dart';
import '../../../cubits/teacherAcademics/assignment/questionBankCubit.dart';
import '../../widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/painters/previewQuestionPainters.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/widgets/questionDetailWidget.dart';
import 'package:eschool_saas_staff/utils/system/questionUtils.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart' as q;

class PreviewQuestionBankSoal extends StatefulWidget {
  final BankSoalQuestion bank;
  final int examId;
  final int classSectionId;
  final int classSubjectId;

  const PreviewQuestionBankSoal({
    required this.bank,
    required this.examId,
    required this.classSectionId,
    required this.classSubjectId,
    super.key,
  });

  @override
  State<PreviewQuestionBankSoal> createState() =>
      _PreviewQuestionBankSoalState();
}

class _PreviewQuestionBankSoalState extends State<PreviewQuestionBankSoal>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allQuestions = [];
  List<dynamic> _filteredQuestions = [];
  final Map<int, Set<int>> _selectedQuestions = {};
  late AnimationController _selectionController;

  final bool _hasShownTooltip = false;
  // New properties for swipeable cards
  final Map<int, PageController> _pageControllers = {};
  final Map<int, int> _activeVersionIndices = {};
  bool _hasShownSwipeGuide = false;
  // Define the border radius for cards
  final BorderRadius cardBorderRadius = BorderRadius.circular(28);

  // New color variables
  static const Color _primaryColor = Color(0xFF7A1E23); // Softer deep maroon

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);

    _fetchQuestions();
    _searchController.addListener(_filterQuestionsLocally);
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _searchController.removeListener(_filterQuestionsLocally);
    _searchController.dispose();

    // Dispose all page controllers
    _pageControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  // Create controller for a question
  PageController _getPageController(int questionId) {
    if (!_pageControllers.containsKey(questionId)) {
      _pageControllers[questionId] = PageController(
        viewportFraction: 0.99, // Slightly less than 1.0 for peeking effect
        initialPage: 0,
      );
    }
    return _pageControllers[questionId]!;
  }

  // Update the active version index
  void _setActiveVersionIndex(int questionId, int versionIndex) {
    setState(() {
      _activeVersionIndices[questionId] = versionIndex;
    });
  }

  // Get the active version index, default to 0 (latest version)
  int _getActiveVersionIndex(int questionId) {
    return _activeVersionIndices[questionId] ?? 0;
  }

  Future<void> _fetchQuestions() async {
    try {
      await context.read<QuestionBankCubit>().fetchBankQuestions(
            examId: widget.examId,
            bankId: widget.bank.id,
            subjectId: widget.bank.subjectId,
          );
      _filterQuestionsLocally();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      debugPrint('Technical error: $e');
      // The error will be handled by the BlocConsumer in the UI
    }
  }

  void _filterQuestionsLocally() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = List.from(_allQuestions);
      } else {
        _filteredQuestions = _allQuestions.where((question) {
          try {
            // Safely access question text with null checks and type validation
            if (question?.versions == null ||
                question.versions.isEmpty ||
                question.versions is! List) {
              return false;
            }

            final latestVersion =
                question.versions[question.versions.length - 1];
            if (latestVersion == null || latestVersion.question == null) {
              return false;
            }

            final questionText =
                QuestionUtils.parseHtmlString(latestVersion.question.toString())
                    .toLowerCase();
            return questionText.contains(query);
          } catch (e) {
            debugPrint('Error filtering question: $e');
            return false;
          }
        }).toList();
      }
    });
  }

  void _toggleQuestionSelection(int index) {
    final question = _filteredQuestions[index];
    final questionId = question.id;
    final activeVersionIndex = _getActiveVersionIndex(questionId);

    // Check if this specific version is already selected
    bool isVersionSelected = false;
    if (_selectedQuestions.containsKey(index)) {
      isVersionSelected =
          _selectedQuestions[index]!.contains(activeVersionIndex);
    }

    if (isVersionSelected) {
      // Unselect this version
      setState(() {
        _selectedQuestions[index]!.remove(activeVersionIndex);
        if (_selectedQuestions[index]!.isEmpty) {
          _selectedQuestions.remove(index);
        }
      });
    } else {
      // Select this version
      setState(() {
        if (!_selectedQuestions.containsKey(index)) {
          _selectedQuestions[index] = {};
        }
        _selectedQuestions[index]!.add(activeVersionIndex);
      });
    }
  }

  bool _isVersionDisabled(dynamic question, int versionIndex) {
    // If the question doesn't have a versions array or the index is out of bounds, return false
    if (question.versions == null || versionIndex >= question.versions.length) {
      return false;
    }

    // Calculate the actual version index in the versions array (since it's reversed in the UI)
    final displayIndex = question.versions.length - 1 - versionIndex;
    final version = question.versions[displayIndex];

    // Check if this specific version is already added to the exam
    return version.selected == true;
  }

  void _showHelpInfo() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF7A1E23),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bantuan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Ketuk soal untuk memilihnya. Soal yang sudah dipilih akan ditandai dengan centang.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Soal yang sudah ditambahkan ke ujian akan muncul dalam keadaan terkunci.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A1E23).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7A1E23).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF7A1E23),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tekan lama card soal untuk melihat detail lengkap soal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A1E23),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1E23),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan extendBodyBehindAppBar agar background mentok ke status bar
      extendBodyBehindAppBar: true,
      appBar: CustomModernAppBar(
        title: widget.bank.name,
        icon: Icons.question_answer,
        fabAnimationController: _selectionController,
        primaryColor: const Color(
            0xFF7A1E23), // Using the maroon color from state variables
        lightColor: const Color(0xFFB84D4D),
        onBackPressed: () => Navigator.of(context).pop(),
        showHelperButton: true,
        onHelperPressed: _showHelpInfo,
      ),
      body: Container(
        // Background putih penuh sampai status bar
        color: Colors.grey[50],
        child: Column(
          children: [
            // Padding for AppBar height
            SizedBox(height: 80 + MediaQuery.of(context).padding.top),

            // Content area
            Expanded(
              child: BlocConsumer<QuestionBankCubit, QuestionBankState>(
                listener: (context, state) {
                  if (state is BankQuestionsFetchSuccess) {
                    try {
                      setState(() {
                        _allQuestions = List.from(state.questions);
                        _filterQuestionsLocally();
                      });
                    } catch (e) {
                      debugPrint('Error processing questions: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error loading questions: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                builder: (context, state) {
                  if (state is QuestionBankLoading && _allQuestions.isEmpty) {
                    return const SkeletonPreviewQuestionBankSoal(itemCount: 6);
                  } else if (state is QuestionBankError &&
                      _allQuestions.isEmpty) {
                    return CustomErrorWidget(
                      message: ErrorMessageUtils.getReadableErrorMessage(
                          state.message),
                      onRetry: _fetchQuestions,
                      primaryColor: _primaryColor,
                    );
                  }
                  return RefreshIndicator(
                      onRefresh: _fetchQuestions, child: _buildContent());
                },
              ),
            ),
          ],
        ),
      ),
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
                              blurRadius: 10)
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedQuestions.clear()),
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.clear, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text('Batal',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold)),
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
                            colors: [Colors.blue[600]!, Colors.blue[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue[600]!.withValues(alpha: 0.3),
                              blurRadius: 10)
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saveSelectedQuestions,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.save, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Simpan ${_selectedQuestions.length} Soal',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
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

  Widget _buildContent() {
    // Check if any questions have multiple versions
    bool hasMultipleVersions =
        _filteredQuestions.any((q) => q.versions.length > 1);

    return Column(
      children: [
        if (!_hasShownTooltip)
          if (_allQuestions.length > 5)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari soal...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
        Expanded(
          child: _filteredQuestions.isEmpty
              ? _buildNoDataWidget()
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _filteredQuestions[index];
                        return FadeInUp(
                          duration: Duration(milliseconds: 400 + (index * 50)),
                          child: _buildSwipeableQuestionCard(question, index),
                        );
                      },
                    ),
                    if (hasMultipleVersions && !_hasShownSwipeGuide)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: FadeIn(
                          duration: const Duration(seconds: 1),
                          child: Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 32.0),
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
                                  const Icon(Icons.swipe,
                                      color: Color(0xFF8B0000)),
                                  const SizedBox(width: 12.0),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Geser kanan atau kiri untuk melihat versi soal lain',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          'Beberapa soal memiliki beberapa versi yang dapat dilihat',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16.0),
                                    onPressed: () {
                                      setState(() {
                                        _hasShownSwipeGuide = true;
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

  Widget _buildNoDataWidget() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ada soal yang cocok'
                  : 'Belum ada soal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Coba gunakan kata kunci lain'
                  : 'Bank soal ini belum memiliki soal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableQuestionCard(dynamic question, int index) {
    final int questionVersionsCount = question.versions.length;
    final PageController pageController = _getPageController(question.id);
    final int activeVersionIndex = _getActiveVersionIndex(question.id);

    // Check if this specific version is selected
    bool isSelected = _selectedQuestions.containsKey(index) &&
        _selectedQuestions[index]!.contains(activeVersionIndex);

    // Check if this specific version is disabled
    bool isVersionDisabled = _isVersionDisabled(question, activeVersionIndex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Stack(
        children: [
          // Main card dan PageView
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.transparent,
                  width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.3)
                      : QuestionUtils.getTypeColor(
                              question.versions[activeVersionIndex].type)
                          .withValues(alpha: 0.12),
                  blurRadius: isSelected ? 15 : 40,
                  offset: const Offset(0, 15),
                  spreadRadius: isSelected ? 2 : 0,
                ),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.30,
                  maxHeight: MediaQuery.of(context).size.height * 0.60,
                ),
                child: PageView.builder(
                  controller: pageController,
                  physics: const BouncingScrollPhysics(),
                  pageSnapping: true,
                  allowImplicitScrolling: true,
                  padEnds: false,
                  itemCount: questionVersionsCount,
                  onPageChanged: (index) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        HapticFeedback.lightImpact();
                        _setActiveVersionIndex(question.id, index);
                      }
                    });
                  },
                  itemBuilder: (context, vIndex) {
                    final displayIndex = questionVersionsCount - 1 - vIndex;
                    final version = question.versions[displayIndex];

                    // Cek apakah versi ini terkunci
                    final bool thisVersionDisabled =
                        _isVersionDisabled(question, vIndex);

                    return AnimatedBuilder(
                      animation: pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (pageController.position.hasContentDimensions) {
                          value = pageController.page! - vIndex;
                          value = (1 - (value.abs() * 0.3)).clamp(0.85, 1.0);
                        }

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(
                                value - 1 != 0.0 ? (value - 1) * 0.5 : 0.0),
                          alignment: value < 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Transform.scale(
                            scale: value,
                            child: Stack(
                              children: [
                                // Konten soal
                                _buildQuestionVersionContent(version, question,
                                    vIndex, questionVersionsCount),

                                // Overlay langsung dalam PageView item dengan border radius
                                if (thisVersionDisabled)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.5),
                                        // Gradient overlay untuk efek visual yang lebih menarik
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.grey.withValues(alpha: 0.6),
                                            Colors.grey.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 1.5, sigmaY: 1.5),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                ),
                                                child: const Icon(Icons.lock,
                                                    color: Colors.white,
                                                    size: 32),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Versi soal ini sudah ditambahkan',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
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
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Layer untuk menangkap tap (tidak mengganggu swipe)
          Positioned.fill(
            child: Stack(
              children: [
                // Layer transparan untuk mengambil gestur tap
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint(
                          'Tap detected on question $index, version $activeVersionIndex');
                      // Tambahkan umpan balik haptic untuk memastikan tap terdeteksi
                      HapticFeedback.mediumImpact();

                      if (isVersionDisabled) {
                        Get.snackbar(
                          'Versi Soal Sudah Ditambahkan',
                          'Versi soal ini sudah ada dalam ujian',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 8,
                          duration: const Duration(seconds: 2),
                        );
                      } else {
                        setState(() {
                          _toggleQuestionSelection(index);
                        });
                      }
                    },
                    onLongPress: () {
                      // Show detailed question information
                      HapticFeedback.heavyImpact();
                      _showQuestionDetail(question, activeVersionIndex);
                    },
                    // Gunakan translucent untuk memastikan tap ditangkap dengan baik
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
              ],
            ),
          ),

          // Indicator for selected version
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
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionVersionContent(
      dynamic version, dynamic question, int versionIndex, int totalVersions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section - using AspectRatio for consistent sizing
        AspectRatio(
          aspectRatio: 2,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    QuestionUtils.getTypeColor(version.type),
                    Color.lerp(QuestionUtils.getTypeColor(version.type),
                        Colors.black, 0.2)!,
                    QuestionUtils.getTypeColor(version.type)
                        .withValues(alpha: 0.85),
                  ],
                  stops: const [0.2, 0.6, 0.9],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Pattern background
                  CustomPaint(
                    painter: UltraModernPatternPainter(
                      primaryColor: Colors.white.withValues(alpha: 0.12),
                      secondaryColor: Colors.white.withValues(alpha: 0.06),
                    ),
                    size: Size.infinite,
                  ),

                  // Light effect
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
                            Colors.white.withValues(alpha: 0)
                          ],
                          stops: const [0.1, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge tipe soal
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
                            width: 1),
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
                            Colors.white.withValues(alpha: 0.1)
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            QuestionUtils.getTypeIcon(version.type),
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            QuestionUtils.getTypeName(version.type),
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
                  ), // Badge poin
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${question.defaultPoint} poin',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Badge versi
                  Positioned(
                    top: 58,
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
                            "Versi ${totalVersions - versionIndex}/$totalVersions",
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

                  // Judul soal
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
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 3,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          version.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
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
          ),
        ), // Content section with improved layout
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question content header
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
                          QuestionUtils.getTypeColor(version.type),
                          QuestionUtils.getTypeColor(version.type)
                              .withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: QuestionUtils.getTypeColor(version.type)
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
              ), // Question content
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
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
                  QuestionUtils.parseHtmlString(version.question),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.5,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ), // Options section
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
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
                    color: QuestionUtils.getTypeColor(version.type)
                        .withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Stacked circles with icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: QuestionUtils.getTypeColor(version.type)
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: QuestionUtils.getTypeColor(version.type)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: QuestionUtils.getTypeColor(version.type)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: QuestionUtils.getTypeColor(version.type),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: QuestionUtils.getTypeColor(version.type),
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 18),

                    // Options text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilihan Jawaban',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${version.options.length} Opsi',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Arrow indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: QuestionUtils.getTypeColor(version.type)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: QuestionUtils.getTypeColor(version.type),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ), // Version indicators - moved from Positioned widget to here
              if (totalVersions > 1)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalVersions, (index) {
                      // Change the active detection logic
                      final isActive = index == versionIndex;
                      return GestureDetector(
                        onTap: () {
                          _getPageController(question.id).animateToPage(
                            index, // Directly use index instead of inverting it
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: isActive ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? QuestionUtils.getTypeColor(version.type)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ), // Small spacer at the end
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSelectedQuestions() async {
    try {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.blue[50], shape: BoxShape.circle),
                  child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          strokeWidth: 3)),
                ),
                const SizedBox(height: 24),
                Text('Menyimpan Soal',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text('Mohon tunggu sebentar...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                    backgroundColor: Colors.blue[50],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[400]!)),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.5),
      );

      final repository = OnlineExamRepository();
      final existingQuestions =
          await repository.getOnlineExamQuestions(widget.examId);

      Map<String, Map<String, dynamic>> assignQuestions = {};
      for (var question in existingQuestions) {
        assignQuestions[question.id.toString()] = {
          'question_id': question.questionId,
          'marks': question.marks,
          'from_bank': false // Boolean value for JSON
        };
      }

      // Process all selected questions with their specific versions
      _selectedQuestions.forEach((questionIndex, selectedVersions) {
        final question = _filteredQuestions[questionIndex];

        // For each selected version of this question
        for (int versionIndex in selectedVersions) {
          // Convert from UI index to actual version index
          final displayIndex = question.versions.length - 1 - versionIndex;
          final version = question.versions[displayIndex];

          assignQuestions[version.id.toString()] = {
            'question_id': version.id,
            'marks': question.defaultPoint,
            'from_bank': true // Boolean value for JSON
          };
        }
      });

      await repository.storeOnlineExamQuestions(
        examId: widget.examId,
        classSectionId: widget.classSectionId,
        classSubjectId: widget.classSubjectId,
        assignQuestions: assignQuestions,
      );

      Get.back();

      await Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 60),
                const SizedBox(height: 20),
                const Text('Berhasil!',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Soal berhasil ditambahkan ke ujian',
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Routes.questionOnlineExam
                        .replaceAll(':id', widget.examId.toString()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: const Text('Lihat Daftar Soal',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal menyimpan soal: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5));
    }
  }

  // Show detailed question information in a modal dialog
  // ─── Show question detail dialog (delegates to QuestionDetailWidget) ──────

  /// Adapts a [BankOnlineQuestion] version to typed models so that
  /// [QuestionDetailWidget] can render it without any inline UI logic.
  void _showQuestionDetail(dynamic question, int activeVersionIndex) {
    final int displayIndex = question.versions.length - 1 - activeVersionIndex;
    final dynamic version = question.versions[displayIndex];

    // Adapt options to typed QuestionOption list
    final List<q.QuestionOption> typedOptions = (version.options as List)
        .map<q.QuestionOption>((opt) => q.QuestionOption(
              text: opt.text as String? ?? '',
              percentage: int.tryParse(opt.percentage.toString()) ?? 0,
              feedback: opt.feedback as String? ?? '',
            ))
        .toList();

    final q.QuestionVersion typedVersion = q.QuestionVersion(
      id: version.id as int? ?? 0,
      version: version.name?.toString() ?? '',
      question: version.question as String? ?? '',
      name: version.name as String? ?? '',
      note: '',
      defaultPoint: question.defaultPoint as int? ?? 1,
      type: version.type as String? ?? 'multiple_choice',
      options: typedOptions,
      orderType: 'numeric',
      image: version.image as String?,
      selected: version.selected as bool? ?? false,
    );

    final q.Question typedQuestion = q.Question(
      id: question.id as int? ?? 0,
      bankSoalId: 0,
      subjectId: 0,
      createdAt: '',
      updatedAt: '',
      bankSoal: q.BankSoalInfo(id: 0, name: ''),
      marks: question.defaultPoint as int? ?? 1,
      versions: [typedVersion],
      selected: false,
      defaultPoint: question.defaultPoint as int? ?? 1,
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
                color: QuestionUtils.getTypeColor(version.type as String? ?? '')
                    .withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: QuestionDetailWidget(
              question: typedQuestion,
              version: typedVersion,
              isLatestVersion: activeVersionIndex == 0,
            ),
          ),
        ),
      ),
    );
  }
}
