import 'package:eschool_saas_staff/models/contact.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';

class ContactRepository {
  // Submit contact (public API - no authentication required)
  Future<Contact> submitContact(SubmitContactRequest request) async {
    try {
      final response = await Api.postJson(
        url: Api.submitContact,
        body: request.toJson(),
        useAuthToken: false, // Public API
      );

      // 🔴 UBAH DISINI: Sesuaikan dengan key 'success' dari Laravel
      if (response['success'] == true && response['data'] != null) {
        return Contact.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to submit contact');
      }
    } catch (e) {
      throw Exception('Failed to submit contact: $e');
    }
  }

  // Get contacts list (authenticated)
  Future<Map<String, dynamic>> getContacts({
    String? type,
    String? status,
    int? perPage,
    int? page,
    String? search,
    String? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'with_replies': 'true', // Request replies data
      };

      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (page != null) queryParams['page'] = page;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

      final response = await Api.get(
        url: Api.getContacts,
        queryParameters: queryParams,
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI: Ini biang kerok eror log baris 69 kamu kemarin!
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Parse contacts list
        final contacts = (data['data'] as List?)
                ?.map((contact) => Contact.fromJson(contact))
                .toList() ??
            [];

        return {
          'contacts': contacts,
          'currentPage': data['current_page'] ?? 1,
          'perPage': data['per_page'] ?? 15,
          'total': data['total'] ?? 0,
          'lastPage': data['last_page'] ?? 1,
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch contacts');
      }
    } catch (e, st) {
      AppLogger.error('ContactRepository.getContacts', 'Exception',
          error: e, stack: st);
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  // Get contact detail (authenticated)
  Future<Contact> getContactDetail(int contactId) async {
    try {
      final response = await Api.get(
        url: '${Api.getContactDetail}/$contactId',
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI
      if (response['success'] == true && response['data'] != null) {
        return Contact.fromJson(response['data']);
      } else {
        throw Exception(
            response['message'] ?? 'Failed to fetch contact detail');
      }
    } catch (e) {
      throw Exception('Failed to fetch contact detail: $e');
    }
  }

  // Reply to contact (staff only)
  Future<Contact> replyToContact(int contactId, String reply) async {
    try {
      final response = await Api.postJson(
        url: '${Api.replyContact}/$contactId/reply',
        body: {'reply': reply},
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI
      if (response['success'] == true && response['data'] != null) {
        return Contact.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to send reply');
      }
    } catch (e) {
      throw Exception('Failed to send reply: $e');
    }
  }

  // Get contact statistics (admin only)
  Future<ContactStats> getContactStats() async {
    try {
      final response = await Api.get(
        url: Api.getContactStats,
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI
      if (response['success'] == true && response['data'] != null) {
        return ContactStats.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch contact stats');
      }
    } catch (e, st) {
      AppLogger.error('ContactRepository.getContactStats', 'Exception',
          error: e, stack: st);
      throw Exception('Failed to fetch contact stats: $e');
    }
  }

  // Update contact status (admin only)
  Future<Contact> updateContactStatus(int contactId, String status) async {
    try {
      final response = await Api.put(
        url: '${Api.getContactDetail}/$contactId',
        body: {'status': status},
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI
      if (response['success'] == true && response['data'] != null) {
        return Contact.fromJson(response['data']);
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update contact status');
      }
    } catch (e) {
      throw Exception('Failed to update contact status: $e');
    }
  }

  // Delete contact (admin only)
  Future<void> deleteContact(int contactId) async {
    try {
      final response = await Api.delete(
        url: '${Api.getContactDetail}/$contactId',
        body: {},
        useAuthToken: true,
      );

      // 🔴 UBAH DISINI: Jika sukses mengembalikan 'success': true, maka lempar error jika false
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Failed to delete contact');
      }
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }
}