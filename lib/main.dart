import 'dart:convert';

import 'package:eschool_saas_staff/app/app.dart';
import 'package:eschool_saas_staff/data/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

///[V.1.4.1] - Staff App Version
///
///

Future<void> main() async {
  timeago.setLocaleMessages('id', timeago.IdMessages());
  await initializeDateFormatting('id');
  Encoding.getByName('utf-8');

  await initializeApp();

  // Setup FCM notification listener via Service
  await NotificationService.instance.init();

  // --- DEBUG TOKEN ---
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('=========================================');
    debugPrint('📍 TOKEN HP GURU (Copy ini):');
    debugPrint(token ?? 'Gagal ambil token');
    debugPrint('=========================================');
  } catch (e) {
    debugPrint('❌ Error ambil token: $e');
  }
  // ------------------
}
