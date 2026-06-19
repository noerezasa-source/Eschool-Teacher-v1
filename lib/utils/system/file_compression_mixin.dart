import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'file_compression_utils.dart';

/// Mixin untuk integrasi mudah kompresi file pada halaman yang sudah ada
///
/// Cara penggunaan:
/// 1. Tambahkan `with FileCompressionMixin` pada State class
/// 2. Ganti panggilan file picker biasa dengan `pickAndCompressFiles()`
/// 3. Kompresi akan berjalan otomatis sebelum file dikembalikan
mixin FileCompressionMixin<T extends StatefulWidget> on State<T> {
  bool _isCompressing = false;

  /// Getter untuk status kompresi
  bool get isCompressing => _isCompressing;

  /// Pick dan kompres file secara otomatis
  ///
  /// Parameters:
  /// - [allowMultiple]: Izinkan pilih multiple files
  /// - [type]: Tipe file yang diizinkan (default: any)
  /// - [allowedExtensions]: Ekstensi file yang diizinkan
  /// - [maxSizeInMB]: Ukuran maksimal file setelah kompresi (default: 2MB)
  /// - [compressionQuality]: Kualitas kompresi (0-100, default: auto)
  /// - [showProgressDialog]: Tampilkan dialog progress saat kompresi
  /// - [forceCompress]: Paksa kompres meskipun file sudah kecil (default: true)
  ///
  /// Returns: List file yang sudah dikompres
  Future<List<PlatformFile>?> pickAndCompressFiles({
    bool allowMultiple = true,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    double maxSizeInMB = 2.0,
    int? compressionQuality,
    bool showProgressDialog = true,
    bool forceCompress = true,
    BuildContext? context,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📂 [FILE PICKER] Memulai pemilihan file:');
        debugPrint('   📋 Tipe: ${type.toString()}');
        debugPrint('   🔢 Multiple: $allowMultiple');
        debugPrint(
            '   🎯 Target maksimal: ${maxSizeInMB.toStringAsFixed(2)} MB');
        debugPrint(
            '   📝 Ekstensi: ${allowedExtensions?.join(", ") ?? "Semua"}');
      }

      // Pick files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: type,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ [FILE PICKER] Tidak ada file yang dipilih');
        }
        return null;
      }

      if (context != null && !context.mounted) return null;

      if (kDebugMode) {
        debugPrint('✅ [FILE PICKER] File terpilih: ${result.files.length}');
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          final fileSize = file.size;
          final sizeInMB = fileSize / (1024 * 1024);
          debugPrint(
              '   📄 [${i + 1}] ${file.name}: ${formatFileSize(fileSize)} (${sizeInMB.toStringAsFixed(2)} MB)');
        }
      }

      List<PlatformFile> compressedFiles = [];

      // Jika hanya 1 file, langsung kompres
      if (result.files.length == 1) {
        final compressedFile = await _compressSingleFile(
          result.files.first,
          maxSizeInMB: maxSizeInMB,
          compressionQuality: compressionQuality,
          showProgress: showProgressDialog,
          forceCompress: forceCompress,
          context: context,
        );

        if (compressedFile != null) {
          compressedFiles.add(compressedFile);
        }
      } else {
        // Multiple files - kompres dengan progress dialog
        compressedFiles = await _compressMultipleFiles(
          result.files,
          maxSizeInMB: maxSizeInMB,
          compressionQuality: compressionQuality,
          showProgress: showProgressDialog,
          forceCompress: forceCompress,
          context: context,
        );
      }

      return compressedFiles;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in pickAndCompressFiles: $e');
      }
      if (context != null) {
        if (!context.mounted) return null;
        _showErrorSnackBar('Error memilih file: $e', context);
      }
      return null;
    }
  }

  /// Pick dan kompres gambar dari gallery/camera
  ///
  /// Parameters:
  /// - [source]: Sumber gambar (gallery/camera)
  /// - [maxSizeInMB]: Ukuran maksimal setelah kompresi
  /// - [compressionQuality]: Kualitas kompresi
  /// - [allowMultiple]: Izinkan multiple selection (hanya untuk gallery)
  ///
  /// Returns: List file gambar yang sudah dikompres
  Future<List<File>?> pickAndCompressImages({
    ImageSource source = ImageSource.gallery,
    double maxSizeInMB = 2.0,
    int? compressionQuality,
    bool allowMultiple = true,
    bool showProgressDialog = true,
    BuildContext? context,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      List<XFile> pickedImages = [];

      if (source == ImageSource.camera || !allowMultiple) {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          pickedImages.add(image);
        }
      } else {
        final images = await picker.pickMultiImage(
          imageQuality: 100, // Ambil original, kompres sendiri
        );
        pickedImages.addAll(images);
      }

      if (pickedImages.isEmpty) {
        return null;
      }

      if (context != null && !context.mounted) return null;

      List<File> compressedFiles = [];

      if (pickedImages.length == 1) {
        final compressedFile = await _compressImageFile(
          File(pickedImages.first.path),
          maxSizeInMB: maxSizeInMB,
          compressionQuality: compressionQuality,
          showProgress: showProgressDialog,
          context: context,
        );

        if (compressedFile != null) {
          compressedFiles.add(compressedFile);
        }
      } else {
        compressedFiles = await _compressMultipleImageFiles(
          pickedImages.map((e) => File(e.path)).toList(),
          maxSizeInMB: maxSizeInMB,
          compressionQuality: compressionQuality,
          showProgress: showProgressDialog,
          context: context,
        );
      }

      return compressedFiles.isNotEmpty ? compressedFiles : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in pickAndCompressImages: $e');
      }
      if (context != null) {
        if (!context.mounted) return null;
        _showErrorSnackBar('Error memilih gambar: $e', context);
      }
      return null;
    }
  }

  /// Kompres file yang sudah ada
  ///
  /// Parameters:
  /// - [file]: File yang akan dikompres
  /// - [maxSizeInMB]: Ukuran maksimal setelah kompresi
  /// - [compressionQuality]: Kualitas kompresi
  ///
  /// Returns: File yang sudah dikompres
  Future<File?> compressExistingFile({
    required File file,
    double maxSizeInMB = 2.0,
    int? compressionQuality,
    bool showProgressDialog = true,
    BuildContext? context,
  }) async {
    return await _compressImageFile(
      file,
      maxSizeInMB: maxSizeInMB,
      compressionQuality: compressionQuality,
      showProgress: showProgressDialog,
      context: context,
    );
  }

  /// Kompres PlatformFile tunggal
  Future<PlatformFile?> _compressSingleFile(
    PlatformFile platformFile, {
    required double maxSizeInMB,
    int? compressionQuality,
    bool showProgress = true,
    bool forceCompress = true,
    BuildContext? context,
  }) async {
    if (platformFile.path == null) return platformFile;

    final file = File(platformFile.path!);

    // Log info sebelum kompresi
    final originalSize = await file.length();
    final originalSizeMB = originalSize / (1024 * 1024);

    if (kDebugMode) {
      debugPrint('🗜️ [FILE COMPRESSION] Memulai kompresi file:');
      debugPrint('   📁 Nama: ${platformFile.name}');
      debugPrint(
          '   📊 Ukuran asli: ${formatFileSize(originalSize)} (${originalSizeMB.toStringAsFixed(2)} MB)');
      debugPrint('   🎯 Target maksimal: ${maxSizeInMB.toStringAsFixed(2)} MB');
      debugPrint('   🔧 Kualitas: ${compressionQuality ?? "Auto"}');
    }

    if (showProgress && context != null) {
      if (!context.mounted) return null;
      return await _showCompressionDialog<PlatformFile>(
        context: context,
        compressionTask: () async {
          final compressedFile = await FileCompressionUtils.compressFile(
            file: file,
            maxSizeInMB: maxSizeInMB,
            customQuality: compressionQuality,
            forceCompress: forceCompress,
          );

          // Log hasil kompresi
          final compressedSize = await compressedFile.length();
          final compressedSizeMB = compressedSize / (1024 * 1024);
          final compressionRatio =
              ((originalSize - compressedSize) / originalSize * 100);
          final sizeDifference = originalSize - compressedSize;

          if (kDebugMode) {
            debugPrint('✅ [FILE COMPRESSION] Kompresi selesai:');
            debugPrint(
                '   📊 Ukuran hasil: ${formatFileSize(compressedSize)} (${compressedSizeMB.toStringAsFixed(2)} MB)');
            debugPrint(
                '   💾 Penghematan: ${formatFileSize(sizeDifference)} (${compressionRatio.toStringAsFixed(1)}%)');
            debugPrint('   📍 Path: ${compressedFile.path}');
            if (compressedSize == originalSize) {
              debugPrint(
                  '   ℹ️  File tidak dikompres (sudah optimal atau format tidak didukung)');
            }
          }

          return PlatformFile(
            name: platformFile.name,
            path: compressedFile.path,
            size: compressedSize,
            bytes: platformFile.bytes,
          );
        },
        message: 'Mengkompres ${platformFile.name}...',
      );
    } else {
      final compressedFile = await FileCompressionUtils.compressFile(
        file: file,
        maxSizeInMB: maxSizeInMB,
        customQuality: compressionQuality,
      );

      // Log hasil kompresi untuk mode tanpa dialog
      final compressedSize = await compressedFile.length();
      final compressedSizeMB = compressedSize / (1024 * 1024);
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100);
      final sizeDifference = originalSize - compressedSize;

      if (kDebugMode) {
        debugPrint('✅ [FILE COMPRESSION] Kompresi selesai:');
        debugPrint(
            '   📊 Ukuran hasil: ${formatFileSize(compressedSize)} (${compressedSizeMB.toStringAsFixed(2)} MB)');
        debugPrint(
            '   💾 Penghematan: ${formatFileSize(sizeDifference)} (${compressionRatio.toStringAsFixed(1)}%)');
        debugPrint('   📍 Path: ${compressedFile.path}');
        if (compressedSize == originalSize) {
          debugPrint(
              '   ℹ️  File tidak dikompres (sudah optimal atau format tidak didukung)');
        }
      }

      return PlatformFile(
        name: platformFile.name,
        path: compressedFile.path,
        size: compressedSize,
        bytes: platformFile.bytes,
      );
    }
  }

  /// Kompres multiple PlatformFiles
  Future<List<PlatformFile>> _compressMultipleFiles(
    List<PlatformFile> platformFiles, {
    required double maxSizeInMB,
    int? compressionQuality,
    bool showProgress = true,
    bool forceCompress = true,
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      debugPrint('🗜️ [BATCH COMPRESSION] Memulai kompresi batch:');
      debugPrint('   📁 Jumlah file: ${platformFiles.length}');
      debugPrint(
          '   🎯 Target maksimal per file: ${maxSizeInMB.toStringAsFixed(2)} MB');
    }

    if (showProgress && context != null) {
      return await _showCompressionDialog<List<PlatformFile>>(
            context: context,
            compressionTask: () async {
              List<PlatformFile> compressedFiles = [];
              int totalOriginalSize = 0;
              int totalCompressedSize = 0;

              for (int i = 0; i < platformFiles.length; i++) {
                final platformFile = platformFiles[i];
                if (platformFile.path == null) {
                  compressedFiles.add(platformFile);
                  continue;
                }

                final file = File(platformFile.path!);
                final originalSize = await file.length();
                totalOriginalSize += originalSize;

                if (kDebugMode) {
                  debugPrint(
                      '   📄 [${i + 1}/${platformFiles.length}] ${platformFile.name}: ${formatFileSize(originalSize)}');
                }

                final compressedFile = await FileCompressionUtils.compressFile(
                  file: file,
                  maxSizeInMB: maxSizeInMB,
                  customQuality: compressionQuality,
                );

                final compressedSize = await compressedFile.length();
                totalCompressedSize += compressedSize;

                compressedFiles.add(PlatformFile(
                  name: platformFile.name,
                  path: compressedFile.path,
                  size: compressedSize,
                  bytes: platformFile.bytes,
                ));
              }

              if (kDebugMode) {
                final totalSavings = totalOriginalSize - totalCompressedSize;
                final totalCompressionRatio = totalOriginalSize > 0
                    ? (totalSavings / totalOriginalSize * 100)
                    : 0.0;
                debugPrint('✅ [BATCH COMPRESSION] Selesai:');
                debugPrint(
                    '   📊 Total ukuran asli: ${formatFileSize(totalOriginalSize)}');
                debugPrint(
                    '   📊 Total ukuran hasil: ${formatFileSize(totalCompressedSize)}');
                debugPrint(
                    '   💾 Total penghematan: ${formatFileSize(totalSavings)} (${totalCompressionRatio.toStringAsFixed(1)}%)');
              }

              return compressedFiles;
            },
            message: 'Mengkompres ${platformFiles.length} file...',
          ) ??
          [];
    } else {
      List<PlatformFile> compressedFiles = [];
      int totalOriginalSize = 0;
      int totalCompressedSize = 0;

      for (int i = 0; i < platformFiles.length; i++) {
        final platformFile = platformFiles[i];
        if (platformFile.path == null) {
          compressedFiles.add(platformFile);
          continue;
        }

        final file = File(platformFile.path!);
        final originalSize = await file.length();
        totalOriginalSize += originalSize;

        if (kDebugMode) {
          debugPrint(
              '   📄 [${i + 1}/${platformFiles.length}] ${platformFile.name}: ${formatFileSize(originalSize)}');
        }

        final compressedFile = await FileCompressionUtils.compressFile(
          file: file,
          maxSizeInMB: maxSizeInMB,
          customQuality: compressionQuality,
        );

        final compressedSize = await compressedFile.length();
        totalCompressedSize += compressedSize;

        compressedFiles.add(PlatformFile(
          name: platformFile.name,
          path: compressedFile.path,
          size: compressedSize,
          bytes: platformFile.bytes,
        ));
      }

      if (kDebugMode) {
        final totalSavings = totalOriginalSize - totalCompressedSize;
        final totalCompressionRatio = totalOriginalSize > 0
            ? (totalSavings / totalOriginalSize * 100)
            : 0.0;
        debugPrint('✅ [BATCH COMPRESSION] Selesai:');
        debugPrint(
            '   📊 Total ukuran asli: ${formatFileSize(totalOriginalSize)}');
        debugPrint(
            '   📊 Total ukuran hasil: ${formatFileSize(totalCompressedSize)}');
        debugPrint(
            '   💾 Total penghematan: ${formatFileSize(totalSavings)} (${totalCompressionRatio.toStringAsFixed(1)}%)');
      }

      return compressedFiles;
    }
  }

  /// Kompres file gambar tunggal
  Future<File?> _compressImageFile(
    File file, {
    required double maxSizeInMB,
    int? compressionQuality,
    bool showProgress = true,
    BuildContext? context,
  }) async {
    // Log info sebelum kompresi gambar
    final originalSize = await file.length();
    final originalSizeMB = originalSize / (1024 * 1024);
    final fileName = file.path.split('/').last;

    if (kDebugMode) {
      debugPrint('🖼️ [IMAGE COMPRESSION] Memulai kompresi gambar:');
      debugPrint('   📁 Nama: $fileName');
      debugPrint(
          '   📊 Ukuran asli: ${formatFileSize(originalSize)} (${originalSizeMB.toStringAsFixed(2)} MB)');
      debugPrint('   🎯 Target maksimal: ${maxSizeInMB.toStringAsFixed(2)} MB');
      debugPrint('   🔧 Kualitas: ${compressionQuality ?? "Auto"}');
    }

    if (showProgress && context != null) {
      if (!context.mounted) return null;
      return await _showCompressionDialog<File>(
        context: context,
        compressionTask: () async {
          final compressedFile = await FileCompressionUtils.compressFile(
            file: file,
            maxSizeInMB: maxSizeInMB,
            customQuality: compressionQuality,
          );

          // Log hasil kompresi gambar
          final compressedSize = await compressedFile.length();
          final compressedSizeMB = compressedSize / (1024 * 1024);
          final compressionRatio =
              ((originalSize - compressedSize) / originalSize * 100);
          final sizeDifference = originalSize - compressedSize;

          if (kDebugMode) {
            debugPrint('✅ [IMAGE COMPRESSION] Kompresi gambar selesai:');
            debugPrint(
                '   📊 Ukuran hasil: ${formatFileSize(compressedSize)} (${compressedSizeMB.toStringAsFixed(2)} MB)');
            debugPrint(
                '   💾 Penghematan: ${formatFileSize(sizeDifference)} (${compressionRatio.toStringAsFixed(1)}%)');
            debugPrint('   📍 Path: ${compressedFile.path}');
            if (compressedSize == originalSize) {
              debugPrint(
                  '   ℹ️  Gambar tidak dikompres (sudah optimal atau format tidak didukung)');
            }
          }

          return compressedFile;
        },
        message: 'Mengkompres gambar...',
      );
    } else {
      final compressedFile = await FileCompressionUtils.compressFile(
        file: file,
        maxSizeInMB: maxSizeInMB,
        customQuality: compressionQuality,
      );

      // Log hasil kompresi untuk mode tanpa dialog
      final compressedSize = await compressedFile.length();
      final compressedSizeMB = compressedSize / (1024 * 1024);
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100);
      final sizeDifference = originalSize - compressedSize;

      if (kDebugMode) {
        debugPrint('✅ [IMAGE COMPRESSION] Kompresi gambar selesai:');
        debugPrint(
            '   📊 Ukuran hasil: ${formatFileSize(compressedSize)} (${compressedSizeMB.toStringAsFixed(2)} MB)');
        debugPrint(
            '   💾 Penghematan: ${formatFileSize(sizeDifference)} (${compressionRatio.toStringAsFixed(1)}%)');
        debugPrint('   📍 Path: ${compressedFile.path}');
        if (compressedSize == originalSize) {
          debugPrint(
              '   ℹ️  Gambar tidak dikompres (sudah optimal atau format tidak didukung)');
        }
      }

      return compressedFile;
    }
  }

  /// Kompres multiple file gambar
  Future<List<File>> _compressMultipleImageFiles(
    List<File> files, {
    required double maxSizeInMB,
    int? compressionQuality,
    bool showProgress = true,
    BuildContext? context,
  }) async {
    if (showProgress && context != null) {
      return await _showCompressionDialog<List<File>>(
            context: context,
            compressionTask: () async {
              return await FileCompressionUtils.compressMultipleFiles(
                files: files,
                maxSizeInMB: maxSizeInMB,
                customQuality: compressionQuality,
              );
            },
            message: 'Mengkompres ${files.length} gambar...',
          ) ??
          [];
    } else {
      return await FileCompressionUtils.compressMultipleFiles(
        files: files,
        maxSizeInMB: maxSizeInMB,
        customQuality: compressionQuality,
      );
    }
  }

  /// Tampilkan dialog progress saat kompresi
  Future<R?> _showCompressionDialog<R>({
    required BuildContext context,
    required Future<R> Function() compressionTask,
    required String message,
  }) async {
    R? result;

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      setState(() {
        _isCompressing = true;
      });

      // Jalankan kompresi
      result = await compressionTask();

      // Tampilkan snackbar sukses
      if (context.mounted) {
        _showSuccessSnackBar('File berhasil dikompres!', context);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Compression error: $e');
      }

      // Tampilkan error
      if (context.mounted) {
        _showErrorSnackBar('Error saat kompresi: $e', context);
      }

      if (kDebugMode) {
        debugPrint('Compression error: $e');
      }
    } finally {
      // Tutup dialog loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isCompressing = false;
      });
    }

    return result;
  }

  /// Tampilkan snackbar error
  void _showErrorSnackBar(String message, BuildContext? context) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Tampilkan snackbar sukses
  void _showSuccessSnackBar(String message, BuildContext? context) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Utilitas untuk mengecek apakah file perlu dikompres
  Future<bool> needsCompression(File file, {double maxSizeInMB = 2.0}) async {
    final sizeInMB = await FileCompressionUtils.getFileSizeInMB(file);
    return sizeInMB > maxSizeInMB &&
        FileCompressionUtils.isCompressionSupported(file.path);
  }

  /// Utilitas untuk format ukuran file
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
