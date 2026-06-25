import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

class OnlineExamResultAnswerScreen extends StatefulWidget {
  final int examId;
  final int questionId;
  final String examName;
  final String questionType;

  const OnlineExamResultAnswerScreen(
      {super.key,
      required this.examId,
      required this.questionId,
      required this.examName,
      required this.questionType});

  @override
  State<OnlineExamResultAnswerScreen> createState() =>
      _OnlineExamResultAnswerScreenState();
}

class _OnlineExamResultAnswerScreenState
    extends State<OnlineExamResultAnswerScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allAnswers = []; // Store all answers locally
  List<dynamic> _filteredAnswers = []; // Store filtered answers
  Map<String, TextEditingController> marksControllers = {};
  bool _isSearching = false;
  bool showSearchBar = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: "Hasil Ujian Online",
        icon: Icons.assignment_outlined,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _energyColor,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: _buildBody(),
    );
  }

  // Animation controller for the app bar
  late AnimationController _animationController;

  // Theme colors for the app bar
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _energyColor => AppColorPalette.lightMaroon; // Softer light maroon
  @override
  void initState() {
    super.initState();
    // Initial load of all answers
    context.read<OnlineExamCubit>().getOnlineExamResultAnswer(
        examId: widget.examId, questionId: widget.questionId, search: '');

    // Initialize animation controller for the app bar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Filter answers locally based on search text
  void _filterAnswers(String query) {
    setState(() {
      _isSearching = true;
      if (query.isEmpty) {
        _filteredAnswers = List.from(_allAnswers);
      } else {
        _filteredAnswers = _allAnswers
            .where((answer) =>
                (answer.studentName?.toLowerCase() ?? '')
                    .contains(query.toLowerCase()) ||
                (answer.answer.toLowerCase()).contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildExamCard(),
        ),
        if (widget.questionType != 'multiple_choice' &&
            widget.questionType != 'true_false')
          _buildBottomSheet(context),
      ],
    );
  }

  Widget _buildSearchBar() {
    return BlocListener<OnlineExamCubit, OnlineExamState>(
        listener: (context, state) {
          if (state is OnlineExamAnswersSuccess) {
            setState(() {
              _allAnswers = state.answers;
              showSearchBar = state.answers.length >= 5;
              if (!_isSearching) {
                _filteredAnswers = List.from(_allAnswers);
              } else {
                _filterAnswers(_searchController.text);
              }
            });
          }
        },
        child: showSearchBar
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _filterAnswers(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari jawaban spesifik...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _filterAnswers('');
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox(height: 10));
  }

  Widget _buildExamCard() {
    return BlocBuilder<OnlineExamCubit, OnlineExamState>(
      builder: (context, state) {
        if (state is OnlineExamLoading && _allAnswers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OnlineExamFailure && _allAnswers.isEmpty) {
          return Center(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<OnlineExamCubit>().getOnlineExamResultAnswer(
                    examId: widget.examId,
                    questionId: widget.questionId,
                    search: '');
              },
              primaryColor: _primaryColor,
            ),
          );
        }

        if (_isSearching || _allAnswers.isNotEmpty) {
          if (_filteredAnswers.isEmpty) {
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada jawaban tersedia',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredAnswers.length,
            itemBuilder: (context, index) {
              final answer = _filteredAnswers[index];
              final controller = marksControllers.putIfAbsent(
                  "${answer.studentId}:${answer.id}",
                  () => TextEditingController(text: answer.marks.toString()));

              return StatefulBuilder(
                builder: (context, setState) {
                  bool localIsCorrect = double.parse(
                          controller.text.isNotEmpty ? controller.text : '0') >=
                      (answer.totalMarks / 2);

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan status nilai
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: localIsCorrect
                                      ? [
                                          Colors.green.shade400,
                                          Colors.green.shade300
                                        ]
                                      : [
                                          Colors.red.shade400,
                                          Colors.red.shade300
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                answer.studentName ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, top: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 50,
                                  maxHeight: 200,
                                ),
                                child: SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        answer.answer,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: (widget.questionType !=
                                              'multiple_choice' &&
                                          widget.questionType != 'true_false')
                                      ? 16
                                      : 8),
                              margin: EdgeInsets.zero,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: widget.questionType != 'multiple_choice' &&
                                      widget.questionType != 'true_false'
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Nilai jawaban berkisar antara 0 hingga ${answer.totalMarks}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            height: 40,
                                            child: TextField(
                                              controller: controller,
                                              onChanged: (value) {
                                                setState(
                                                    () {}); // Memperbarui UI lokal
                                              },
                                              onEditingComplete: () {
                                                if (controller.text.isEmpty) {
                                                  controller.text = '0';
                                                }
                                              },
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                height: 1.5,
                                              ),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey[50],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[200]!),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 8),
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                TextInputFormatter.withFunction(
                                                    (oldValue, newValue) {
                                                  if (newValue.text.isEmpty) {
                                                    return newValue;
                                                  }
                                                  final intValue = int.tryParse(
                                                          newValue.text) ??
                                                      0;
                                                  if (intValue < 0) {
                                                    return const TextEditingValue(
                                                        text: '0');
                                                  }
                                                  if (intValue >
                                                      answer.totalMarks) {
                                                    return TextEditingValue(
                                                        text: answer.totalMarks
                                                            .toString());
                                                  }
                                                  return newValue;
                                                }),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada jawaban tersedia',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity, // Lebar penuh
      decoration: BoxDecoration(
        color: Colors.white, // Latar belakang tetap putih
        border: Border(
          top: BorderSide(
              color: Colors.grey.shade400, width: 2), // Border garis atas
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, -2), // Bayangan ke atas
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity, // Lebar penuh
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorPalette.primaryMaroon, // Warna maroon
            foregroundColor: Colors.white, // Warna teks putih
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (await context
                .read<OnlineExamCubit>()
                .updateOnlineExamAnswerCorrection(
                    examId: widget.examId,
                    data: marksControllers.entries.map((entry) {
                      return {
                        'student_id':
                            int.tryParse(entry.key.split(":")[0]) ?? 0,
                        'marks': int.tryParse(entry.value.text) ?? 0,
                        "question_id": widget.questionId,
                        "answer_id": int.tryParse(entry.key.split(":")[1]) ?? 0,
                        "is_answer":
                            (int.tryParse(entry.value.text) ?? 0) > 0 ? 1 : 0
                      };
                    }).toList())) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "Nilai berhasil disimpan!",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            } else {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "Gagal menyimpan nilai!",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          child: const Text(
            "Simpan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
