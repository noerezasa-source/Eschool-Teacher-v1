import 'dart:convert';

import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:animate_do/animate_do.dart';
import '../../../cubits/teacherAcademics/assignment/questionBankCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart' as q;
import 'package:eschool_saas_staff/data/models/exam/questionBank.dart';

import '../../../data/models/exam/subjectQuestion.dart';
import 'package:html/parser.dart' show parse;
import '../../../app/routes.dart';

import '../../../ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

// Light rays painter
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/painters/bankQuestionPainters.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/widgets/questionDetailWidget.dart';

class BankQuestionScreen extends StatefulWidget {
  final BankSoal bankSoal;
  final int subjectId;
  final SubjectQuestion subject;

  const BankQuestionScreen({
    super.key,
    required this.bankSoal,
    required this.subjectId,
    required this.subject,
  });

  @override
  State<BankQuestionScreen> createState() => _BankQuestionScreenState();
}

class _BankQuestionScreenState extends State<BankQuestionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<q.Question> _filteredQuestions = [];
  bool _showSearch = false;

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _floatingIconsController;
  late AnimationController _cardHoverController;
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late AnimationController _loadingController;
  late AnimationController _tabTransitionController;
  late AnimationController _searchExpandController;

  // Animations

  // Tambahkan variabel untuk menyimpan data gambar
  final Map<int, dynamic> _questionImages = {};

  // Add this map to track active version for each question
  final Map<int, int> _activeVersionIndices = {};

  // Track drag distance for hybrid gesture detection
  double _dragDistance = 0.0;

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

  // Tambahkan properti ini di class _BankQuestionScreenState
  bool _hasShownSwipeGuide = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();

    // Setup animation controllers
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    _floatingIconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _searchExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Setup animations

    // Set system UI style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _backgroundAnimationController.dispose();
    _waveAnimationController.dispose();
    _floatingIconsController.dispose();
    _cardHoverController.dispose();
    _breathingController.dispose();
    _rotationController.dispose();
    _loadingController.dispose();
    _tabTransitionController.dispose();
    _searchExpandController.dispose();
    super.dispose();
  }

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

  void _loadQuestions() {
    context.read<QuestionBankCubit>().fetchBankQuestions(
          subjectId: widget.subject.subject.id,
          bankId: widget.bankSoal.id,
        );
  }

  void _navigateToAddQuestion() async {
    final result = await Get.toNamed(
      Routes.addQuestionScreen,
      arguments: {
        'bankSoalId': widget.bankSoal.id,
        'subjectId': widget.subject.subject.id,
      },
    );

    if (result == true) {
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            Colors.white, // Change to white to extend all the way to status bar
        extendBodyBehindAppBar: true,
        appBar: CustomModernAppBar(
          title: "Soal Akademik",
          icon: Icons.question_answer_rounded,
          fabAnimationController: _breathingController,
          primaryColor: _primaryColor,
          lightColor: _accentColor,
          onBackPressed: () => Navigator.pop(context),
          showAddButton: true,
          onAddPressed: _navigateToAddQuestion,
        ),
        body: BlocListener<QuestionBankCubit, QuestionBankState>(
          listener: (context, state) {
            // When we receive a BankQuestionsFetchSuccess state, we update the filtered questions
            if (state is BankQuestionsFetchSuccess) {
              setState(() {
                // Reset filtered questions to show all questions when new data arrives
                _filteredQuestions = List.from(state.questions);
                // Clear search if there was one
                if (_searchController.text.isNotEmpty) {
                  _filterQuestions(_searchController.text, state.questions);
                }
              });
            }
          },
          child: Stack(
            children: [
              // Background gradient covering the whole screen
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFFFF0F0),
                    ],
                  ),
                ),
              ),
              // Content with parallax scroll effect
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Parallax effect removed since _dragPosition is no longer used
                  return false;
                },
                child: Column(
                  children: [
                    // Add padding to account for app bar
                    SizedBox(height: MediaQuery.of(context).padding.top + 80),

                    // Main content
                    Expanded(
                      child: BlocBuilder<QuestionBankCubit, QuestionBankState>(
                        builder: (context, state) {
                          if (state is QuestionBankLoading) {
                            return _buildShimmerLoading();
                          }
                          if (state is BankQuestionsFetchSuccess) {
                            return state.questions.isEmpty
                                ? _buildEmptyState()
                                : _buildContent(state.questions);
                          }
                          if (state is QuestionBankError) {
                            return Center(
                              child: ErrorContainer(
                                errorMessage:
                                    "Tidak dapat terhubung ke server, mohon periksa koneksi internet anda dan coba lagi",
                                onTapRetry: () {
                                  context
                                      .read<QuestionBankCubit>()
                                      .fetchBankQuestions(
                                        subjectId: widget.subject.subject.id,
                                        bankId: widget.bankSoal.id,
                                      );
                                },
                              ),
                            );
                          }
                          // Default case - return an empty container
                          return const SizedBox();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterQuestions(String query, List<q.Question> questions) {
    debugPrint(
        '_filterQuestions called with query: "$query", total questions: ${questions.length}');
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = List.from(questions);
        debugPrint(
            'Query empty, showing all ${_filteredQuestions.length} questions');
      } else {
        _filteredQuestions = questions.where((question) {
          final nameMatch = question.versions.last.name
              .toLowerCase()
              .contains(query.toLowerCase());
          final questionMatch = question.versions.last.question
              .toLowerCase()
              .contains(query.toLowerCase());

          final isMatch = nameMatch || questionMatch;

          return isMatch;
        }).toList();

        // Debug: Print hasil filter
        debugPrint(
            'Search query: "$query", Found: ${_filteredQuestions.length} results from ${questions.length} total questions');
      }
    });
  }

  // Modifikasi _buildContent untuk menampilkan panduan swipe saat pertama kali
  Widget _buildContent(List<q.Question> questions) {
    debugPrint(
        '_buildContent called with ${questions.length} questions, current searchText: "${_searchController.text}", current filteredQuestions: ${_filteredQuestions.length}');

    if (questions.isEmpty) {
      return _buildEmptyState();
    }

    _showSearch = questions
        .isNotEmpty; // Always show search if there are questions (for testing)

    // Update filtered questions only if search is not active
    // Hanya update jika tidak ada teks pencarian
    if (_searchController.text.isEmpty) {
      debugPrint('Search is empty, showing all ${questions.length} questions');
      _filteredQuestions = List.from(questions);
    } else {
      debugPrint(
          'Search active: "${_searchController.text}", keeping current filtered results: ${_filteredQuestions.length}');
    }
    // Jangan panggil _filterQuestions lagi di sini karena sudah dipanggil di onChanged

    // Show swipe guide tooltip if multiple versions and not shown before
    bool hasMultipleVersions = questions.any((q) => q.versions.length > 1);

    return Column(
      children: [
        // Search bar if needed
        if (_showSearch)
          AnimatedBuilder(
            animation: _searchExpandController,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, // Reduced horizontal padding
                  vertical: 8.0,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.95, // Increased width to 95% of screen
                  height: 52.0, // Slightly taller for better visibility
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: _searchController.text.isNotEmpty
                        ? Border.all(
                            color: _primaryColor.withValues(alpha: 0.3),
                            width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(
                            alpha:
                                _searchController.text.isNotEmpty ? 0.15 : 0.1),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Get current state questions untuk filter
                      final currentState =
                          context.read<QuestionBankCubit>().state;
                      if (currentState is BankQuestionsFetchSuccess) {
                        _filterQuestions(value, currentState.questions);
                      }
                      setState(() {}); // Force rebuild to update suffixIcon
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari soal...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: _primaryColor,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                // Get current state questions untuk reset filter
                                final currentState =
                                    context.read<QuestionBankCubit>().state;
                                if (currentState is BankQuestionsFetchSuccess) {
                                  _filterQuestions('', currentState.questions);
                                }
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 16.0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ), // Questions list
        Expanded(
          child: Stack(
            children: [
              // Debug: Print kondisi untuk debugging
              Builder(
                builder: (context) {
                  final hasSearchText = _searchController.text.isNotEmpty;
                  final hasNoResults = _filteredQuestions.isEmpty;

                  // Debug output
                  debugPrint(
                      'Debug - hasSearchText: $hasSearchText, hasNoResults: $hasNoResults, filteredCount: ${_filteredQuestions.length}');

                  // Tampilkan pesan "no search results" jika sedang search tapi tidak ada hasil
                  if (hasSearchText && hasNoResults) {
                    debugPrint('Showing no search results screen');
                    return _buildNoSearchResults();
                  }

                  // Tampilkan daftar soal jika ada hasil
                  debugPrint(
                      'Showing question list with ${_filteredQuestions.length} items');
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
                    itemCount: _filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _filteredQuestions[index];
                      final latestVersionIndex = question.versions.length - 1;
                      final latestVersion =
                          question.versions[latestVersionIndex];

                      return _buildQuestionCard(question, latestVersion);
                    },
                  );
                },
              ),

              // Swipe guide tooltip
              if (hasMultipleVersions && !_hasShownSwipeGuide)
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
                            Icon(Icons.swipe, color: _primaryColor),
                            const SizedBox(width: 12.0),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Geser Untuk Melihat Versi",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  const Text(
                                    "Geser kartu ke kiri/kanan untuk melihat versi soal sebelumnya",
                                    style: TextStyle(fontSize: 12.0),
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

  Widget _buildShimmerLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFFFF0F0), // Very light maroon tint instead of light blue
          ],
        ),
      ),
      child: const SkeletonPreviewQuestionBankSoal(
        itemCount: 6,
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
            'Belum ada soal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tambahkan soal baru untuk memulai',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return NoSearchResultsWidget(
      searchQuery: _searchController.text,
      onClearSearch: () {
        setState(() {
          _searchController.clear();
          // Get current questions from state and restore full list
          final currentState = context.read<QuestionBankCubit>().state;
          if (currentState is BankQuestionsFetchSuccess) {
            _filteredQuestions = List.from(currentState.questions);
          }
        });
      },
      primaryColor: _primaryColor,
      accentColor: _accentColor,
      title: 'Tidak Ada Hasil',
      description:
          'Tidak ditemukan soal yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
      clearButtonText: 'Hapus Pencarian',
      icon: Icons.search_off_rounded,
    );
  }

  Widget _buildQuestionCard(q.Question question, dynamic latestVersion) {
    final int questionVersionsCount = question.versions.length;
    final int activeIndex = _getActiveVersionIndex(question.id);

    // Calculate display index (0 = latest, 1 = older, etc.)
    // Ensure activeIndex is within bounds
    final int safeIndex = activeIndex.clamp(0, questionVersionsCount - 1);

    // Map UI index back to actual version list index
    // UI: 0 is latest, 1 is previous...
    // List: 0 is oldest, N-1 is latest
    final displayIndex = questionVersionsCount - 1 - safeIndex;
    final version = question.versions[displayIndex];

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          _dragDistance = 0.0;
        },
        onHorizontalDragUpdate: (details) {
          _dragDistance += details.delta.dx;
        },
        onHorizontalDragEnd: (details) {
          if (questionVersionsCount <= 1) return;

          final double velocity = details.primaryVelocity ?? 0.0;
          final double distance = _dragDistance;

          // Hybrid Detection:
          // 1. Fast Swipe (Velocity < -300)
          // 2. Slow Drag (Distance < -100) - moved significantly left
          if (velocity < -300 || distance < -100) {
            debugPrint("GESTURE DEBUG: Left Action (Next Version)");
            if (safeIndex < questionVersionsCount - 1) {
              HapticFeedback.lightImpact();
              _setActiveVersionIndex(question.id, safeIndex + 1);
            }
          }
          // 1. Fast Swipe (Velocity > 300)
          // 2. Slow Drag (Distance > 100) - moved significantly right
          else if (velocity > 300 || distance > 100) {
            if (safeIndex > 0) {
              HapticFeedback.lightImpact();
              _setActiveVersionIndex(question.id, safeIndex - 1);
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color:
                    _getTypeColor(latestVersion.type).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: SizedBox(
                // Use a composite key to GUARANTEE uniqueness even if version.id is null/duplicate
                key: ValueKey<String>("${question.id}_ver_$safeIndex"),
                width: double.infinity,
                // Important: No fixed height here!
                child: _buildVersionCardWithActionsImproved(
                    version, question, safeIndex, questionVersionsCount),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCardWithActionsImproved(q.QuestionVersion version,
      q.Question question, int versionIndex, int totalVersions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        _buildVersionCardHeader(version, question, versionIndex, totalVersions),

        // Content section
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question content
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
                          _getTypeColor(version.type),
                          _getTypeColor(version.type).withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor(version.type)
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

              const SizedBox(height: 16),
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
                  parseHtmlString(version.question),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.5,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                  ),
                  // Removed maxLines to allow full expansion
                ),
              ),

              const SizedBox(height: 18),

              // Pilihan Jawaban section
              Container(
                padding: const EdgeInsets.all(15),
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
                    color: _getTypeColor(version.type).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Animated pulse container
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getTypeColor(version.type)
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _getTypeColor(version.type)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getTypeColor(version.type)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getTypeColor(version.type),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: _getTypeColor(version.type),
                            size: 20,
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
                    // Arrow indicator with click functionality
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            _showDetailQuestionSheet(question, version),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getTypeColor(version.type)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _getTypeColor(version.type),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),

        // Action buttons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Show edit, delete, and detail buttons for latest version
                  if (versionIndex == 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit Button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _navigateToEditQuestion(question, version),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    _getTypeColor(version.type),
                                    Color.lerp(_getTypeColor(version.type),
                                        Colors.black, 0.15)!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getTypeColor(version.type)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Space between buttons

                        // Delete button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showDeleteQuestionConfirmation(question),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else // Detail Button for older versions
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            _showDetailQuestionSheet(question, version),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                _getTypeColor(version.type)
                                    .withValues(alpha: 0.8),
                                Color.lerp(_getTypeColor(version.type),
                                        Colors.black, 0.2)!
                                    .withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getTypeColor(version.type)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Version Indicators
              if (totalVersions > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalVersions, (index) {
                      final isActive = index == versionIndex;
                      return Container(
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _getTypeColor(version.type)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCardHeader(q.QuestionVersion version, q.Question question,
      int versionIndex, int totalVersions) {
    return AspectRatio(
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
                _getTypeColor(version.type),
                Color.lerp(_getTypeColor(version.type), Colors.black, 0.2)!,
                _getTypeColor(version.type).withValues(alpha: 0.85),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1),
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
                        _getTypeIcon(version.type),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getTypeName(version.type),
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

              // Badge poin
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${version.defaultPoint} poin',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ), // Badge versi
              Positioned(
                top: 60,
                right: 20,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  void _navigateToEditQuestion(
      q.Question question, q.QuestionVersion version) async {
    // Create a map with all the data needed by EditQuestionScreen
    Map<String, dynamic> questionData = {
      'idBankSoal': widget.bankSoal.id,
      'name': version.name,
      'typeOrder': 'numeric', // Default value since property doesn't exist
      'question': version.question,
      'default_point': version.defaultPoint,
      'note': version.note,
      'type': version.type,
      'image': version.image,
      'options': version.options
          .map((opt) => {
                'text': opt.text,
                'percentage': opt.percentage,
                'feedback': opt.feedback,
              })
          .toList(),
    };

    final result = await Get.toNamed(
      Routes.editQuestionScreen,
      arguments: {
        'questionData': questionData,
        'idList': {
          'bankSoalSoalId': question.id,
          'subjectId': widget.subject.subject.id,
        },
      },
    );

    if (result == true) {
      // Explicitly reload questions when we get true result
      _loadQuestions();
    }
  }

  void _showDeleteQuestionConfirmation(q.Question question) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 16),
              Text('Hapus Soal'),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus soal ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog first

                try {
                  await context.read<QuestionBankCubit>().deleteQuestion(
                        subjectId: widget.subject.subject.id,
                        banksoalId: widget.bankSoal.id,
                        banksoalSoalId: question.id,
                      );

                  if (!mounted) return;
                  // Remove question from local state
                  setState(() {
                    _filteredQuestions.removeWhere((q) => q.id == question.id);
                  });

                  // Show auto-dismissing success notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Soal berhasil dihapus!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.green.shade400,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Tidak dapat menghapus soal, mohon periksa koneksi internet anda dan coba lagi"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailQuestionSheet(
      q.Question question, q.QuestionVersion version) {
    // Cek apakah ini versi terbaru dari soal
    // Versi terakhir di array selalu merupakan versi terbaru
    final isLatestVersion = question.versions.last.id == version.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            color: Colors.white,
            child: QuestionDetailWidget(
              question: question,
              version: version,
              isLatestVersion: isLatestVersion,
              onEdit: () => _navigateToEditQuestion(question, version),
              imageWidgetBuilder: _questionImages.containsKey(question.id)
                  ? (_) => _buildImagePreview(_questionImages[question.id])
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // Add helper method to display image preview
  Widget _buildImagePreview(dynamic imageData) {
    if (imageData is Uint8List) {
      return Image.memory(
        imageData,
        fit: BoxFit.contain,
      );
    } else if (imageData is String) {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                "Gagal memuat gambar",
                style: TextStyle(color: Colors.grey),
              ),
            );
          },
        );
      } else {
        // Assume it's a base64 image
        try {
          final decodedImage = base64Decode(imageData);
          return Image.memory(
            decodedImage,
            fit: BoxFit.contain,
          );
        } catch (e) {
          return const Center(
            child: Text(
              "Format gambar tidak valid",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
      }
    } else {
      return const Center(
        child: Text(
          "Format gambar tidak didukung",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
  }
}
