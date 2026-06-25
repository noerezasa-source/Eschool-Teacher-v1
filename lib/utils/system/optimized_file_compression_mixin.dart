import 'dart:io';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'optimized_file_compression_utils.dart';

/// Optimized mixin with loading indicators and better UX
mixin OptimizedFileCompressionMixin {
  /// Pick and compress files with loading dialog
  Future<List<File>?> pickAndCompressFiles({
    FileType fileType = FileType.any,
    bool allowMultiple = true,
    List<String>? allowedExtensions,
    double maxSizeInMB = 0.5, // Default 500KB
    int? customQuality,
    bool forceCompress = true,
    required BuildContext context,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '\n🚀 [OPTIMIZED FILE PICKER] Starting file selection and compression...');
        debugPrint('   📋 File type: $fileType');
        debugPrint('   📊 Max size: ${maxSizeInMB.toStringAsFixed(2)} MB');
        debugPrint('   💪 Force compress: $forceCompress');
      }

      // Pick files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
      );

      if (result == null) {
        if (kDebugMode) {
          debugPrint('   ❌ User cancelled file picker');
        }
        return null;
      }

      final List<File> selectedFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      if (selectedFiles.isEmpty) {
        if (kDebugMode) {
          debugPrint('   ❌ No files selected');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('   ✅ Selected ${selectedFiles.length} file(s)');
        for (int i = 0; i < selectedFiles.length; i++) {
          final file = selectedFiles[i];
          final size = await file.length();
          debugPrint(
              '     📄 File ${i + 1}: ${file.path.split('/').last} (${OptimizedFileCompressionUtils.formatFileSize(size)})');
        }
      }

      // Show loading dialog and compress files
      if (!context.mounted) return null;
      return await _showCompressionDialog(
        context: context,
        files: selectedFiles,
        maxSizeInMB: maxSizeInMB,
        customQuality: customQuality,
        forceCompress: forceCompress,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CRITICAL ERROR] File picker and compression failed: $e');
      }
      return null;
    }
  }

  /// Show compression dialog with progress
  Future<List<File>?> _showCompressionDialog({
    required BuildContext context,
    required List<File> files,
    required double maxSizeInMB,
    int? customQuality,
    required bool forceCompress,
  }) async {
    return await showDialog<List<File>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _CompressionDialog(
          files: files,
          maxSizeInMB: maxSizeInMB,
          customQuality: customQuality,
          forceCompress: forceCompress,
          onComplete: (result) {
            Navigator.of(dialogContext).pop(result);
          },
          onError: (error) {
            Navigator.of(dialogContext)
                .pop(files); // Return original files on error
          },
        );
      },
    );
  }

  /// Pick and compress images specifically
  Future<List<File>?> pickAndCompressImages({
    bool allowMultiple = true,
    double maxSizeInMB = 0.5,
    int? customQuality,
    bool forceCompress = true,
    required BuildContext context,
  }) async {
    return await pickAndCompressFiles(
      fileType: FileType.image,
      allowMultiple: allowMultiple,
      maxSizeInMB: maxSizeInMB,
      customQuality: customQuality,
      forceCompress: forceCompress,
      context: context,
    );
  }

  /// Pick and compress single file
  Future<File?> pickAndCompressSingleFile({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    double maxSizeInMB = 0.5,
    int? customQuality,
    bool forceCompress = true,
    required BuildContext context,
  }) async {
    final files = await pickAndCompressFiles(
      fileType: fileType,
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
      maxSizeInMB: maxSizeInMB,
      customQuality: customQuality,
      forceCompress: forceCompress,
      context: context,
    );

    if (!context.mounted) return null;
    return files?.isNotEmpty == true ? files!.first : null;
  }

  /// Show compression result to user with modern design
  void showCompressionResult(
    BuildContext context, {
    required int originalSize,
    required int compressedSize,
    required String fileName,
  }) {
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compression Successful!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${OptimizedFileCompressionUtils.formatFileSize(originalSize)} → ${OptimizedFileCompressionUtils.formatFileSize(compressedSize)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${reduction.toStringAsFixed(1)}% size reduction',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }
}

/// Compression dialog widget
class _CompressionDialog extends StatefulWidget {
  final List<File> files;
  final double maxSizeInMB;
  final int? customQuality;
  final bool forceCompress;
  final Function(List<File>) onComplete;
  final Function(String) onError;

  const _CompressionDialog({
    required this.files,
    required this.maxSizeInMB,
    this.customQuality,
    required this.forceCompress,
    required this.onComplete,
    required this.onError,
  });

  @override
  State<_CompressionDialog> createState() => _CompressionDialogState();
}

class _CompressionDialogState extends State<_CompressionDialog> {
  String currentStatus = 'Initializing...';
  int currentFileIndex = 0;
  double progress = 0.0;
  List<File> compressedFiles = [];

  @override
  void initState() {
    super.initState();
    _startCompression();
  }

  Future<void> _startCompression() async {
    try {
      setState(() {
        currentStatus = 'Initializing compression engine...';
        progress = 0.0;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      for (int i = 0; i < widget.files.length; i++) {
        final file = widget.files[i];
        final fileName = file.path.split('/').last;

        setState(() {
          currentFileIndex = i + 1;
          currentStatus = 'Analyzing $fileName...';
          progress = (i + 0.1) / widget.files.length;
        });

        await Future.delayed(const Duration(milliseconds: 200));

        setState(() {
          currentStatus = 'Compressing $fileName...';
          progress = (i + 0.5) / widget.files.length;
        });

        final compressedFile = await OptimizedFileCompressionUtils.compressFile(
          file: file,
          maxSizeInMB: widget.maxSizeInMB,
          customQuality: widget.customQuality,
          forceCompress: widget.forceCompress,
          onProgress: (status) {
            if (mounted) {
              setState(() {
                currentStatus = status;
              });
            }
          },
        );

        compressedFiles.add(compressedFile);

        setState(() {
          currentStatus = 'Optimized $fileName successfully!';
          progress = (i + 1) / widget.files.length;
        });

        await Future.delayed(const Duration(milliseconds: 300));
      }

      setState(() {
        progress = 1.0;
        currentStatus = 'All files compressed successfully!';
      });

      // Show completion for a moment
      await Future.delayed(const Duration(milliseconds: 800));

      widget.onComplete(compressedFiles);
    } catch (e) {
      setState(() {
        currentStatus = 'Compression failed: ${e.toString()}';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColorPalette.secondaryMaroon, AppColorPalette.primaryMaroon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.compress,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Compressing Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Progress Bar
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColorPalette.secondaryMaroon, AppColorPalette.primaryMaroon],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Progress Text
              Text(
                'File $currentFileIndex of ${widget.files.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              // Status Text
              SizedBox(
                width: double.infinity,
                child: Text(
                  currentStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Percentage
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColorPalette.primaryMaroon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
