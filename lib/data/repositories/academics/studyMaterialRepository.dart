import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/foundation.dart';

class StudyMaterialRepository {
  Future<void> deleteStudyMaterial({required int fileId}) async {
    try {
      await Api.post(
        body: {
          "file_id": fileId,
        },
        url: Api.deleteStudyMaterial,
        useAuthToken: true,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<StudyMaterial> updateStudyMaterial({
    required int fileId,
    required Map<String, dynamic> fileDetails,
  }) async {
    try {
      Map<String, dynamic> body = {
        "file_id": fileId,
      };
      body.addAll(fileDetails);

      final result = await Api.post(
        body: body,
        url: Api.updateStudyMaterial,
        useAuthToken: true,
      );

      return StudyMaterial.fromJson(Map.from(result['data']));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> downloadStudyMaterialFile({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    required Function updateDownloadedPercentage,
  }) async {
    try {
      // Jika URL sudah lengkap (dimulai dengan http), gunakan langsung.
      // Jika belum, baru tambahkan storageUrl.
      String finalUrl = url;
      if (!url.startsWith('http')) {
        finalUrl = storageUrl + url;
      } else {
        // Kasus spesial: Kadang URL yang datang sudah absolut tapi entah kenapa
        // terbungkus lagi oleh storageUrl di level pemanggil (seperti di log user).
        // Kita bersihkan jika ada pola 'storage//http'
        if (url.contains('/storage//http')) {
          finalUrl = url.split('/storage//').last;
        } else if (url.contains('/storage/http')) {
          finalUrl = url.split('/storage/').last;
        }
      }

      await Api.download(
        cancelToken: cancelToken,
        url: finalUrl,
        savePath: savePath,
        updateDownloadedPercentage: updateDownloadedPercentage,
      );
      debugPrint("OK GA ERROR");
    } catch (e) {
      debugPrint("OK ERROR");
      debugPrint(e.toString());
      throw ApiException(e.toString());
    }
  }
}
