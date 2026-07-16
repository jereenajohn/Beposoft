import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffMailPage extends StatefulWidget {
  const StaffMailPage({super.key});

  @override
  State<StaffMailPage> createState() => _StaffMailPageState();
}

class _StaffMailPageState extends State<StaffMailPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController staffSearchController = TextEditingController();
  final TextEditingController mailSearchController = TextEditingController();
  final TextEditingController replySearchController = TextEditingController();
  final TextEditingController replyMessageController = TextEditingController();

  static const int maxFileSize = 1024 * 1024;

  List<dynamic> staffs = [];
  List<Map<String, dynamic>> selectedStaffs = [];
  List<Map<String, dynamic>> selectedCcStaffs = [];
  List<Map<String, dynamic>> selectedBccStaffs = [];
  List<Map<String, dynamic>> allRecipientStaffs = [];
  List<PlatformFile> selectedFiles = [];

  List<dynamic> inboxMails = [];
  List<dynamic> sentMails = [];

  bool isFetchingStaffs = false;
  bool isFetchingAllStaffs = false;
  bool allRecipientsSelected = false;
  bool isSending = false;
  bool isLoadingInbox = false;
  bool isLoadingSent = false;
  bool isDeleting = false;
  bool isUpdatingReadStatus = false;

  int unreadCount = 0;
  String readStatusFilter = '';

  dynamic selectedMail;
  List<dynamic> mailThread = [];
  List<dynamic> replyStaffs = [];
  List<Map<String, dynamic>> replyRecipientUsers = [];
  List<Map<String, dynamic>> replyCcRecipientUsers = [];
  List<Map<String, dynamic>> replyBccRecipientUsers = [];
  List<PlatformFile> replyDocuments = [];

  bool isLoadingMailDetail = false;
  bool isFetchingReplyStaffs = false;
  bool isSendingReply = false;
  bool allReplyRecipientsSelected = false;

  Timer? replySearchDebounce;

  int inboxPage = 1;
  int sentPage = 1;

  bool hasMoreInbox = true;
  bool hasMoreSent = true;

  Timer? staffDebounce;
  Timer? mailSearchDebounce;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    fetchMails(type: 'inbox', refresh: true);
    fetchMails(type: 'sent', refresh: true);
  }

  @override
  void dispose() {
    tabController.dispose();
    subjectController.dispose();
    messageController.dispose();
    staffSearchController.dispose();
    mailSearchController.dispose();
    replySearchController.dispose();
    replyMessageController.dispose();
    staffDebounce?.cancel();
    mailSearchDebounce?.cancel();
    replySearchDebounce?.cancel();
    super.dispose();
  }

  bool isReplyMail(dynamic mail) {
    if (mail is! Map) return false;

    final dynamic parentMail =
        mail['parent_mail'] ??
        mail['parent'] ??
        mail['reply_to'] ??
        mail['replied_to'] ??
        mail['original_mail'];

    if (parentMail != null) {
    if (parentMail is int && parentMail > 0) return true;

    if (parentMail is String &&
        parentMail.trim().isNotEmpty &&
        parentMail.trim() != '0') {
      return true;
    }

    if (parentMail is Map && parentMail.isNotEmpty) {
      return true;
    }
  }

    final String subject =
        (mail['subject'] ?? '').toString().trim().toLowerCase();

    return subject.startsWith('re:');
  }

  bool isUnreadMail(dynamic mail) {
    if (mail is! Map) return false;

    if (mail.containsKey('is_read')) {
    return mail['is_read'] != true;
  }

  if (mail.containsKey('read')) {
    return mail['read'] != true;
  }

  if (mail.containsKey('read_at')) {
    final dynamic readAt = mail['read_at'];

    return readAt == null || readAt.toString().trim().isEmpty;
  }

    return false;
  }

  String getMailDisplaySubject(dynamic mail) {
    final String subject =
        (mail['subject'] ?? '').toString().trim();

    if (subject.isEmpty) {
    return isReplyMail(mail) ? 'Reply message' : 'No subject';
  }

    return subject;
  }

  String formatDateTimeIndian(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$day-$month-$year  $hour:$minute $amPm';
    } catch (_) {
      return value;
    }
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> jsonHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri buildUri(String path, Map<String, String> query) {
    return Uri.parse('$api/$path').replace(queryParameters: query);
  }

  void showMsg(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<dynamic> extractStaffData(dynamic decoded) {
    final dynamic possibleData =
        decoded?['results']?['data'] ??
        decoded?['data']?['data'] ??
        decoded?['results'] ??
        decoded?['data'];

    return possibleData is List ? possibleData : <dynamic>[];
  }

  String? extractNextPageUrl(dynamic decoded) {
    final dynamic next =
        decoded?['next'] ??
        decoded?['results']?['next'] ??
        decoded?['links']?['next'];

    final String? value = next?.toString();

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  int? extractStaffTotalCount(dynamic decoded) {
    final dynamic rawCount =
        decoded?['count'] ??
        decoded?['results']?['count'] ??
        decoded?['total'] ??
        decoded?['results']?['total'];

    if (rawCount == null) return null;

    return rawCount is int
        ? rawCount
        : int.tryParse(rawCount.toString());
  }

  Future<void> fetchStaffs([String search = '']) async {
    if (isFetchingStaffs) return;

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        showMsg('Token missing');
        return;
      }

      if (mounted) {
        setState(() {
          isFetchingStaffs = true;
        });
      }

      final Uri uri = buildUri(
        'api/get/staffs/',
        {
          'page': '1',
          'search': search.trim(),
          'approval_status': 'approved',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Staff API failed with ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> receivedStaffs = extractStaffData(decoded);

      final List<Map<String, dynamic>> validStaffs = [];

      for (final dynamic staff in receivedStaffs) {
        final Map<String, dynamic>? normalized = normalizeRecipient(staff);

        if (normalized != null) {
          validStaffs.add(normalized);
        }
      }

      if (!mounted) return;

      setState(() {
        staffs = validStaffs;
      });
    } catch (e) {
      debugPrint('FETCH STAFF ERROR: $e');
      showMsg('Error fetching staffs');
    } finally {
      if (mounted) {
        setState(() {
          isFetchingStaffs = false;
        });
      }
    }
  }

  Future<void> fetchMails({
    required String type,
    bool refresh = false,
  }) async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        showMsg('Token missing');
        return;
      }

      final bool isInbox = type == 'inbox';

      if (refresh) {
        if (isInbox) {
          inboxPage = 1;
          hasMoreInbox = true;
        } else {
          sentPage = 1;
          hasMoreSent = true;
        }
      }

      if (isInbox) {
        if (isLoadingInbox || !hasMoreInbox) return;
        setState(() => isLoadingInbox = true);
      } else {
        if (isLoadingSent || !hasMoreSent) return;
        setState(() => isLoadingSent = true);
      }

      final currentPage = isInbox ? inboxPage : sentPage;

      final Map<String, String> query = {
        'type': type,
        'search': mailSearchController.text.trim(),
        'page': currentPage.toString(),
      };

      if (isInbox && readStatusFilter.isNotEmpty) {
        query['read_status'] = readStatusFilter;
      }

      final response = await http.get(
        buildUri('api/internal/mails/', query),
        headers: jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Mail API failed with ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      if (!mounted) return;

      dynamic rawData;
      dynamic rawUnreadCount = 0;
      dynamic rawNext;

      if (decoded is Map) {
        final dynamic results = decoded['results'];
        final dynamic rootData = decoded['data'];

        if (results is Map) {
          rawData = results['data'];
          rawUnreadCount =
              results['unread_count'] ?? decoded['unread_count'] ?? 0;
          rawNext = results['next'] ?? decoded['next'];
        } else if (results is List) {
          rawData = results;
          rawUnreadCount = decoded['unread_count'] ?? 0;
          rawNext = decoded['next'];
        } else if (rootData is Map && rootData['data'] is List) {
          rawData = rootData['data'];
          rawUnreadCount =
              rootData['unread_count'] ?? decoded['unread_count'] ?? 0;
          rawNext = rootData['next'] ?? decoded['next'];
        } else {
          rawData = rootData;
          rawUnreadCount = decoded['unread_count'] ?? 0;
          rawNext = decoded['next'];
        }

        if (rawNext == null && decoded['links'] is Map) {
          rawNext = decoded['links']['next'];
        }
      } else if (decoded is List) {
        rawData = decoded;
      }

      final List<dynamic> data =
          rawData is List ? List<dynamic>.from(rawData) : <dynamic>[];
      final bool hasNext = rawNext != null;
      final int responseUnreadCount =
          int.tryParse(rawUnreadCount.toString()) ?? 0;

      setState(() {
        if (isInbox) {
          inboxMails = refresh ? data : [...inboxMails, ...data];
          unreadCount = responseUnreadCount;
          inboxPage++;
          hasMoreInbox = hasNext;
        } else {
          sentMails = refresh ? data : [...sentMails, ...data];
          sentPage++;
          hasMoreSent = hasNext;
        }
      });
    } catch (_) {
      showMsg('Error fetching mails');
    } finally {
      if (!mounted) return;

      setState(() {
        if (type == 'inbox') {
          isLoadingInbox = false;
        } else {
          isLoadingSent = false;
        }
      });
    }
  }

  int getSelectedFilesTotalSize() {
    return selectedFiles.fold<int>(
      0,
      (total, file) => total + file.size,
    );
  }

  void showMaxUploadSizePopup() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload limit exceeded'),
        content: const Text(
          'Maximum 1 MB can be uploaded in total. Please remove some files and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> sendMail() async {
    if (isSending) return;

    if (selectedStaffs.isEmpty &&
        selectedCcStaffs.isEmpty &&
        selectedBccStaffs.isEmpty) {
      showMsg('Select at least one To, CC or BCC recipient');
      return;
    }

    if (subjectController.text.trim().isEmpty) {
      showMsg('Subject is required');
      return;
    }

    if (messageController.text.trim().isEmpty && selectedFiles.isEmpty) {
      showMsg('Message or file is required');
      return;
    }

    if (getSelectedFilesTotalSize() > maxFileSize) {
      showMaxUploadSizePopup();
      return;
    }

    try {
      if (mounted) {
        setState(() => isSending = true);
      }

      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        showMsg('Token missing');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$api/api/internal/mails/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['subject'] = subjectController.text.trim();
      request.fields['message'] = messageController.text.trim();

      final Set<int> toIds = selectedStaffs
          .map(getRecipientId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      final Set<int> ccIds = selectedCcStaffs
          .map(getRecipientId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      final Set<int> bccIds = selectedBccStaffs
          .map(getRecipientId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();

      if (toIds.isEmpty && ccIds.isEmpty && bccIds.isEmpty) {
        showMsg('No valid recipients selected');
        return;
      }

      for (final int recipientId in toIds) {
        request.files.add(http.MultipartFile.fromString(
          'recipients', recipientId.toString()));
      }
      for (final int recipientId in ccIds) {
        request.files.add(http.MultipartFile.fromString(
          'cc_recipients', recipientId.toString()));
      }
      for (final int recipientId in bccIds) {
        request.files.add(http.MultipartFile.fromString(
          'bcc_recipients', recipientId.toString()));
      }

      for (final file in selectedFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'documents',
              file.path!,
              filename: file.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (!mounted) return;

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        showMsg('Mail sent successfully', success: true);

        setState(() {
          selectedStaffs.clear();
          selectedCcStaffs.clear();
          selectedBccStaffs.clear();
          selectedFiles.clear();
          subjectController.clear();
          messageController.clear();
          allRecipientsSelected = false;
        });

        await fetchMails(type: 'sent', refresh: true);
        await fetchMails(type: 'inbox', refresh: true);

        tabController.animateTo(1);
      } else {
        String message = 'Failed to send mail';

        try {
          final decoded = jsonDecode(responseBody);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        showMsg(message);
      }
    } catch (e) {
      showMsg('Something went wrong while sending mail');
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  Future<void> deleteMail(dynamic mail, String type) async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        showMsg('Token missing');
        return;
      }

      setState(() => isDeleting = true);

      final response = await http.delete(
        Uri.parse('$api/api/internal/mails/${mail['id']}/'),
        headers: jsonHeaders(token),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        showMsg(decoded['message'] ?? 'Mail deleted', success: true);
        fetchMails(type: type, refresh: true);
      } else {
        showMsg(decoded['message'] ?? 'Failed to delete mail');
      }
    } catch (_) {
      showMsg('Delete failed');
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );

    if (result == null) return;

    final currentTotalSize = getSelectedFilesTotalSize();
    final pickedTotalSize = result.files.fold<int>(
      0,
      (total, file) => total + file.size,
    );

    if (currentTotalSize + pickedTotalSize > maxFileSize) {
      showMaxUploadSizePopup();
      return;
    }

    setState(() {
      selectedFiles.addAll(result.files);
    });
  }

  String staffName(dynamic staff) {
    return staff['name']?.toString() ??
        staff['user_name']?.toString() ??
        staff['staff_name']?.toString() ??
        staff['username']?.toString() ??
        'Unknown';
  }

  String staffEmail(dynamic staff) {
    return 'mexpo.org';
  }

  int? getRecipientId(dynamic staff) {
    final dynamic rawId =
        staff?['user_id'] ??
        staff?['user']?['id'] ??
        staff?['recipient_id'] ??
        staff?['id'];

    if (rawId == null) return null;

    final int? parsedId =
        rawId is int ? rawId : int.tryParse(rawId.toString());

    if (parsedId == null || parsedId <= 0) {
      return null;
    }

    return parsedId;
  }

  bool isApprovedRecipient(dynamic staff) {
    final dynamic approvalStatus = staff?['approval_status'];

    if (approvalStatus == null) {
      return true;
    }

    return approvalStatus.toString().trim().toLowerCase() == 'approved';
  }

  Map<String, dynamic>? normalizeRecipient(dynamic staff) {
    if (staff is! Map) return null;

    final int? recipientId = getRecipientId(staff);

    if (recipientId == null || !isApprovedRecipient(staff)) {
      return null;
    }

    final Map<String, dynamic> normalized =
        Map<String, dynamic>.from(staff);

    normalized['recipient_id'] = recipientId;

    return normalized;
  }

  bool isStaffSelected(dynamic staff) {
    final int? recipientId = getRecipientId(staff);

    if (recipientId == null) return false;

    return selectedStaffs.any(
      (selected) => getRecipientId(selected) == recipientId,
    );
  }

  void toggleStaff(dynamic staff) {
    final Map<String, dynamic>? normalized = normalizeRecipient(staff);

    if (normalized == null) {
      showMsg('This staff does not have a valid approved user account');
      return;
    }

    final int recipientId = normalized['recipient_id'] as int;

    setState(() {
      final bool alreadySelected = selectedStaffs.any(
        (selected) => getRecipientId(selected) == recipientId,
      );

      if (alreadySelected) {
        selectedStaffs.removeWhere(
          (selected) => getRecipientId(selected) == recipientId,
        );
      } else {
        selectedCcStaffs.removeWhere(
          (selected) => getRecipientId(selected) == recipientId,
        );
        selectedBccStaffs.removeWhere(
          (selected) => getRecipientId(selected) == recipientId,
        );
        selectedStaffs.add(normalized);
      }

      allRecipientsSelected = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllRecipientStaffs() async {
    if (isFetchingAllStaffs) {
      return allRecipientStaffs;
    }

    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return [];
    }

    if (mounted) {
      setState(() {
        isFetchingAllStaffs = true;
      });
    }

    try {
      int page = 1;
      bool hasMorePages = true;

      final List<Map<String, dynamic>> completeList = [];
      final Set<String> fetchedPageSignatures = {};

      while (hasMorePages) {
        final Uri uri = buildUri(
          'api/get/staffs/',
          {
            'page': page.toString(),
            'approval_status': 'approved',
          },
        );

        debugPrint('FETCH ALL STAFF PAGE $page: $uri');

        final http.Response response = await http.get(
          uri,
          headers: jsonHeaders(token),
        );

        if (response.statusCode != 200) {
          throw Exception(
            'Unable to fetch staff page $page: ${response.statusCode}',
          );
        }

        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> currentPage = extractStaffData(decoded);
        final String? nextPageUrl = extractNextPageUrl(decoded);
        final int? totalCount = extractStaffTotalCount(decoded);

        final List<Map<String, dynamic>> validPageUsers = [];

        for (final dynamic staff in currentPage) {
          final Map<String, dynamic>? normalized = normalizeRecipient(staff);

          if (normalized != null) {
            validPageUsers.add(normalized);
          }
        }

        final List<int> pageIds = validPageUsers
            .map(getRecipientId)
            .whereType<int>()
            .toList()
          ..sort();

        final String pageSignature = pageIds.join(',');

        if (pageSignature.isNotEmpty &&
            fetchedPageSignatures.contains(pageSignature)) {
          debugPrint(
            'Pagination stopped because page $page returned duplicate records.',
          );
          break;
        }

        if (pageSignature.isNotEmpty) {
          fetchedPageSignatures.add(pageSignature);
        }

        completeList.addAll(validPageUsers);

        if (nextPageUrl != null) {
          page++;
          continue;
        }

        if (totalCount != null &&
            completeList.length < totalCount &&
            currentPage.isNotEmpty) {
          page++;
          continue;
        }

        hasMorePages = false;
      }

      final Map<int, Map<String, dynamic>> uniqueRecipients = {};

      for (final Map<String, dynamic> staff in completeList) {
        final int? recipientId = getRecipientId(staff);

        if (recipientId != null) {
          uniqueRecipients[recipientId] = staff;
        }
      }

      final List<Map<String, dynamic>> result =
          uniqueRecipients.values.toList();

      result.sort(
        (a, b) => staffName(a)
            .toLowerCase()
            .compareTo(staffName(b).toLowerCase()),
      );

      if (mounted) {
        setState(() {
          allRecipientStaffs = result;
        });
      }

      return result;
    } catch (e) {
      debugPrint('FETCH ALL RECIPIENTS ERROR: $e');
      showMsg('Failed to fetch all recipients');
      return [];
    } finally {
      if (mounted) {
        setState(() {
          isFetchingAllStaffs = false;
        });
      }
    }
  }

  Future<void> selectAllRecipients() async {
    List<Map<String, dynamic>> completeList = allRecipientStaffs;

    if (completeList.isEmpty) {
      completeList = await fetchAllRecipientStaffs();
    }

    if (completeList.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    final Map<int, Map<String, dynamic>> uniqueRecipients = {};

    for (final Map<String, dynamic> staff in completeList) {
      final int? recipientId = getRecipientId(staff);

      final excludedIds = {
        ...selectedCcStaffs.map(getRecipientId).whereType<int>(),
        ...selectedBccStaffs.map(getRecipientId).whereType<int>(),
      };

      if (recipientId != null &&
          isApprovedRecipient(staff) &&
          !excludedIds.contains(recipientId)) {
        uniqueRecipients[recipientId] = staff;
      }
    }

    if (uniqueRecipients.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    if (!mounted) return;

    setState(() {
      selectedStaffs = uniqueRecipients.values.toList();
      allRecipientsSelected = true;
      staffSearchController.clear();
    });

    showMsg(
      '${selectedStaffs.length} approved recipients selected',
      success: true,
    );
  }

  void clearAllRecipients() {
    setState(() {
      selectedStaffs.clear();
      allRecipientsSelected = false;
      staffSearchController.clear();
    });
  }

  Set<int> _composeExcludedIdsFor(String type) {
    final Set<int> excluded = {};

    if (type != 'to') {
      excluded.addAll(
        selectedStaffs.map(getRecipientId).whereType<int>(),
      );
    }

    if (type != 'cc') {
      excluded.addAll(
        selectedCcStaffs.map(getRecipientId).whereType<int>(),
      );
    }

    if (type != 'bcc') {
      excluded.addAll(
        selectedBccStaffs.map(getRecipientId).whereType<int>(),
      );
    }

    return excluded;
  }

  Future<List<Map<String, dynamic>>> _eligibleComposeRecipients(
    String type,
  ) async {
    List<Map<String, dynamic>> completeList = allRecipientStaffs;

    if (completeList.isEmpty) {
      completeList = await fetchAllRecipientStaffs();
    }

    final Set<int> excludedIds = _composeExcludedIdsFor(type);
    final Map<int, Map<String, dynamic>> uniqueRecipients = {};

    for (final Map<String, dynamic> staff in completeList) {
      final int? recipientId = getRecipientId(staff);

      if (recipientId != null &&
          recipientId > 0 &&
          isApprovedRecipient(staff) &&
          !excludedIds.contains(recipientId)) {
        uniqueRecipients[recipientId] = staff;
      }
    }

    return uniqueRecipients.values.toList();
  }

  Future<void> selectAllComposeRecipientsFor(String type) async {
    final List<Map<String, dynamic>> eligible =
        await _eligibleComposeRecipients(type);

    if (eligible.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    if (!mounted) return;

    setState(() {
      final List<Map<String, dynamic>> target = _composeListFor(type);
      target
        ..clear()
        ..addAll(eligible);

      allRecipientsSelected = type == 'to';
      staffSearchController.clear();
    });

    showMsg(
      '${eligible.length} ${_recipientLabel(type)} recipients selected',
      success: true,
    );
  }

  void clearAllComposeRecipientsFor(String type) {
    setState(() {
      _composeListFor(type).clear();

      if (type == 'to') {
        allRecipientsSelected = false;
      }

      staffSearchController.clear();
    });
  }

  bool areAllComposeRecipientsSelected(
    String type,
    List<Map<String, dynamic>> eligible,
  ) {
    if (eligible.isEmpty) return false;

    final Set<int> eligibleIds =
        eligible.map(getRecipientId).whereType<int>().toSet();

    final Set<int> selectedIds =
        _composeListFor(type).map(getRecipientId).whereType<int>().toSet();

    return eligibleIds.isNotEmpty && selectedIds.containsAll(eligibleIds);
  }

  Set<int> get composeRecipientIds => {
        ...selectedStaffs.map(getRecipientId).whereType<int>(),
        ...selectedCcStaffs.map(getRecipientId).whereType<int>(),
        ...selectedBccStaffs.map(getRecipientId).whereType<int>(),
      };

  Set<int> get replyAllRecipientIds => {
        ...replyRecipientUsers.map(getRecipientId).whereType<int>(),
        ...replyCcRecipientUsers.map(getRecipientId).whereType<int>(),
        ...replyBccRecipientUsers.map(getRecipientId).whereType<int>(),
      };

  List<Map<String, dynamic>> _composeListFor(String type) {
    switch (type) {
      case 'cc':
        return selectedCcStaffs;
      case 'bcc':
        return selectedBccStaffs;
      default:
        return selectedStaffs;
    }
  }

  List<Map<String, dynamic>> _replyListFor(String type) {
    switch (type) {
      case 'cc':
        return replyCcRecipientUsers;
      case 'bcc':
        return replyBccRecipientUsers;
      default:
        return replyRecipientUsers;
    }
  }

  String _recipientLabel(String type) {
    switch (type) {
      case 'cc':
        return 'CC';
      case 'bcc':
        return 'BCC';
      default:
        return 'To';
    }
  }

  Future<void> openComposeRecipientSelector(String type) async {
    List<Map<String, dynamic>> visible = [];
    List<Map<String, dynamic>> eligibleAll = [];
    bool loading = true;
    bool sheetActive = true;
    bool initialLoadStarted = false;
    Timer? localDebounce;

    Future<void> load(
      String search,
      StateSetter modalSetState,
      BuildContext modalContext,
    ) async {
      if (!sheetActive) return;

      await fetchStaffs(search);

      if (!sheetActive || !mounted || !modalContext.mounted) return;

      eligibleAll = await _eligibleComposeRecipients(type);

      if (!sheetActive || !mounted || !modalContext.mounted) return;

      visible = staffs
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((user) {
            final int? id = getRecipientId(user);
            final Set<int> currentGroupIds = _composeListFor(type)
                .map(getRecipientId)
                .whereType<int>()
                .toSet();

            return id != null &&
                (!composeRecipientIds.contains(id) ||
                    currentGroupIds.contains(id));
          })
          .toList();

      loading = false;

      if (sheetActive && modalContext.mounted) {
        modalSetState(() {});
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            if (!initialLoadStarted) {
              initialLoadStarted = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetActive && modalContext.mounted) {
                  load('', modalSetState, modalContext);
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: .88,
              minChildSize: .5,
              maxChildSize: .96,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select ${_recipientLabel(type)} recipients',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          decoration: inputDecoration(
                            hint: 'Search staff',
                            icon: Icons.search_rounded,
                          ),
                          onChanged: (value) {
                            localDebounce?.cancel();
                            localDebounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (sheetActive && modalContext.mounted) {
                                  load(
                                    value.trim(),
                                    modalSetState,
                                    modalContext,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Builder(
                          builder: (_) {
                            final bool allSelected =
                                areAllComposeRecipientsSelected(
                              type,
                              eligibleAll,
                            );

                            return InkWell(
                              onTap: isFetchingAllStaffs
                                  ? null
                                  : () async {
                                      if (allSelected) {
                                        clearAllComposeRecipientsFor(type);
                                      } else {
                                        await selectAllComposeRecipientsFor(
                                          type,
                                        );
                                      }

                                      eligibleAll =
                                          await _eligibleComposeRecipients(
                                        type,
                                      );

                                      if (modalContext.mounted) {
                                        modalSetState(() {});
                                      }
                                    },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: allSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: allSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(
                                        child: isFetchingAllStaffs
                                            ? const SizedBox(
                                                width: 23,
                                                height: 23,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Checkbox(
                                                value: allSelected,
                                                activeColor:
                                                    const Color(0xFF2563EB),
                                                onChanged: (_) async {
                                                  if (allSelected) {
                                                    clearAllComposeRecipientsFor(
                                                      type,
                                                    );
                                                  } else {
                                                    await selectAllComposeRecipientsFor(
                                                      type,
                                                    );
                                                  }

                                                  eligibleAll =
                                                      await _eligibleComposeRecipients(
                                                    type,
                                                  );

                                                  if (modalContext.mounted) {
                                                    modalSetState(() {});
                                                  }
                                                },
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isFetchingAllStaffs
                                                ? 'Loading all staff...'
                                                : allSelected
                                                    ? 'Clear All'
                                                    : 'Select All',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isFetchingAllStaffs
                                                ? 'Fetching every staff page'
                                                : allSelected
                                                    ? 'All available ${_recipientLabel(type)} recipients selected'
                                                    : 'Select approved staff from all pages',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${_composeListFor(type).length} selected',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : visible.isEmpty
                                ? const Center(
                                    child: Text('No staff found'),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      100,
                                    ),
                                    itemCount: visible.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final Map<String, dynamic> user =
                                          visible[index];
                                      final int id = getRecipientId(user)!;
                                      final List<Map<String, dynamic>> list =
                                          _composeListFor(type);
                                      final bool selected = list.any(
                                        (e) => getRecipientId(e) == id,
                                      );

                                      return CheckboxListTile(
                                        value: selected,
                                        activeColor: const Color(0xFF2563EB),
                                        title: Text(
                                          staffName(user),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          user['department_name']
                                                  ?.toString() ??
                                              user['department']?.toString() ??
                                              'mexpo.org',
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        tileColor: selected
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF8FAFC),
                                        onChanged: (_) {
                                          if (!sheetActive ||
                                              !modalContext.mounted) {
                                            return;
                                          }

                                          setState(() {
                                            if (selected) {
                                              list.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                            } else {
                                              selectedStaffs.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              selectedCcStaffs.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              selectedBccStaffs.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              list.add(user);
                                            }

                                            allRecipientsSelected = false;
                                          });

                                          if (modalContext.mounted) {
                                            modalSetState(() {});
                                          }
                                        },
                                      );
                                    },
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: primaryButtonStyle(),
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(
                              'Done (${_composeListFor(type).length})',
                            ),
                          ),
                        ),
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

    sheetActive = false;
    localDebounce?.cancel();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openReplyGroupSelector(
    String type,
    VoidCallback refreshParent,
  ) async {
    List<Map<String, dynamic>> visible = [];
    List<Map<String, dynamic>> eligibleAll = [];
    bool loading = true;
    bool sheetActive = true;
    bool initialLoadStarted = false;
    Timer? localDebounce;

    Future<void> load(
      String search,
      StateSetter modalSetState,
      BuildContext modalContext,
    ) async {
      if (!sheetActive) return;

      await fetchReplySelectorStaffs(search);

      if (!sheetActive || !mounted || !modalContext.mounted) return;

      eligibleAll = await _eligibleReplyRecipients(type);

      if (!sheetActive || !mounted || !modalContext.mounted) return;

      visible = replyStaffs
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((user) {
            final int? id = getRecipientId(user);
            final Set<int> currentGroupIds = _replyListFor(type)
                .map(getRecipientId)
                .whereType<int>()
                .toSet();

            return id != null &&
                (!replyAllRecipientIds.contains(id) ||
                    currentGroupIds.contains(id));
          })
          .toList();

      loading = false;

      if (sheetActive && modalContext.mounted) {
        modalSetState(() {});
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            if (!initialLoadStarted) {
              initialLoadStarted = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetActive && modalContext.mounted) {
                  load('', modalSetState, modalContext);
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: .88,
              minChildSize: .5,
              maxChildSize: .96,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Reply ${_recipientLabel(type)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          decoration: inputDecoration(
                            hint: 'Search staff',
                            icon: Icons.search_rounded,
                          ),
                          onChanged: (value) {
                            localDebounce?.cancel();
                            localDebounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (sheetActive && modalContext.mounted) {
                                  load(
                                    value.trim(),
                                    modalSetState,
                                    modalContext,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Builder(
                          builder: (_) {
                            final bool allSelected =
                                areAllReplyRecipientsSelected(
                              type,
                              eligibleAll,
                            );

                            return InkWell(
                              onTap: isFetchingAllStaffs
                                  ? null
                                  : () async {
                                      if (allSelected) {
                                        clearAllReplyRecipientsFor(type);
                                      } else {
                                        await selectAllReplyRecipientsFor(
                                          type,
                                        );
                                      }

                                      eligibleAll =
                                          await _eligibleReplyRecipients(type);

                                      if (modalContext.mounted) {
                                        modalSetState(() {});
                                      }

                                      refreshParent();
                                    },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: allSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: allSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(
                                        child: isFetchingAllStaffs
                                            ? const SizedBox(
                                                width: 23,
                                                height: 23,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Checkbox(
                                                value: allSelected,
                                                activeColor:
                                                    const Color(0xFF2563EB),
                                                onChanged: (_) async {
                                                  if (allSelected) {
                                                    clearAllReplyRecipientsFor(
                                                      type,
                                                    );
                                                  } else {
                                                    await selectAllReplyRecipientsFor(
                                                      type,
                                                    );
                                                  }

                                                  eligibleAll =
                                                      await _eligibleReplyRecipients(
                                                    type,
                                                  );

                                                  if (modalContext.mounted) {
                                                    modalSetState(() {});
                                                  }

                                                  refreshParent();
                                                },
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isFetchingAllStaffs
                                                ? 'Loading all staff...'
                                                : allSelected
                                                    ? 'Clear All'
                                                    : 'Select All',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isFetchingAllStaffs
                                                ? 'Fetching every staff page'
                                                : allSelected
                                                    ? 'All available reply ${_recipientLabel(type)} recipients selected'
                                                    : 'Select approved staff from all pages',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${_replyListFor(type).length} selected',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : visible.isEmpty
                                ? const Center(
                                    child: Text('No staff found'),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      100,
                                    ),
                                    itemCount: visible.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final Map<String, dynamic> user =
                                          visible[index];
                                      final int id = getRecipientId(user)!;
                                      final List<Map<String, dynamic>> list =
                                          _replyListFor(type);
                                      final bool selected = list.any(
                                        (e) => getRecipientId(e) == id,
                                      );

                                      return CheckboxListTile(
                                        value: selected,
                                        activeColor: const Color(0xFF2563EB),
                                        title: Text(
                                          staffName(user),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          user['department_name']
                                                  ?.toString() ??
                                              user['department']?.toString() ??
                                              'mexpo.org',
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        tileColor: selected
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF8FAFC),
                                        onChanged: (_) {
                                          if (!sheetActive ||
                                              !modalContext.mounted) {
                                            return;
                                          }

                                          setState(() {
                                            if (selected) {
                                              list.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                            } else {
                                              replyRecipientUsers.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              replyCcRecipientUsers.removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              replyBccRecipientUsers
                                                  .removeWhere(
                                                (e) =>
                                                    getRecipientId(e) == id,
                                              );
                                              list.add(user);
                                            }
                                          });

                                          if (modalContext.mounted) {
                                            modalSetState(() {});
                                          }

                                          refreshParent();
                                        },
                                      );
                                    },
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: primaryButtonStyle(),
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(
                              'Done (${_replyListFor(type).length})',
                            ),
                          ),
                        ),
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

    sheetActive = false;
    localDebounce?.cancel();

    if (mounted) {
      refreshParent();
    }
  }

  Future<void> openStaffSelector() async {
    staffSearchController.clear();
    await fetchStaffs();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (sheetContext, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            18,
                            10,
                            14,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Select Recipients',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () {
                                  Navigator.pop(bottomSheetContext);
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: TextField(
                            controller: staffSearchController,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              modalSetState(() {});

                              staffDebounce?.cancel();
                              staffDebounce = Timer(
                                const Duration(milliseconds: 450),
                                () async {
                                  await fetchStaffs(value.trim());

                                  if (!mounted || !modalContext.mounted) {
                                    return;
                                  }

                                  modalSetState(() {});
                                },
                              );
                            },
                            decoration: inputDecoration(
                              hint: 'Search staff',
                              icon: Icons.search_rounded,
                            ).copyWith(
                              suffixIcon:
                                  staffSearchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () async {
                                            staffDebounce?.cancel();
                                            staffSearchController.clear();

                                            modalSetState(() {});

                                            await fetchStaffs();

                                            if (!mounted ||
                                                !modalContext.mounted) {
                                              return;
                                            }

                                            modalSetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: InkWell(
                            onTap: isFetchingAllStaffs
                                ? null
                                : () async {
                                    if (allRecipientsSelected) {
                                      clearAllRecipients();
                                    } else {
                                      await selectAllRecipients();
                                    }

                                    if (modalContext.mounted) {
                                      modalSetState(() {});
                                    }
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: allRecipientsSelected
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: allRecipientsSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: isFetchingAllStaffs
                                          ? const SizedBox(
                                              width: 23,
                                              height: 23,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Checkbox(
                                              value:
                                                  allRecipientsSelected,
                                              activeColor:
                                                  const Color(0xFF2563EB),
                                              onChanged: (_) async {
                                                if (allRecipientsSelected) {
                                                  clearAllRecipients();
                                                } else {
                                                  await selectAllRecipients();
                                                }

                                                if (modalContext.mounted) {
                                                  modalSetState(() {});
                                                }
                                              },
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFetchingAllStaffs
                                              ? 'Loading all staff...'
                                              : allRecipientsSelected
                                                  ? 'Clear All'
                                                  : 'Select All',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isFetchingAllStaffs
                                              ? 'Fetching every staff page'
                                              : allRecipientsSelected
                                                  ? 'All approved staff selected'
                                                  : 'Select approved staff from all pages',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${selectedStaffs.length} selected',
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: isFetchingStaffs
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : staffs.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_search_rounded,
                                              size: 48,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'No staff found',
                                              style: TextStyle(
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: scrollController,
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        4,
                                        18,
                                        110,
                                      ),
                                      itemCount: staffs.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (itemContext, index) {
                                        final dynamic staff = staffs[index];
                                        final bool selected =
                                            isStaffSelected(staff);

                                        return InkWell(
                                          onTap: () {
                                            toggleStaff(staff);
                                            modalSetState(() {});
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? const Color(0xFFEFF6FF)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: selected
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFFE2E8F0),
                                                width: selected ? 1.4 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: selected
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFFF1F5F9),
                                                  child: Icon(
                                                    selected
                                                        ? Icons.check_rounded
                                                        : Icons.person_rounded,
                                                    color: selected
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        staffName(staff),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      const Text(
                                                        'mexpo.org',
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFF64748B),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Checkbox(
                                                  value: selected,
                                                  activeColor:
                                                      const Color(0xFF2563EB),
                                                  onChanged: (_) {
                                                    toggleStaff(staff);
                                                    modalSetState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            12,
                            18,
                            18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(bottomSheetContext);
                              },
                              style: primaryButtonStyle(),
                              child: Text(
                                'Done (${selectedStaffs.length})',
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
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  InputDecoration inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
    );
  }

  ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String formatDate(String? value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  IconData fileIcon(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }

    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return Icons.table_chart_rounded;
    }

    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }

    if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
      return Icons.folder_zip_rounded;
    }

    return Icons.insert_drive_file_rounded;
  }

  String fileSizeText(int size) {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(size / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Internal Mail',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inbox'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sent'),
            const Tab(text: 'Compose'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          buildMailList(type: 'inbox'),
          buildMailList(type: 'sent'),
          buildComposePage(),
        ],
      ),
    );
  }

  Widget buildMailList({required String type}) {
    final mails = type == 'inbox' ? inboxMails : sentMails;
    final isLoading = type == 'inbox' ? isLoadingInbox : isLoadingSent;
    final hasMore = type == 'inbox' ? hasMoreInbox : hasMoreSent;

    return RefreshIndicator(
      onRefresh: () => fetchMails(type: type, refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 120 &&
              !isLoading &&
              hasMore) {
            fetchMails(type: type);
          }

          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: mailSearchController,
              onChanged: (_) {
                mailSearchDebounce?.cancel();
                mailSearchDebounce = Timer(
                  const Duration(milliseconds: 450),
                  () {
                    fetchMails(type: 'inbox', refresh: true);
                    fetchMails(type: 'sent', refresh: true);
                  },
                );
              },
              decoration: inputDecoration(
                hint: 'Search mails',
                icon: Icons.search_rounded,
              ),
            ),
            const SizedBox(height: 12),
            if (type == 'inbox') ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildReadFilterChip(label: 'All', value: ''),
                    const SizedBox(width: 8),
                    buildReadFilterChip(
                      label: unreadCount > 0
                          ? 'Unread ($unreadCount)'
                          : 'Unread',
                      value: 'unread',
                    ),
                    const SizedBox(width: 8),
                    buildReadFilterChip(label: 'Read', value: 'read'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 4),
            if (mails.isEmpty && isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mails.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: Text(
                    'No mails found',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              ...mails.map((mail) => buildMailCard(mail, type)),
            if (isLoading && mails.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildReadFilterChip({
    required String label,
    required String value,
  }) {
    final bool selected = readStatusFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        if (readStatusFilter == value) return;

        setState(() {
          readStatusFilter = value;
          inboxMails = [];
          inboxPage = 1;
          hasMoreInbox = true;
        });

        fetchMails(type: 'inbox', refresh: true);
      },
      selectedColor: const Color(0xFFDBEAFE),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFF2563EB)
            : const Color(0xFFE2E8F0),
      ),
      labelStyle: TextStyle(
        color: selected
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF475569),
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

 Widget buildMailCard(dynamic mail, String type) {
  final List attachments =
      mail['attachments'] as List? ?? [];

  final List recipients =
      mail['recipients_data'] as List? ?? [];

  final bool replyMail = isReplyMail(mail);
  final bool unread = type == 'inbox' && isUnreadMail(mail);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: unread
          ? const Color(0xFFEFF6FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: unread
            ? const Color(0xFF2563EB)
            : replyMail
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
        width: unread ? 1.4 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => openMailDetail(mail, type),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: replyMail
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFEFF6FF),
                  child: Icon(
                    replyMail
                        ? Icons.reply_rounded
                        : type == 'inbox'
                            ? Icons.inbox_rounded
                            : Icons.send_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),

                if (unread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (replyMail) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: unread
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFDBEAFE),
                            borderRadius:
                                BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread ? 'NEW REPLY' : 'REPLY',
                            style: TextStyle(
                              color: unread
                                  ? Colors.white
                                  : const Color(0xFF1D4ED8),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: Text(
                          getMailDisplaySubject(mail),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: unread
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    type == 'inbox'
                        ? 'From: ${mail['sender_name'] ?? 'Unknown'}'
                        : 'To: ${recipients.map(
                            (e) => e['name'] ?? '',
                          ).where(
                            (name) =>
                                name.toString().trim().isNotEmpty,
                          ).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontWeight: unread
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    (mail['message'] ?? '').toString().trim().isEmpty
                        ? 'No message'
                        : mail['message'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        replyMail
                            ? Icons.forum_outlined
                            : Icons.schedule_rounded,
                        size: 15,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          formatDateTimeIndian(
                            mail['created_at']?.toString(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if ((int.tryParse(mail['reply_count']?.toString() ?? '0') ?? 0) > 0) ...[
                        const Icon(
                          Icons.reply_all_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${mail['reply_count']}',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      if (attachments.isNotEmpty) ...[
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${attachments.length}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            IconButton(
              tooltip: 'Delete',
              onPressed: isDeleting
                  ? null
                  : () => confirmDelete(mail, type),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void confirmDelete(dynamic mail, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete mail?'),
        content: const Text('This mail will be removed from your mailbox.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteMail(mail, type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic rawId =
        prefs.getInt('user_id') ??
        prefs.getString('user_id') ??
        prefs.getInt('id') ??
        prefs.getString('id');

    if (rawId == null) return null;

    return rawId is int
        ? rawId
        : int.tryParse(rawId.toString());
  }

  void resetReplyForm() {
    replySearchDebounce?.cancel();
    replySearchController.clear();
    replyMessageController.clear();

    setState(() {
      replyStaffs = [];
      replyRecipientUsers = [];
      replyCcRecipientUsers = [];
      replyBccRecipientUsers = [];
      replyDocuments = [];
      allReplyRecipientsSelected = false;
    });
  }

  Future<void> prepareDefaultReplyRecipients(dynamic mailData) async {
    final int? currentUserId = await getCurrentUserId();

    final Map<int, Map<String, dynamic>> uniqueUsers = {};

    void addUser(dynamic rawUser) {
      if (rawUser is! Map) return;

      final Map<String, dynamic> user =
          Map<String, dynamic>.from(rawUser);

      final int? id = getRecipientId(user);

      if (id == null || id <= 0 || id == currentUserId) {
        return;
      }

      user['recipient_id'] = id;
      uniqueUsers[id] = user;
    }

    final dynamic senderId = mailData?['sender'];

    if (senderId != null) {
      addUser({
        'id': senderId,
        'recipient_id': senderId,
        'name': mailData?['sender_name'] ?? 'Sender',
      });
    }

    final List recipients =
        mailData?['recipients_data'] is List
            ? mailData['recipients_data']
            : <dynamic>[];

    for (final dynamic recipient in recipients) {
      addUser(recipient);
    }

    if (!mounted) return;

    setState(() {
      replyRecipientUsers = uniqueUsers.values.toList();
      allReplyRecipientsSelected = false;
    });
  }

  Future<bool> loadMailThread(int mailId) async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return false;
    }

    try {
      if (mounted) {
        setState(() {
          isLoadingMailDetail = true;
        });
      }

      final http.Response response = await http.get(
        Uri.parse('$api/api/internal/mails/$mailId/'),
        headers: jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        String message = 'Failed to open mail';

        try {
          final dynamic decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        showMsg(message);
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);

      final dynamic mailData =
          decoded['data'] ?? decoded['mail'] ?? decoded;

      final List<dynamic> threadData =
          decoded['thread'] is List
              ? List<dynamic>.from(decoded['thread'])
              : mailData != null
                  ? <dynamic>[mailData]
                  : <dynamic>[];

      if (!mounted) return false;

      setState(() {
        selectedMail = mailData;
        mailThread = threadData;
      });

      await prepareDefaultReplyRecipients(mailData);

      return true;
    } catch (e) {
      debugPrint('OPEN MAIL ERROR: $e');
      showMsg('Failed to open mail');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMailDetail = false;
        });
      }
    }
  }

  Future<void> fetchReplyStaffs(String search) async {
    if (isFetchingReplyStaffs) return;

    final String normalizedSearch = search.trim();

    if (normalizedSearch.isEmpty) {
      if (mounted) {
        setState(() {
          replyStaffs = [];
        });
      }
      return;
    }

    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return;
    }

    try {
      if (mounted) {
        setState(() {
          isFetchingReplyStaffs = true;
        });
      }

      final Uri uri = buildUri(
        'api/get/staffs/',
        {
          'page': '1',
          'search': normalizedSearch,
          'approval_status': 'approved',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Reply staff API failed with ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> receivedStaffs = extractStaffData(decoded);

      final List<Map<String, dynamic>> validStaffs = [];

      for (final dynamic staff in receivedStaffs) {
        final Map<String, dynamic>? normalized =
            normalizeRecipient(staff);

        if (normalized == null) continue;

        final int? recipientId = getRecipientId(normalized);

        final bool alreadySelected =
            replyRecipientUsers.any(
          (selected) =>
              getRecipientId(selected) == recipientId,
        );

        if (!alreadySelected) {
          validStaffs.add(normalized);
        }
      }

      if (!mounted) return;

      setState(() {
        replyStaffs = validStaffs;
      });
    } catch (e) {
      debugPrint('FETCH REPLY STAFF ERROR: $e');
      showMsg('Failed to search recipients');
    } finally {
      if (mounted) {
        setState(() {
          isFetchingReplyStaffs = false;
        });
      }
    }
  }

  void addReplyRecipient(dynamic staff) {
    final Map<String, dynamic>? normalized =
        normalizeRecipient(staff);

    if (normalized == null) {
      showMsg(
        'This staff does not have a valid approved user account',
      );
      return;
    }

    final int? recipientId = getRecipientId(normalized);

    if (recipientId == null) return;

    final bool alreadySelected = replyRecipientUsers.any(
      (item) => getRecipientId(item) == recipientId,
    );

    if (alreadySelected) {
      replySearchController.clear();

      setState(() {
        replyStaffs = [];
      });
      return;
    }

    setState(() {
      replyRecipientUsers.add(normalized);
      replySearchController.clear();
      replyStaffs = [];
      allReplyRecipientsSelected = false;
    });
  }

  void removeReplyRecipient(dynamic staff) {
    final int? recipientId = getRecipientId(staff);

    if (recipientId == null) return;

    setState(() {
      replyRecipientUsers.removeWhere(
        (item) => getRecipientId(item) == recipientId,
      );
      allReplyRecipientsSelected = false;
    });
  }


  bool isReplyRecipientSelected(dynamic staff) {
    final int? recipientId = getRecipientId(staff);

    if (recipientId == null) return false;

    return replyRecipientUsers.any(
      (selected) => getRecipientId(selected) == recipientId,
    );
  }

  void toggleReplyRecipient(dynamic staff) {
    final Map<String, dynamic>? normalized =
        normalizeRecipient(staff);

    if (normalized == null) {
      showMsg(
        'This staff does not have a valid approved user account',
      );
      return;
    }

    final int? recipientId = getRecipientId(normalized);

    if (recipientId == null) return;

    setState(() {
      final bool alreadySelected = replyRecipientUsers.any(
        (selected) =>
            getRecipientId(selected) == recipientId,
      );

      if (alreadySelected) {
        replyRecipientUsers.removeWhere(
          (selected) =>
              getRecipientId(selected) == recipientId,
        );
      } else {
        replyCcRecipientUsers.removeWhere(
          (selected) => getRecipientId(selected) == recipientId,
        );
        replyBccRecipientUsers.removeWhere(
          (selected) => getRecipientId(selected) == recipientId,
        );
        replyRecipientUsers.add(normalized);
      }

      allReplyRecipientsSelected = false;
    });
  }

  Future<void> selectAllReplyRecipients() async {
    List<Map<String, dynamic>> completeList =
        allRecipientStaffs;

    if (completeList.isEmpty) {
      completeList = await fetchAllRecipientStaffs();
    }

    if (completeList.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    final int? currentUserId = await getCurrentUserId();
    final Map<int, Map<String, dynamic>> uniqueRecipients = {};

    for (final Map<String, dynamic> staff in completeList) {
      final int? recipientId = getRecipientId(staff);

      final excludedIds = {
        ...replyCcRecipientUsers.map(getRecipientId).whereType<int>(),
        ...replyBccRecipientUsers.map(getRecipientId).whereType<int>(),
      };

      if (recipientId == null ||
          recipientId <= 0 ||
          recipientId == currentUserId ||
          excludedIds.contains(recipientId) ||
          !isApprovedRecipient(staff)) {
        continue;
      }

      uniqueRecipients[recipientId] = staff;
    }

    if (uniqueRecipients.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    if (!mounted) return;

    setState(() {
      replyRecipientUsers = uniqueRecipients.values.toList();
      allReplyRecipientsSelected = true;
      replySearchController.clear();
    });

    showMsg(
      '${replyRecipientUsers.length} reply recipients selected',
      success: true,
    );
  }

  void clearAllReplyRecipients() {
    setState(() {
      replyRecipientUsers.clear();
      allReplyRecipientsSelected = false;
      replySearchController.clear();
    });
  }

  Set<int> _replyExcludedIdsFor(String type) {
    final Set<int> excluded = {};

    if (type != 'to') {
      excluded.addAll(
        replyRecipientUsers.map(getRecipientId).whereType<int>(),
      );
    }

    if (type != 'cc') {
      excluded.addAll(
        replyCcRecipientUsers.map(getRecipientId).whereType<int>(),
      );
    }

    if (type != 'bcc') {
      excluded.addAll(
        replyBccRecipientUsers.map(getRecipientId).whereType<int>(),
      );
    }

    return excluded;
  }

  Future<List<Map<String, dynamic>>> _eligibleReplyRecipients(
    String type,
  ) async {
    List<Map<String, dynamic>> completeList = allRecipientStaffs;

    if (completeList.isEmpty) {
      completeList = await fetchAllRecipientStaffs();
    }

    final int? currentUserId = await getCurrentUserId();
    final Set<int> excludedIds = _replyExcludedIdsFor(type);
    final Map<int, Map<String, dynamic>> uniqueRecipients = {};

    for (final Map<String, dynamic> staff in completeList) {
      final int? recipientId = getRecipientId(staff);

      if (recipientId != null &&
          recipientId > 0 &&
          recipientId != currentUserId &&
          isApprovedRecipient(staff) &&
          !excludedIds.contains(recipientId)) {
        uniqueRecipients[recipientId] = staff;
      }
    }

    return uniqueRecipients.values.toList();
  }

  Future<void> selectAllReplyRecipientsFor(String type) async {
    final List<Map<String, dynamic>> eligible =
        await _eligibleReplyRecipients(type);

    if (eligible.isEmpty) {
      showMsg('No approved recipients found');
      return;
    }

    if (!mounted) return;

    setState(() {
      final List<Map<String, dynamic>> target = _replyListFor(type);
      target
        ..clear()
        ..addAll(eligible);

      allReplyRecipientsSelected = type == 'to';
      replySearchController.clear();
    });

    showMsg(
      '${eligible.length} reply ${_recipientLabel(type)} recipients selected',
      success: true,
    );
  }

  void clearAllReplyRecipientsFor(String type) {
    setState(() {
      _replyListFor(type).clear();

      if (type == 'to') {
        allReplyRecipientsSelected = false;
      }

      replySearchController.clear();
    });
  }

  bool areAllReplyRecipientsSelected(
    String type,
    List<Map<String, dynamic>> eligible,
  ) {
    if (eligible.isEmpty) return false;

    final Set<int> eligibleIds =
        eligible.map(getRecipientId).whereType<int>().toSet();

    final Set<int> selectedIds =
        _replyListFor(type).map(getRecipientId).whereType<int>().toSet();

    return eligibleIds.isNotEmpty && selectedIds.containsAll(eligibleIds);
  }

  Future<void> fetchReplySelectorStaffs([
    String search = '',
  ]) async {
    if (isFetchingReplyStaffs) return;

    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return;
    }

    try {
      if (mounted) {
        setState(() {
          isFetchingReplyStaffs = true;
        });
      }

      final Uri uri = buildUri(
        'api/get/staffs/',
        {
          'page': '1',
          'search': search.trim(),
          'approval_status': 'approved',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Reply staff API failed with ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> receivedStaffs =
          extractStaffData(decoded);

      final List<Map<String, dynamic>> validStaffs = [];

      for (final dynamic staff in receivedStaffs) {
        final Map<String, dynamic>? normalized =
            normalizeRecipient(staff);

        if (normalized != null) {
          validStaffs.add(normalized);
        }
      }

      if (!mounted) return;

      setState(() {
        replyStaffs = validStaffs;
      });
    } catch (e) {
      debugPrint(
        'FETCH REPLY SELECTOR STAFF ERROR: $e',
      );
      showMsg('Failed to load recipients');
    } finally {
      if (mounted) {
        setState(() {
          isFetchingReplyStaffs = false;
        });
      }
    }
  }

  Future<void> openReplyRecipientSelector({
    required VoidCallback refreshParentSheet,
  }) async {
    replySearchDebounce?.cancel();
    replySearchController.clear();

    await fetchReplySelectorStaffs();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            Future<void> refreshReplyStaffList([
              String search = '',
            ]) async {
              await fetchReplySelectorStaffs(search);

              if (modalContext.mounted) {
                modalSetState(() {});
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (sheetContext, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            18,
                            10,
                            14,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Select Reply Recipients',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () {
                                  Navigator.pop(
                                    bottomSheetContext,
                                  );
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          child: TextField(
                            controller: replySearchController,
                            textInputAction:
                                TextInputAction.search,
                            onChanged: (value) {
                              modalSetState(() {});
                              replySearchDebounce?.cancel();

                              replySearchDebounce = Timer(
                                const Duration(
                                  milliseconds: 450,
                                ),
                                () async {
                                  await refreshReplyStaffList(
                                    value.trim(),
                                  );
                                },
                              );
                            },
                            decoration: inputDecoration(
                              hint: 'Search staff',
                              icon: Icons.search_rounded,
                            ).copyWith(
                              suffixIcon:
                                  replySearchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () async {
                                            replySearchDebounce
                                                ?.cancel();
                                            replySearchController
                                                .clear();
                                            modalSetState(() {});
                                            await refreshReplyStaffList();
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          child: InkWell(
                            onTap: isFetchingAllStaffs
                                ? null
                                : () async {
                                    if (allReplyRecipientsSelected) {
                                      clearAllReplyRecipients();
                                    } else {
                                      await selectAllReplyRecipients();
                                    }

                                    if (modalContext.mounted) {
                                      modalSetState(() {});
                                    }

                                    refreshParentSheet();
                                  },
                            borderRadius:
                                BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: allReplyRecipientsSelected
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: allReplyRecipientsSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: isFetchingAllStaffs
                                          ? const SizedBox(
                                              width: 23,
                                              height: 23,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Checkbox(
                                              value:
                                                  allReplyRecipientsSelected,
                                              activeColor:
                                                  const Color(
                                                0xFF2563EB,
                                              ),
                                              onChanged: (_) async {
                                                if (allReplyRecipientsSelected) {
                                                  clearAllReplyRecipients();
                                                } else {
                                                  await selectAllReplyRecipients();
                                                }

                                                if (modalContext
                                                    .mounted) {
                                                  modalSetState(
                                                    () {},
                                                  );
                                                }

                                                refreshParentSheet();
                                              },
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFetchingAllStaffs
                                              ? 'Loading all staff...'
                                              : allReplyRecipientsSelected
                                                  ? 'Clear All'
                                                  : 'Select All',
                                          style: const TextStyle(
                                            color:
                                                Color(0xFF0F172A),
                                            fontWeight:
                                                FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isFetchingAllStaffs
                                              ? 'Fetching every staff page'
                                              : allReplyRecipientsSelected
                                                  ? 'All approved staff selected'
                                                  : 'Select approved staff from all pages',
                                          style: const TextStyle(
                                            color:
                                                Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEFF6FF,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        999,
                                      ),
                                    ),
                                    child: Text(
                                      '${replyRecipientUsers.length} selected',
                                      style: const TextStyle(
                                        color:
                                            Color(0xFF2563EB),
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: isFetchingReplyStaffs
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : replyStaffs.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .person_search_rounded,
                                              size: 48,
                                              color:
                                                  Color(0xFF94A3B8),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'No staff found',
                                              style: TextStyle(
                                                color:
                                                    Color(0xFF475569),
                                                fontWeight:
                                                    FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller:
                                          scrollController,
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                        18,
                                        4,
                                        18,
                                        110,
                                      ),
                                      itemCount:
                                          replyStaffs.length,
                                      separatorBuilder: (_, __) {
                                        return const SizedBox(
                                          height: 10,
                                        );
                                      },
                                      itemBuilder:
                                          (itemContext, index) {
                                        final dynamic staff =
                                            replyStaffs[index];

                                        final bool selected =
                                            isReplyRecipientSelected(
                                          staff,
                                        );

                                        return InkWell(
                                          onTap: () {
                                            toggleReplyRecipient(
                                              staff,
                                            );
                                            modalSetState(() {});
                                            refreshParentSheet();
                                          },
                                          borderRadius:
                                              BorderRadius.circular(
                                            16,
                                          ),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(
                                              14,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: selected
                                                  ? const Color(
                                                      0xFFEFF6FF,
                                                    )
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                16,
                                              ),
                                              border: Border.all(
                                                color: selected
                                                    ? const Color(
                                                        0xFF2563EB,
                                                      )
                                                    : const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                width:
                                                    selected ? 1.4 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      selected
                                                          ? const Color(
                                                              0xFF2563EB,
                                                            )
                                                          : const Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                  child: Icon(
                                                    selected
                                                        ? Icons
                                                            .check_rounded
                                                        : Icons
                                                            .person_rounded,
                                                    color: selected
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 12,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        staffName(
                                                          staff,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style:
                                                            const TextStyle(
                                                          color: Color(
                                                            0xFF0F172A,
                                                          ),
                                                          fontWeight:
                                                              FontWeight
                                                                  .w900,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      const Text(
                                                        'mexpo.org',
                                                        style:
                                                            TextStyle(
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                          fontWeight:
                                                              FontWeight
                                                                  .w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Checkbox(
                                                  value: selected,
                                                  activeColor:
                                                      const Color(
                                                    0xFF2563EB,
                                                  ),
                                                  onChanged: (_) {
                                                    toggleReplyRecipient(
                                                      staff,
                                                    );
                                                    modalSetState(
                                                      () {},
                                                    );
                                                    refreshParentSheet();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            12,
                            18,
                            18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  bottomSheetContext,
                                );
                                refreshParentSheet();
                              },
                              style: primaryButtonStyle(),
                              child: Text(
                                'Done '
                                '(${replyRecipientUsers.length})',
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
        );
      },
    );

    replySearchController.clear();

    if (mounted) {
      setState(() {});
    }

    refreshParentSheet();
  }

  int getReplyDocumentsTotalSize() {
    return replyDocuments.fold<int>(
      0,
      (total, file) => total + file.size,
    );
  }

  Future<void> pickReplyFiles() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );

    if (result == null) return;

    final int existingSize = getReplyDocumentsTotalSize();
    final int pickedSize = result.files.fold<int>(
      0,
      (total, file) => total + file.size,
    );

    if (existingSize + pickedSize > maxFileSize) {
      showMaxUploadSizePopup();
      return;
    }

    if (!mounted) return;

    setState(() {
      replyDocuments.addAll(result.files);
    });
  }

  Future<bool> sendReply() async {
    if (isSendingReply) return false;

    final int? mailId = int.tryParse(
      selectedMail?['id']?.toString() ?? '',
    );

    if (mailId == null || mailId <= 0) {
      showMsg('Select a mail first');
      return false;
    }

    final Set<int> recipientIds = replyRecipientUsers
        .map(getRecipientId).whereType<int>().where((id) => id > 0).toSet();
    final Set<int> ccRecipientIds = replyCcRecipientUsers
        .map(getRecipientId).whereType<int>().where((id) => id > 0).toSet();
    final Set<int> bccRecipientIds = replyBccRecipientUsers
        .map(getRecipientId).whereType<int>().where((id) => id > 0).toSet();

    if (recipientIds.isEmpty && ccRecipientIds.isEmpty && bccRecipientIds.isEmpty) {
      showMsg('Select at least one To, CC or BCC reply recipient');
      return false;
    }

    final String message = replyMessageController.text.trim();

    if (message.isEmpty && replyDocuments.isEmpty) {
      showMsg('Reply message or attachment is required');
      return false;
    }

    if (getReplyDocumentsTotalSize() > maxFileSize) {
      showMaxUploadSizePopup();
      return false;
    }

    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return false;
    }

    try {
      if (mounted) {
        setState(() {
          isSendingReply = true;
        });
      }

      final http.MultipartRequest request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          '$api/api/internal/mails/$mailId/reply/',
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['message'] = message;

      for (final int recipientId in recipientIds) {
        request.files.add(http.MultipartFile.fromString('recipients', recipientId.toString()));
      }
      for (final int recipientId in ccRecipientIds) {
        request.files.add(http.MultipartFile.fromString('cc_recipients', recipientId.toString()));
      }
      for (final int recipientId in bccRecipientIds) {
        request.files.add(http.MultipartFile.fromString('bcc_recipients', recipientId.toString()));
      }

      for (final PlatformFile file in replyDocuments) {
        if (file.path == null) continue;

        request.files.add(
          await http.MultipartFile.fromPath(
            'documents',
            file.path!,
            filename: file.name,
          ),
        );
      }

      final http.StreamedResponse streamedResponse =
          await request.send();

      final String responseBody =
          await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        String errorMessage = 'Failed to send reply';

        try {
          final dynamic decoded = jsonDecode(responseBody);
          errorMessage =
              decoded['message']?.toString() ??
              errorMessage;
        } catch (_) {}

        showMsg(errorMessage);
        return false;
      }

      showMsg('Reply sent successfully', success: true);

      replyMessageController.clear();

      if (mounted) {
        setState(() {
          replyDocuments = [];
          replyCcRecipientUsers = [];
          replyBccRecipientUsers = [];
        });
      }

      await loadMailThread(mailId);
      await fetchMails(type: 'inbox', refresh: true);
      await fetchMails(type: 'sent', refresh: true);

      return true;
    } catch (e) {
      debugPrint('SEND REPLY ERROR: $e');
      showMsg('Something went wrong while sending reply');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSendingReply = false;
        });
      }
    }
  }

  Widget buildAttachmentTile(dynamic file) {
    final String? url =
        file?['document_url']?.toString();

    final String name =
        file?['document']
                ?.toString()
                .split('/')
                .last ??
            'Attachment';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(fileIcon(name)),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            const Icon(Icons.open_in_new_rounded),
        onTap: () async {
          if (url == null || url.isEmpty) return;

          final Uri uri = Uri.parse(url);

          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            showMsg('Unable to open attachment');
          }
        },
      ),
    );
  }

  Widget buildThreadMessageCard(dynamic threadMail) {
    final List attachments =
        threadMail?['attachments'] is List
            ? threadMail['attachments']
            : <dynamic>[];

    final List recipients =
        threadMail?['recipients_data'] is List
            ? threadMail['recipients_data']
            : <dynamic>[];
    final List ccRecipients = threadMail?['cc_recipients_data'] is List
        ? threadMail['cc_recipients_data']
        : <dynamic>[];
    final List bccRecipients = threadMail?['bcc_recipients_data'] is List
        ? threadMail['bcc_recipients_data']
        : <dynamic>[];

    final bool replyMessage = isReplyMail(threadMail);

    final String recipientNames = recipients
        .map((user) => user?['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
    final String ccNames = ccRecipients
        .map((user) => user?['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty).join(', ');
    final String bccNames = bccRecipients
        .map((user) => user?['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFFEFF6FF),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (replyMessage) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'REPLY',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Text(
                            threadMail?['sender_name']
                                    ?.toString() ??
                                'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To: ${recipientNames.isEmpty ? 'Unknown' : recipientNames}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    if (ccNames.isNotEmpty)
                      Text('CC: $ccNames', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    if (bccNames.isNotEmpty)
                      Text('BCC: $bccNames', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    if (threadMail?['current_user_recipient_type']?.toString().toLowerCase() == 'bcc')
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                        child: const Text('You received this mail as BCC',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDateTimeIndian(
                  threadMail?['created_at']?.toString(),
                ),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            threadMail?['message']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? threadMail['message'].toString()
                : 'No message',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Attachments',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            ...attachments.map(buildAttachmentTile),
          ],
        ],
      ),
    );
  }

  Future<bool> updateMailReadStatus(
    int mailId,
    bool isRead, {
    bool showFeedback = true,
  }) async {
    if (isUpdatingReadStatus) return false;

    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      showMsg('Token missing');
      return false;
    }

    try {
      if (mounted) {
        setState(() => isUpdatingReadStatus = true);
      }

      final http.Response response = await http.patch(
        Uri.parse('$api/api/internal/mails/$mailId/read/status/'),
        headers: jsonHeaders(token),
        body: jsonEncode({'is_read': isRead}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to update read status';
        try {
          final dynamic decoded = jsonDecode(response.body);
          message = decoded?['message']?.toString() ?? message;
        } catch (_) {}
        if (showFeedback) showMsg(message);
        return false;
      }

      dynamic updatedData;
      try {
        final dynamic decoded = jsonDecode(response.body);
        updatedData = decoded?['data'];
      } catch (_) {}

      final bool updatedIsRead =
          updatedData?['is_read'] is bool ? updatedData['is_read'] : isRead;
      final dynamic updatedReadAt = updatedData?['read_at'];

      if (!mounted) return true;

      setState(() {
        inboxMails = inboxMails.map((item) {
          if (int.tryParse(item?['id']?.toString() ?? '') != mailId) {
            return item;
          }
          return <String, dynamic>{
            ...Map<String, dynamic>.from(item as Map),
            'is_read': updatedIsRead,
            'read_at': updatedReadAt,
          };
        }).toList();

        if (selectedMail is Map &&
            int.tryParse(selectedMail?['id']?.toString() ?? '') == mailId) {
          selectedMail = <String, dynamic>{
            ...Map<String, dynamic>.from(selectedMail as Map),
            'is_read': updatedIsRead,
            'read_at': updatedReadAt,
          };
        }
      });

      if (showFeedback) {
        showMsg(
          updatedIsRead ? 'Mail marked as read' : 'Mail marked as unread',
          success: true,
        );
      }

      await fetchMails(type: 'inbox', refresh: true);
      return true;
    } catch (e) {
      debugPrint('UPDATE READ STATUS ERROR: $e');
      if (showFeedback) showMsg('Failed to update read status');
      return false;
    } finally {
      if (mounted) {
        setState(() => isUpdatingReadStatus = false);
      }
    }
  }

  Future<void> openMailDetail(dynamic mail, String mailboxType) async {
    final int? mailId = int.tryParse(
      mail?['id']?.toString() ?? '',
    );

    if (mailId == null || mailId <= 0) {
      showMsg('Invalid mail');
      return;
    }

    final bool wasUnread = mailboxType == 'inbox' && isUnreadMail(mail);

    resetReplyForm();

    final bool loaded = await loadMailThread(mailId);

    if (loaded && wasUnread) {
      await updateMailReadStatus(
        mailId,
        true,
        showFeedback: false,
      );
    }

    if (!loaded || !mounted || selectedMail == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            void refreshSheet() {
              if (modalContext.mounted) {
                modalSetState(() {});
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.94,
              minChildSize: 0.55,
              maxChildSize: 0.98,
              builder: (sheetContext, scrollController) {
                final List<dynamic> displayThread =
                    mailThread.isNotEmpty
                        ? mailThread
                        : <dynamic>[selectedMail];

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            14,
                            8,
                            12,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getMailDisplaySubject(
                                        selectedMail,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight.w900,
                                        color:
                                            Color(0xFF0F172A),
                                      ),
                                    ),
                                    // const SizedBox(height: 3),
                                    // const Text(
                                    //   'Conversation thread',
                                    //   style: TextStyle(
                                    //     color:
                                    //         Color(0xFF64748B),
                                    //     fontWeight:
                                    //         FontWeight.w600,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                              if (mailboxType == 'inbox')
                                IconButton(
                                  tooltip: isUnreadMail(selectedMail)
                                      ? 'Mark as read'
                                      : 'Mark as unread',
                                  onPressed: isUpdatingReadStatus
                                      ? null
                                      : () async {
                                          final bool targetRead =
                                              isUnreadMail(selectedMail);
                                          await updateMailReadStatus(
                                            mailId,
                                            targetRead,
                                          );
                                          refreshSheet();
                                        },
                                  icon: Icon(
                                    isUnreadMail(selectedMail)
                                        ? Icons.mark_email_read_outlined
                                        : Icons.mark_email_unread_outlined,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: isDeleting
                                    ? null
                                    : () async {
                                        Navigator.pop(
                                          bottomSheetContext,
                                        );
                                        confirmDelete(
                                          selectedMail,
                                          mailboxType,
                                        );
                                      },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () {
                                  Navigator.pop(
                                    bottomSheetContext,
                                  );
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              24,
                            ),
                            children: [
                              if (isReplyMail(selectedMail) ||
                                  displayThread.length > 1)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.forum_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Reply conversation',
                                              style: TextStyle(
                                                color: Color(0xFF1D4ED8),
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'This mail contains replies in an existing conversation.',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
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
                              ...displayThread.map(
                                buildThreadMessageCard,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFE2E8F0,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w900,
                                        color:
                                            Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    InkWell(
                                      onTap: () async {
                                        await openReplyRecipientSelector(
                                          refreshParentSheet:
                                              refreshSheet,
                                        );
                                      },
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF8FAFC,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFE2E8F0,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .people_alt_rounded,
                                              color: Color(
                                                0xFF475569,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                replyRecipientUsers
                                                        .isEmpty
                                                    ? 'Select reply recipients'
                                                    : '${replyRecipientUsers.length} reply recipients selected',
                                                style: TextStyle(
                                                  color:
                                                      replyRecipientUsers
                                                              .isEmpty
                                                          ? const Color(
                                                              0xFF64748B,
                                                            )
                                                          : const Color(
                                                              0xFF0F172A,
                                                            ),
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons
                                                  .keyboard_arrow_down_rounded,
                                              color: Color(
                                                0xFF64748B,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (replyRecipientUsers
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            replyRecipientUsers
                                                .map(
                                          (user) {
                                            return Chip(
                                              label: Text(
                                                staffName(user),
                                              ),
                                              deleteIcon:
                                                  const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                              ),
                                              onDeleted: () {
                                                removeReplyRecipient(
                                                  user,
                                                );
                                                refreshSheet();
                                              },
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    _buildReplyRecipientField('cc', replyCcRecipientUsers, refreshSheet),
                                    const SizedBox(height: 14),
                                    _buildReplyRecipientField('bcc', replyBccRecipientUsers, refreshSheet),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 140,
                                      child: TextField(
                                        controller:
                                            replyMessageController,
                                        expands: true,
                                        maxLines: null,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        decoration:
                                            inputDecoration(
                                          hint:
                                              'Write your reply',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () async {
                                        await pickReplyFiles();
                                        refreshSheet();
                                      },
                                      borderRadius:
                                          BorderRadius.circular(
                                        14,
                                      ),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(
                                          13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF8FAFC,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(14),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFE2E8F0,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .attach_file_rounded,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Add reply attachments',
                                                style:
                                                    TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w800,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Max 1 MB',
                                              style:
                                                  TextStyle(
                                                color: Color(
                                                  0xFF64748B,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (replyDocuments
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      ...List.generate(
                                        replyDocuments.length,
                                        (index) {
                                          final PlatformFile file =
                                              replyDocuments[
                                                  index];

                                          return Container(
                                            margin:
                                                const EdgeInsets
                                                    .only(
                                              bottom: 8,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: const Color(
                                                0xFFF8FAFC,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                12,
                                              ),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFE2E8F0,
                                                ),
                                              ),
                                            ),
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                fileIcon(
                                                  file.name,
                                                ),
                                              ),
                                              title: Text(
                                                file.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),
                                              subtitle: Text(
                                                fileSizeText(
                                                  file.size,
                                                ),
                                              ),
                                              trailing:
                                                  IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    replyDocuments
                                                        .removeAt(
                                                      index,
                                                    );
                                                  });
                                                  refreshSheet();
                                                },
                                                icon:
                                                    const Icon(
                                                  Icons
                                                      .close_rounded,
                                                  color:
                                                      Colors.red,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child:
                                          ElevatedButton.icon(
                                        onPressed:
                                            isSendingReply
                                                ? null
                                                : () async {
                                                    final bool
                                                        sent =
                                                        await sendReply();

                                                    refreshSheet();

                                                    if (sent) {
                                                      await prepareDefaultReplyRecipients(
                                                        selectedMail,
                                                      );
                                                      refreshSheet();
                                                    }
                                                  },
                                        icon: isSendingReply
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2,
                                                  color:
                                                      Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons
                                                    .send_rounded,
                                              ),
                                        label: Text(
                                          isSendingReply
                                              ? 'Sending...'
                                              : 'Send Reply',
                                        ),
                                        style:
                                            primaryButtonStyle(),
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
                );
              },
            );
          },
        );
      },
    );

    if (mounted) {
      resetReplyForm();

      setState(() {
        selectedMail = null;
        mailThread = [];
      });
    }
  }

  Widget _buildComposeRecipientField(
    String type,
    List<Map<String, dynamic>> users,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => openComposeRecipientSelector(type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Icon(type == 'bcc' ? Icons.visibility_off_rounded : Icons.people_outline_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text(
                users.isEmpty ? 'Select ${_recipientLabel(type)} recipients' : '${users.length} ${_recipientLabel(type)} recipients selected',
                style: const TextStyle(fontWeight: FontWeight.w800))),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ]),
          ),
        ),
        if (users.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: users.map((user) => Chip(
              label: Text(staffName(user)),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              onDeleted: () => setState(() {
                users.removeWhere((item) => getRecipientId(item) == getRecipientId(user));
                allRecipientsSelected = false;
              }),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReplyRecipientField(
    String type,
    List<Map<String, dynamic>> users,
    VoidCallback refreshSheet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => openReplyGroupSelector(type, refreshSheet),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Icon(type == 'bcc' ? Icons.visibility_off_rounded : Icons.people_alt_rounded,
                color: const Color(0xFF475569)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                users.isEmpty ? 'Select reply ${_recipientLabel(type)}' : '${users.length} reply ${_recipientLabel(type)} selected',
                style: TextStyle(
                  color: users.isEmpty ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800))),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
            ]),
          ),
        ),
        if (users.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: users.map((user) => Chip(
              label: Text(staffName(user)),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              onDeleted: () {
                setState(() => users.removeWhere((item) => getRecipientId(item) == getRecipientId(user)));
                refreshSheet();
              },
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget buildComposePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Message',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: openStaffSelector,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedStaffs.isEmpty
                            ? 'Select recipients'
                            : '${selectedStaffs.length} recipients selected',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            if (selectedStaffs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(selectedStaffs.length, (index) {
                  final staff = selectedStaffs[index];

                  return Chip(
                    label: Text(staffName(staff)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    onDeleted: () {
                      setState(() => selectedStaffs.removeAt(index));
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 14),
            _buildComposeRecipientField('cc', selectedCcStaffs),
            const SizedBox(height: 14),
            _buildComposeRecipientField('bcc', selectedBccStaffs),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: inputDecoration(
                hint: 'Subject',
                icon: Icons.subject_rounded,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: TextField(
                controller: messageController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: inputDecoration(
                  hint: 'Write your message',
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: pickFiles,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attach_file_rounded),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add files',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      'Any file under 1 MB',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...List.generate(selectedFiles.length, (index) {
                final file = selectedFiles[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: Icon(fileIcon(file.name)),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(fileSizeText(file.size)),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() => selectedFiles.removeAt(index));
                      },
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSending ? null : sendMail,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(isSending ? 'Sending...' : 'Send Mail'),
                style: primaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
