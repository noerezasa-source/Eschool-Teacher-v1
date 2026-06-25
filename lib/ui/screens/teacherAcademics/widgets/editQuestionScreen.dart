import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/assignment/questionBankCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class EditQuestionScreen extends StatefulWidget {
  final Map<String, dynamic>? questionData;
  final Map<String, int>? idList;

  const EditQuestionScreen({super.key, this.questionData, this.idList});

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController questionController;
  late TextEditingController pointController;
  late TextEditingController noteController;
  late int idBankSoal;
  List<Map<String, dynamic>> options = [];
  late int version;
  String selectedType = 'multiple_choice';
  String selectedOrderType = 'numeric';

  dynamic _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor =>
      AppColorPalette.primaryMaroon; // Softer deep maroon - UPDATED
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon
  static Color get _highlightColor =>
      AppColorPalette.secondaryMaroon; // Softer bright maroon
  static Color get _energyColor => AppColorPalette.lightMaroon; // Softer light maroon
  static Color get _glowColor => AppColorPalette.secondaryMaroon; // Softer rich maroon

  void _loadImage() async {
    _imageFile = await Api.fetchImg(widget.questionData?["image"]);
    setState(() {});
  }

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
        text: stripHtmlTags(widget.questionData?['name'] ?? ''));
    selectedOrderType = widget.questionData?['typeOrder'] ?? 'numeric';
    questionController = TextEditingController(
        text: stripHtmlTags(widget.questionData?['question'] ?? ''));
    pointController = TextEditingController(
        text: widget.questionData?['default_point']?.toString() ?? '100');
    noteController = TextEditingController(
        text: stripHtmlTags(widget.questionData?['note'] ?? ''));
    idBankSoal = widget.questionData?['idBankSoal'];
    selectedType = widget.questionData?['type'] ?? 'multiple_choice';
    version = 1;

    String jsonString =
        const JsonEncoder.withIndent("  ").convert(widget.questionData);

    for (var line in jsonString.split("\n")) {
      debugPrint(line.toString());
    }

    if (widget.questionData?["image"] != null) {
      _loadImage();
    }

    if (widget.questionData?['options'] != null) {
      options = List<Map<String, dynamic>>.from(
          widget.questionData!['options'].map((opt) {
        return {
          'text': stripHtmlTags(opt['text'] ?? ''),
          'percentage': opt['percentage'] ?? 0,
          'feedback': stripHtmlTags(opt['feedback'] ?? ''),
        };
      }).toList());
    } else {
      if (selectedType == 'multiple_choice') {
        options = List.generate(
            2,
            (index) => {
                  'text': '',
                  'percentage': 0,
                  'feedback': '',
                });
      } else {
        options = _getDefaultOptionsForType(selectedType);
      }
    }

    // Initialize the app bar animation controller
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  late AnimationController
      _fabAnimationController; // AnimationController for the app bar

  @override
  void dispose() {
    nameController.dispose();
    questionController.dispose();
    pointController.dispose();
    noteController.dispose();
    _fabAnimationController
        .dispose(); // Dispose the app bar animation controller
    super.dispose();
  }

  String toRomanNumeral(int number) {
    if (number < 1) {
      return "Angka harus lebih besar dari 0";
    }

    List<int> values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    List<String> symbols = [
      "M",
      "CM",
      "D",
      "CD",
      "C",
      "XC",
      "L",
      "XL",
      "X",
      "IX",
      "V",
      "IV",
      "I"
    ];

    String result = "";
    int num = number;

    for (int i = 0; i < values.length; i++) {
      while (num >= values[i]) {
        result += symbols[i];
        num -= values[i];
      }
    }

    while (num > 0) {
      result += "M";
      num -= 1000;
    }

    return result;
  }

  String toBaseAZ(int number) {
    if (number < 1) {
      return "Angka harus lebih besar dari 0";
    }

    String result = "";
    int num = number;

    while (num > 0) {
      int remainder = (num - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      num = (num - 1) ~/ 26;
    }

    return result;
  }

  String stripHtmlTags(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }
    // Remove all HTML tags
    final strippedString = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    return strippedString
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
  }

  void _onOrderTypeChanged(String type) {
    setState(() {
      selectedOrderType = type;
    });
  }

  List<Map<String, dynamic>> _getDefaultOptionsForType(String type) {
    switch (type) {
      case 'true_false':
        return [
          {'text': 'Benar', 'percentage': 0, 'feedback': ''},
          {'text': 'Salah', 'percentage': 0, 'feedback': ''},
        ];
      case 'essay':
      case 'short_answer':
      case 'numeric':
        return [
          {'text': '', 'percentage': 100, 'feedback': ''},
        ];
      case 'multiple_choice':
      default:
        return [
          {'text': '', 'percentage': 0, 'feedback': ''},
          {'text': '', 'percentage': 0, 'feedback': ''},
        ];
    }
  }

  void _addOption() {
    setState(() {
      options.add({
        'text': '',
        'percentage': 0,
        'feedback': '',
      });
    });
  }

  void _addAnswerOption() {
    setState(() {
      switch (selectedType) {
        case 'essay':
        case 'short_answer':
        case 'numeric':
          options.add({
            'text': '',
            'percentage': 0,
            'feedback': '',
          });
          break;
        case 'multiple_choice':
          options.add({
            'text': '',
            'percentage': 0,
            'feedback': '',
          });
          break;
        case 'true_false':
          break;
      }
    });
  }

  void _removeAnswerOption(int index) {
    if (options.length > 2) {
      setState(() {
        bool wasCorrectAnswer = options[index]['percentage'] == 100;
        options.removeAt(index);
        if (wasCorrectAnswer && options.isNotEmpty) {
          options[0]['percentage'] = 100;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 2 pilihan jawaban'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isSubmitting) return;

      setState(() {
        _isSubmitting = true;
      });

      try {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        try {
          debugPrint(widget.idList.toString());
          debugPrint({
            "banksoalSoalId": widget.idList!['bankSoalSoalId'],
            "subjectId": widget.idList!['subjectId'],
            "bankSoalId": idBankSoal,
            "name": nameController.text.trim(),
            "type": selectedType,
            "orderType": selectedOrderType,
            "defaultPoint": int.parse(pointController.text),
            "question": questionController.text.trim(),
            "note": noteController.text.trim(),
            "image": _imageFile,
            "options": options
                .map((opt) => QuestionOption(
                      text: opt['text'].toString(),
                      percentage: int.parse(opt['percentage'].toString()),
                      feedback: opt['feedback'].toString(),
                    ))
                .toList()
          }.toString());

          debugPrint("===;");

          await context.read<QuestionBankCubit>().updateQuestion(
                banksoalSoalId: widget.idList!['bankSoalSoalId'] ?? 0,
                subjectId: widget.idList!['subjectId'] ?? 0,
                bankSoalId: idBankSoal,
                name: nameController.text.trim(),
                type: selectedType,
                orderType: selectedOrderType,
                defaultPoint: int.parse(pointController.text),
                question: questionController.text.trim(),
                note: noteController.text.trim(),
                image: _imageFile,
                options: options
                    .map((opt) => QuestionOption(
                          text: opt['text'].toString(),
                          percentage: int.parse(opt['percentage'].toString()),
                          feedback: opt['feedback'].toString(),
                        ))
                    .toList(),
              );
          if (!mounted) return;
          debugPrint("AMAN ABDURRAHMAN");

          Get.back(result: true);

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
                      'Soal berhasil diperbarui!',
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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
          );
        } catch (e) {
          debugPrint("ABDURRAHMAN SALAM");
          debugPrint(e.toString());
          if (!e.toString().contains('validation.exists') ||
              !e.toString().toLowerCase().contains('updated')) {
            Get.snackbar(
              'Error',
              "Gagal mengedit pertanyaan, periksa koneksi anda dan coba lagi",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to dark icons since background is white
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for white background
    ));

    return Scaffold(
      appBar: CustomModernAppBar(
        title: "Edit Soal",
        icon: Icons.edit_note,
        fabAnimationController: _fabAnimationController,
        primaryColor: _primaryColor,
        lightColor: _highlightColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showAddButton: false, // Don't show add button as requested
      ),
      body: SafeArea(
        top: false, // Don't pad the top
        child: Container(
          color: Colors.grey[50],
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: _buildQuestionInfoCard(),
                  ),
                  const SizedBox(height: 20),
                  _buildQuestionTypeSelector(),
                  const SizedBox(height: 15),
                  if (selectedType == 'multiple_choice')
                    _buildMultipleChoiceOrder(),
                  const SizedBox(height: 20),
                  _buildAnswerOptionsCard(),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gambar Pertanyaan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_imageFile != null) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _imageFile is File
                                    ? Image.file(_imageFile as File,
                                        fit: BoxFit.cover)
                                    : FutureBuilder<Uint8List>(
                                        future:
                                            (_imageFile as XFile).readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          if (snapshot.hasError ||
                                              !snapshot.hasData) {
                                            return const Center(
                                                child: Icon(Icons.error));
                                          }
                                          return Image.memory(snapshot.data!,
                                              fit: BoxFit.cover);
                                        },
                                      ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                              ),
                            ],
                          ),
                        ] else
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tambah Gambar',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: _buildSubmitButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: 0.08),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  'Informasi Soal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                _buildAnimatedFormField(
                  controller: nameController,
                  label: 'Nama Soal',
                  icon: Icons.title_rounded,
                  hint: 'Masukkan nama soal',
                  maxLines: null,
                  minLines: 2,
                ),
                const SizedBox(height: 20),

                // Question field
                _buildAnimatedFormField(
                  controller: questionController,
                  label: 'Pertanyaan',
                  icon: Icons.help_outline_rounded,
                  hint: 'Masukkan pertanyaan lengkap',
                  maxLines: null,
                  minLines: 3,
                ),
                const SizedBox(height: 20),

                // Note field
                _buildAnimatedFormField(
                  controller: noteController,
                  label: 'Catatan (Opsional)',
                  icon: Icons.notes_rounded,
                  hint: 'Tambahkan catatan jika diperlukan',
                  maxLines: 2,
                  isOptional: true,
                ),
                const SizedBox(height: 20),

                // Points field
                _buildAnimatedFormField(
                  controller: pointController,
                  label: 'Poin Bawaan',
                  icon: Icons.stars_rounded,
                  hint: 'Masukkan poin',
                  keyboardType: TextInputType.number,
                  helperText: 'Nilai maksimal untuk soal ini',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Poin Bawaan harus diisi';
                    }
                    final point = int.tryParse(value);
                    if (point == null || point <= 0) {
                      return 'Masukkan nilai yang valid';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _updateOptionsPoints();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int? maxLines = 1,
    int? minLines,
    bool isOptional = false,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
        // Input field with animation
        FadeInLeft(
          duration: const Duration(milliseconds: 300),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator ??
                (value) {
                  if (!isOptional && (value == null || value.isEmpty)) {
                    return '$label harus diisi';
                  }
                  return null;
                },
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeSelector() {
    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: 0.08),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor, _highlightColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Tipe Soal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Type selection area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih tipe soal yang sesuai:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildTypeDropdownEnhanced(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdownEnhanced() {
    // Map of question types with their details
    final questionTypes = {
      'multiple_choice': {
        'icon': Icons.check_circle_outline_rounded,
        'label': 'Pilihan Ganda',
      },
      'essay': {
        'icon': Icons.edit_note_rounded,
        'label': 'Essay',
      },
      'true_false': {
        'icon': Icons.rule_rounded,
        'label': 'Benar/Salah',
      },
      'short_answer': {
        'icon': Icons.short_text_rounded,
        'label': 'Jawaban Singkat',
      },
      'numeric': {
        'icon': Icons.numbers_rounded,
        'label': 'Numerik',
      },
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedType,
        icon:
            Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: questionTypes.entries.map((type) {
          return DropdownMenuItem<String>(
            value: type.key,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.value['icon'] as IconData,
                  color: _primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    type.value['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null && newValue != selectedType) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 10),
                      Text(
                        'Konfirmasi Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Mengubah tipe soal akan mereset semua pilihan jawaban yang sudah ada. Anda yakin ingin melanjutkan?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedType = newValue;
                          options = _getDefaultOptionsForType(newValue);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Ya, Ubah'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildMultipleChoiceOrder() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 5,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipe Urutan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedOrderType,
                  items: [
                    _buildDropdownItem(
                        'roman_uppercase', 'Romawi Kapital', null),
                    _buildDropdownItem('roman_lowercase', 'Romawi', null),
                    _buildDropdownItem('numeric', 'Angka', null),
                    _buildDropdownItem(
                        'alphabet_uppercase', 'Alfabet Kapital', null),
                    _buildDropdownItem('alphabet_lowercase', 'Alfabet', null),
                  ],
                  onChanged: (value) => _onOrderTypeChanged(value!),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptionsCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: 0.08),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_highlightColor, _energyColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.question_answer_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  // Display type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedType == 'multiple_choice'
                              ? Icons.check_circle_outline
                              : selectedType == 'essay'
                                  ? Icons.edit_note
                                  : selectedType == 'true_false'
                                      ? Icons.rule
                                      : selectedType == 'short_answer'
                                          ? Icons.short_text
                                          : Icons.numbers,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          selectedType == 'multiple_choice'
                              ? 'Pilihan Ganda'
                              : selectedType == 'essay'
                                  ? 'Essay'
                                  : selectedType == 'true_false'
                                      ? 'Benar/Salah'
                                      : selectedType == 'short_answer'
                                          ? 'Jawaban Singkat'
                                          : 'Numerik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Instructions section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedType == 'multiple_choice'
                          ? 'Tambahkan pilihan jawaban dan tandai jawaban yang benar'
                          : selectedType == 'true_false'
                              ? 'Pilih jawaban yang benar (Benar atau Salah)'
                              : 'Tambahkan jawaban yang diterima untuk soal ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Options area with appropriate padding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedType == 'multiple_choice') ...[
                    ...options.asMap().entries.map((entry) =>
                        _buildMultipleChoiceOptionEnhanced(entry.key)),
                    _buildAddOptionButtonEnhanced(),
                  ] else if (selectedType == 'true_false') ...[
                    _buildTrueFalseOptionEnhanced(0, 'Benar'),
                    _buildTrueFalseOptionEnhanced(1, 'Salah'),
                  ] else ...[
                    _buildEssayOptionEnhanced(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptionEnhanced(int index) {
    // Get the appropriate prefix based on selected order type
    String prefix = selectedOrderType == 'roman_uppercase'
        ? toRomanNumeral(index + 1).toUpperCase()
        : selectedOrderType == 'roman_lowercase'
            ? toRomanNumeral(index + 1).toLowerCase()
            : selectedOrderType == 'alphabet_uppercase'
                ? toBaseAZ(index + 1).toUpperCase()
                : selectedOrderType == 'alphabet_lowercase'
                    ? toBaseAZ(index + 1).toLowerCase()
                    : (index + 1).toString();

    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: options[index]['percentage'] == 100
              ? Colors.green.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: options[index]['percentage'] == 100
                ? Colors.green.shade300
                : Colors.grey.shade200,
            width: options[index]['percentage'] == 100 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.07),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: options[index]['percentage'] == 100
                    ? Colors.green.shade100.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: options[index]['percentage'] == 100
                        ? Colors.green.shade200
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: options[index]['percentage'] == 100
                          ? Colors.green
                          : _primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        prefix,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: options[index]['percentage'] == 100
                              ? Colors.white
                              : _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[index]['percentage'] == 100
                          ? 'Jawaban Benar'
                          : 'Pilihan Jawaban',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: options[index]['percentage'] == 100
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (options.length > 2)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => _removeAnswerOption(index),
                      tooltip: 'Hapus pilihan jawaban',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Option content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Ensure column takes minimum height
                children: [
                  // Text input
                  TextFormField(
                    initialValue: options[index]['text'],
                    maxLines: null,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Teks Jawaban',
                      prefixIcon: Icon(
                        Icons.text_fields_rounded,
                        color: _primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                    onChanged: (value) {
                      setState(() {
                        options[index]['text'] = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Correct answer selection
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: options[index]['percentage'] == 100,
                          onChanged: (value) {
                            setState(() {
                              if (value!) {
                                // Set all percentages to 0 first
                                for (var opt in options) {
                                  opt['percentage'] = 0;
                                }
                                // Then set this one to 100
                                options[index]['percentage'] = 100;
                              } else {
                                options[index]['percentage'] = 0;
                              }
                            });
                          },
                          activeColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          'Tandai Benar',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Feedback input
                  TextFormField(
                    initialValue: options[index]['feedback'],
                    decoration: InputDecoration(
                      labelText: 'Umpan Balik untuk jawaban ini',
                      prefixIcon: Icon(
                        Icons.comment_outlined,
                        color: _primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText: '* Wajib diisi',
                      helperStyle: const TextStyle(color: Colors.red),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Umpan Balik tidak boleh kosong';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {
                      options[index]['feedback'] = value;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrueFalseOptionEnhanced(int index, String text) {
    bool isSelected = options[index]['percentage'] == 100;

    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.07),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.shade100.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? Colors.green.shade200
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    text == 'Benar'
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isSelected
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Jawaban Benar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Option content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection control
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          // ignore: deprecated_member_use
                          groupValue: options
                              .indexWhere((opt) => opt['percentage'] == 100),
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              for (var i = 0; i < options.length; i++) {
                                options[i]['percentage'] = i == value ? 100 : 0;
                              }
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Text(
                          'Tandai Benar',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Feedback input
                  TextFormField(
                    initialValue: options[index]['feedback'],
                    decoration: InputDecoration(
                      labelText: 'Umpan Balik',
                      prefixIcon: Icon(
                        Icons.comment_outlined,
                        color: _primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText: '* Wajib diisi',
                      helperStyle: const TextStyle(color: Colors.red),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Umpan Balik tidak boleh kosong';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {
                      options[index]['feedback'] = value;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssayOptionEnhanced() {
    return Column(
      children: [
        ...List.generate(
          options.length,
          (index) => FadeInLeft(
            delay: Duration(milliseconds: 100 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.07),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                selectedType == 'essay'
                                    ? Icons.edit_note_rounded
                                    : selectedType == 'short_answer'
                                        ? Icons.short_text_rounded
                                        : Icons.numbers_rounded,
                                color: _primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedType == 'essay'
                                  ? 'Jawaban Essay'
                                  : selectedType == 'short_answer'
                                      ? 'Jawaban Singkat'
                                      : 'Jawaban Numerik',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (options.length > 1)
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red.shade400),
                            onPressed: () => _removeAnswerOption(index),
                            tooltip: 'Hapus jawaban ini',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),

                  // Option content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Answer text field
                        TextFormField(
                          initialValue: options[index]['text'],
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: selectedType == 'short_answer'
                                ? 'Jawaban Singkat'
                                : selectedType == 'numeric'
                                    ? 'Jawaban Numerik'
                                    : 'Jawaban Essay',
                            prefixIcon: Icon(
                              selectedType == 'short_answer'
                                  ? Icons.short_text
                                  : selectedType == 'numeric'
                                      ? Icons.numbers
                                      : Icons.edit_note,
                              color: _primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: selectedType == 'numeric'
                              ? TextInputType.number
                              : TextInputType.multiline,
                          inputFormatters: selectedType == 'numeric'
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : null,
                          maxLines: null,
                          minLines: selectedType == 'essay' ? 3 : 1,
                          textInputAction: selectedType == 'essay'
                              ? TextInputAction.newline
                              : TextInputAction.done,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Wajib diisi' : null,
                          onChanged: (value) {
                            setState(() {
                              options[index]['text'] = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Percentage field
                        TextFormField(
                          initialValue: options[index]['percentage'].toString(),
                          decoration: InputDecoration(
                            labelText: 'Persentase Nilai',
                            prefixIcon:
                                Icon(Icons.percent, color: _primaryColor),
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Wajib diisi' : null,
                          onChanged: (value) {
                            setState(() {
                              options[index]['percentage'] =
                                  int.tryParse(value) ?? 0;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Feedback field
                        TextFormField(
                          initialValue: options[index]['feedback'],
                          decoration: InputDecoration(
                            labelText: 'Umpan Balik',
                            prefixIcon: Icon(Icons.comment_outlined,
                                color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            helperText: '*Wajib diisi',
                            helperStyle: const TextStyle(color: Colors.red),
                          ),
                          maxLines: null,
                          minLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Umpan Balik tidak boleh kosong';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              options[index]['feedback'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selectedType != 'true_false') _buildAddAnswerButtonEnhanced(),
      ],
    );
  }

  Widget _buildAddOptionButtonEnhanced() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: _addOption,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: _primaryColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tambah Pilihan Jawaban',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddAnswerButtonEnhanced() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: _addAnswerOption,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: _primaryColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tambah Jawaban',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSubmitting ? null : _submitForm,
              borderRadius: BorderRadius.circular(15),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSubmitting) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _isSubmitting ? 'Memproses...' : 'Simpan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!_isSubmitting) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ).animate(onPlay: (controller) {
                        controller.repeat(reverse: true);
                      }).slideX(
                        begin: 0,
                        end: 0.3,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
      String value, String label, IconData? icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  void _updateOptionsPoints() {
    final defaultPoint = int.tryParse(pointController.text) ?? 100;
    setState(() {
      for (var option in options) {
        final percentage = option['percentage'] as int;
        final point = (defaultPoint * percentage / 100).round();
        option['point'] = point;
      }
    });
  }
}
