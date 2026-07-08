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

  static const int maxFileSize = 1024 * 1024;

  List<dynamic> staffs = [];
  List<Map<String, dynamic>> selectedStaffs = [];
  List<PlatformFile> selectedFiles = [];

  List<dynamic> inboxMails = [];
  List<dynamic> sentMails = [];

  bool isFetchingStaffs = false;
  bool isSending = false;
  bool isLoadingInbox = false;
  bool isLoadingSent = false;
  bool isDeleting = false;

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
    staffDebounce?.cancel();
    mailSearchDebounce?.cancel();
    super.dispose();
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

  Future<void> fetchStaffs([String search = '']) async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        showMsg('Token missing');
        return;
      }

      if (mounted) {
        setState(() => isFetchingStaffs = true);
      }

      final response = await http.get(
        buildUri('api/get/staffs/', {
          'page': '1',
          'page_size': '1000',
          'search': search,
        }),
        headers: jsonHeaders(token),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        staffs = decoded['results']?['data'] ??
            decoded['results'] ??
            decoded['data'] ??
            [];
      });
    } catch (_) {
      showMsg('Error fetching staffs');
    } finally {
      if (mounted) {
        setState(() => isFetchingStaffs = false);
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

      final response = await http.get(
        buildUri('api/internal/mails/', {
          'type': type,
          'search': mailSearchController.text.trim(),
          'page': currentPage.toString(),
        }),
        headers: jsonHeaders(token),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      final List<dynamic> data = decoded['results']?['data'] ??
          decoded['data']?['data'] ??
          decoded['results'] ??
          decoded['data'] ??
          [];

      final bool hasNext =
          decoded['next'] != null || decoded['results']?['next'] != null;

      setState(() {
        if (isInbox) {
          inboxMails = refresh ? data : [...inboxMails, ...data];
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

  if (selectedStaffs.isEmpty) {
    showMsg('Please select at least one recipient');
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

    for (final staff in selectedStaffs) {
      request.files.add(
        http.MultipartFile.fromString(
          'recipients',
          staff['id'].toString(),
        ),
      );
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
        selectedFiles.clear();
        subjectController.clear();
        messageController.clear();
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
    return staff['email']?.toString() ??
        staff['official_email']?.toString() ??
        'No email';
  }

  bool isStaffSelected(dynamic staff) {
    return selectedStaffs.any(
      (item) => item['id'].toString() == staff['id'].toString(),
    );
  }

  void toggleStaff(dynamic staff) {
    setState(() {
      if (isStaffSelected(staff)) {
        selectedStaffs.removeWhere(
          (item) => item['id'].toString() == staff['id'].toString(),
        );
      } else {
        selectedStaffs.add(Map<String, dynamic>.from(staff));
      }
    });
  }

  Future<void> openStaffSelector() async {
    staffSearchController.clear();
    await fetchStaffs();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
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
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select Recipients',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          controller: staffSearchController,
                          onChanged: (value) {
                            modalSetState(() {});
                            staffDebounce?.cancel();
                            staffDebounce = Timer(
                              const Duration(milliseconds: 450),
                              () async {
                                await fetchStaffs(value.trim());
                                if (context.mounted) {
                                  modalSetState(() {});
                                }
                              },
                            );
                          },
                          decoration: inputDecoration(
                            hint: 'Search staff',
                            icon: Icons.search_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isFetchingStaffs
                            ? const Center(child: CircularProgressIndicator())
                            : staffs.isEmpty
                                ? const Center(child: Text('No staff found'))
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      8,
                                      18,
                                      100,
                                    ),
                                    itemCount: staffs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final staff = staffs[index];
                                      final selected = isStaffSelected(staff);

                                      return InkWell(
                                        onTap: () {
                                          toggleStaff(staff);
                                          modalSetState(() {});
                                        },
                                        borderRadius: BorderRadius.circular(16),
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
                                                      : const Color(0xFF64748B),
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
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      staffEmail(staff),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Checkbox(
                                                value: selected,
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
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: primaryButtonStyle(),
                            child: Text('Done (${selectedStaffs.length})'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Sent'),
            Tab(text: 'Compose'),
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
            const SizedBox(height: 16),
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

  Widget buildMailCard(dynamic mail, String type) {
    final attachments = mail['attachments'] as List? ?? [];
    final recipients = mail['recipients_data'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => openMailDetail(mail),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(
            type == 'inbox' ? Icons.inbox_rounded : Icons.send_rounded,
            color: const Color(0xFF2563EB),
          ),
        ),
        title: Text(
          mail['subject']?.toString() ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'inbox'
                    ? 'From: ${mail['sender_name'] ?? ''}'
                    : 'To: ${recipients.map((e) => e['name']).join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(formatDateTimeIndian(mail['created_at']?.toString())),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.attach_file_rounded, size: 16),
                    Text('${attachments.length}'),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: isDeleting ? null : () => confirmDelete(mail, type),
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
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

  void openMailDetail(dynamic mail) {
    final attachments = mail['attachments'] as List? ?? [];
    final recipients = mail['recipients_data'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  mail['subject']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text('From: ${mail['sender_name'] ?? ''}'),
                const SizedBox(height: 6),
                Text('To: ${recipients.map((e) => e['name']).join(', ')}'),
                const SizedBox(height: 6),
Text(formatDateTimeIndian(mail['created_at']?.toString())),
                const Divider(height: 28),
                Text(
                  mail['message']?.toString().isNotEmpty == true
                      ? mail['message'].toString()
                      : 'No message',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...attachments.map((file) {
                    final url = file['document_url']?.toString();
                    final name =
                        file['document']?.toString().split('/').last ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        leading: Icon(fileIcon(name)),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () async {
                          if (url == null || url.isEmpty) return;

                          final uri = Uri.parse(url);

                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
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