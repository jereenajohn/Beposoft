import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeExitFormPage extends StatefulWidget {
  final int? exitId;
  final bool popOnSuccess;

  const EmployeeExitFormPage({
    super.key,
    this.exitId,
    this.popOnSuccess = false,
  });

  @override
  State<EmployeeExitFormPage> createState() => _EmployeeExitFormPageState();
}

class _EmployeeExitFormPageState extends State<EmployeeExitFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isSaving = false;
  bool isStaffLoading = false;

  List<Map<String, dynamic>> staffList = [];

  String? selectedEmployeeId;
  String? selectedHandoverToId;
  String? selectedLogisticsClearanceById;
  String? selectedFinanceClearanceById;
  String? selectedHrClearanceById;
  String? selectedSalesClearanceById;
  String? selectedItClearanceById;

  final TextEditingController exitDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController exitReasonNoteController = TextEditingController();
  final TextEditingController assetResponsibilityController =
      TextEditingController();
  final TextEditingController handoverDateController = TextEditingController();

  final TextEditingController logisticsClearanceDateController =
      TextEditingController();
  final TextEditingController logisticsClearanceNoteController =
      TextEditingController();

  final TextEditingController financeClearanceDateController =
      TextEditingController();
  final TextEditingController financeClearanceNoteController =
      TextEditingController();

  final TextEditingController hrClearanceDateController =
      TextEditingController();
  final TextEditingController hrClearanceNoteController =
      TextEditingController();

  final TextEditingController salesClearanceDateController =
      TextEditingController();
  final TextEditingController salesClearanceNoteController =
      TextEditingController();

  final TextEditingController itClearanceDateController =
      TextEditingController();
  final TextEditingController itClearanceNoteController =
      TextEditingController();

  final TextEditingController exitFormDateController = TextEditingController();

  String selectedReasonType = 'resignation';

  bool logisticsClearance = false;
  bool financeClearance = false;
  bool hrClearance = false;
  bool salesClearance = false;
  bool itClearance = false;

  File? logisticsSignatureFile;
  File? financeSignatureFile;
  File? hrSignatureFile;
  File? salesSignatureFile;
  File? itSignatureFile;
  File? employeeSignatureFile;

  String? logisticsSignatureUrl;
  String? financeSignatureUrl;
  String? hrSignatureUrl;
  String? salesSignatureUrl;
  String? itSignatureUrl;
  String? employeeSignatureUrl;

  final ImagePicker picker = ImagePicker();

  bool get isEditMode => widget.exitId != null;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  @override
  void dispose() {
    exitDateController.dispose();
    reasonController.dispose();
    exitReasonNoteController.dispose();
    assetResponsibilityController.dispose();
    handoverDateController.dispose();

    logisticsClearanceDateController.dispose();
    logisticsClearanceNoteController.dispose();

    financeClearanceDateController.dispose();
    financeClearanceNoteController.dispose();

    hrClearanceDateController.dispose();
    hrClearanceNoteController.dispose();

    salesClearanceDateController.dispose();
    salesClearanceNoteController.dispose();

    itClearanceDateController.dispose();
    itClearanceNoteController.dispose();

    exitFormDateController.dispose();
    super.dispose();
  }

  Future<void> initializePage() async {
    setState(() {
      isLoading = true;
    });

    await getStaff();

    if (isEditMode) {
      await getExitDetails();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getStaff() async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<Map<String, dynamic>> tempList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'];

        if (data is List) {
          for (final item in data) {
            tempList.add({
              'id': item['id'],
              'name': item['name'] ?? '',
              'email': item['email'] ?? '',
              'designation': item['designation'] ?? '',
              'image': item['image'],
              'approval_status': item['approval_status'],
            });
          }
        }

        setState(() {
          staffList = tempList;
        });
      } else {
        showMessage('Failed to load staff list');
      }
    } catch (e) {
      showMessage('Error loading staff list');
    } finally {
      setState(() {
        isStaffLoading = false;
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    if (text.contains('T')) {
      return text.split('T').first;
    }
    return text;
  }

  String buildFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final cleanedApi = api.endsWith('/') ? api.substring(0, api.length - 1) : api;
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return '$cleanedApi$cleanedPath';
  }

  String? extractId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toString();
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      if (value['id'] != null) return value['id'].toString();
      if (value['pk'] != null) return value['pk'].toString();
      if (value['user_id'] != null) return value['user_id'].toString();
    }
    return null;
  }

  bool extractBool(dynamic value) {
    if (value == true) return true;
    if (value == false) return false;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic>? getStaffById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return staffList.firstWhere((e) => e['id'].toString() == id);
    } catch (e) {
      return null;
    }
  }

  String getStaffDisplayText(Map<String, dynamic> staff) {
    final name = staff['name']?.toString() ?? '';
    final designation = staff['designation']?.toString() ?? '';
    final email = staff['email']?.toString() ?? '';

    if (designation.isNotEmpty && email.isNotEmpty) {
      return '$name - $designation - $email';
    } else if (designation.isNotEmpty) {
      return '$name - $designation';
    } else if (email.isNotEmpty) {
      return '$name - $email';
    }
    return name;
  }

  Future<void> getExitDetails() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/employee/exit/edit/${widget.exitId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic data;
        if (decoded is Map<String, dynamic>) {
          data = decoded['data'] ??
              decoded['results'] ??
              decoded['result'] ??
              decoded['item'] ??
              decoded;
        } else {
          data = decoded;
        }

        if (data is Map<String, dynamic>) {
          setState(() {
            selectedEmployeeId = extractId(data['employee']);
            exitDateController.text = formatDate(data['exit_date']);
            reasonController.text = data['reason']?.toString() ?? '';
            selectedReasonType =
                data['reason_type']?.toString() ?? 'resignation';
            exitReasonNoteController.text =
                data['exit_reason_note']?.toString() ?? '';
            assetResponsibilityController.text =
                data['asset_responsibility']?.toString() ?? '';

            selectedHandoverToId = extractId(data['handover_to']);
            handoverDateController.text = formatDate(data['handover_date']);

            logisticsClearance = extractBool(data['logistics_clearance']);
            logisticsClearanceDateController.text =
                formatDate(data['logistics_clearance_date']);
            selectedLogisticsClearanceById =
                extractId(data['logistics_clearance_by']);
            logisticsClearanceNoteController.text =
                data['logistics_clearance_note']?.toString() ?? '';
            logisticsSignatureUrl = buildFullImageUrl(
              data['logistics_clearence_signature']?.toString(),
            );
            logisticsSignatureFile = null;

            financeClearance = extractBool(data['finance_clearance']);
            financeClearanceDateController.text =
                formatDate(data['finance_clearance_date']);
            selectedFinanceClearanceById =
                extractId(data['finance_clearance_by']);
            financeClearanceNoteController.text =
                data['finance_clearance_note']?.toString() ?? '';
            financeSignatureUrl = buildFullImageUrl(
              data['finance_clearance_signature']?.toString(),
            );
            financeSignatureFile = null;

            hrClearance = extractBool(data['hr_clearance']);
            hrClearanceDateController.text =
                formatDate(data['hr_clearance_date']);
            selectedHrClearanceById = extractId(data['hr_clearance_by']);
            hrClearanceNoteController.text =
                data['hr_clearance_note']?.toString() ?? '';
            hrSignatureUrl = buildFullImageUrl(
              data['hr_clearance_signature']?.toString(),
            );
            hrSignatureFile = null;

            salesClearance = extractBool(data['sales_clearance']);
            salesClearanceDateController.text =
                formatDate(data['sales_clearance_date']);
            selectedSalesClearanceById =
                extractId(data['sales_clearance_by']);
            salesClearanceNoteController.text =
                data['sales_clearance_note']?.toString() ?? '';
            salesSignatureUrl = buildFullImageUrl(
              data['sales_clearance_signature']?.toString(),
            );
            salesSignatureFile = null;

            itClearance = extractBool(data['it_clearance']);
            itClearanceDateController.text =
                formatDate(data['it_clearance_date']);
            selectedItClearanceById = extractId(data['it_clearance_by']);
            itClearanceNoteController.text =
                data['it_clearance_note']?.toString() ?? '';
            itSignatureUrl = buildFullImageUrl(
              data['it_clearance_signature']?.toString(),
            );
            itSignatureFile = null;

            employeeSignatureUrl = buildFullImageUrl(
              data['employee_signature']?.toString(),
            );
            employeeSignatureFile = null;

            exitFormDateController.text = formatDate(data['exit_form_date']);
          });
        } else {
          showMessage('Invalid edit response format');
        }
      } else {
        showMessage('Failed to load employee exit details');
      }
    } catch (e) {
      showMessage('Error loading employee exit details');
    }
  }

  void clearAllFields() {
    _formKey.currentState?.reset();

    setState(() {
      selectedEmployeeId = null;
      selectedHandoverToId = null;
      selectedLogisticsClearanceById = null;
      selectedFinanceClearanceById = null;
      selectedHrClearanceById = null;
      selectedSalesClearanceById = null;
      selectedItClearanceById = null;

      exitDateController.clear();
      reasonController.clear();
      exitReasonNoteController.clear();
      assetResponsibilityController.clear();
      handoverDateController.clear();

      logisticsClearanceDateController.clear();
      logisticsClearanceNoteController.clear();

      financeClearanceDateController.clear();
      financeClearanceNoteController.clear();

      hrClearanceDateController.clear();
      hrClearanceNoteController.clear();

      salesClearanceDateController.clear();
      salesClearanceNoteController.clear();

      itClearanceDateController.clear();
      itClearanceNoteController.clear();

      exitFormDateController.clear();

      selectedReasonType = 'resignation';

      logisticsClearance = false;
      financeClearance = false;
      hrClearance = false;
      salesClearance = false;
      itClearance = false;

      logisticsSignatureFile = null;
      financeSignatureFile = null;
      hrSignatureFile = null;
      salesSignatureFile = null;
      itSignatureFile = null;
      employeeSignatureFile = null;

      logisticsSignatureUrl = null;
      financeSignatureUrl = null;
      hrSignatureUrl = null;
      salesSignatureUrl = null;
      itSignatureUrl = null;
      employeeSignatureUrl = null;
    });
  }

  Future<void> pickDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.trim().isNotEmpty) {
      try {
        final parts = controller.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      controller.text = formatted;
      setState(() {});
    }
  }

  Future<void> pickImage(String type) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      final file = File(image.path);

      if (type == 'logistics') logisticsSignatureFile = file;
      if (type == 'finance') financeSignatureFile = file;
      if (type == 'hr') hrSignatureFile = file;
      if (type == 'sales') salesSignatureFile = file;
      if (type == 'it') itSignatureFile = file;
      if (type == 'employee') employeeSignatureFile = file;
    });
  }

  Future<void> saveExitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedEmployeeId == null || selectedEmployeeId!.isEmpty) {
      showMessage('Please select employee');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final token = await getTokenFromPrefs();

      final uri = isEditMode
          ? Uri.parse('$api/api/employee/exit/edit/${widget.exitId}/')
          : Uri.parse('$api/api/employee/exit/add/');

      final request = http.MultipartRequest(
        isEditMode ? 'PUT' : 'POST',
        uri,
      );

      request.headers['Authorization'] = 'Bearer $token';

      void addField(String key, String value) {
        if (value.trim().isNotEmpty) {
          request.fields[key] = value.trim();
        }
      }

      void addDropdownField(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          request.fields[key] = value.trim();
        }
      }

      addDropdownField('employee', selectedEmployeeId);
      addField('exit_date', exitDateController.text);
      addField('reason', reasonController.text);
      addField('reason_type', selectedReasonType);
      addField('exit_reason_note', exitReasonNoteController.text);
      addField('asset_responsibility', assetResponsibilityController.text);

      addDropdownField('handover_to', selectedHandoverToId);
      addField('handover_date', handoverDateController.text);

      request.fields['logistics_clearance'] = logisticsClearance.toString();
      addField(
        'logistics_clearance_date',
        logisticsClearanceDateController.text,
      );
      addDropdownField(
        'logistics_clearance_by',
        selectedLogisticsClearanceById,
      );
      addField(
        'logistics_clearance_note',
        logisticsClearanceNoteController.text,
      );

      request.fields['finance_clearance'] = financeClearance.toString();
      addField('finance_clearance_date', financeClearanceDateController.text);
      addDropdownField(
        'finance_clearance_by',
        selectedFinanceClearanceById,
      );
      addField('finance_clearance_note', financeClearanceNoteController.text);

      request.fields['hr_clearance'] = hrClearance.toString();
      addField('hr_clearance_date', hrClearanceDateController.text);
      addDropdownField('hr_clearance_by', selectedHrClearanceById);
      addField('hr_clearance_note', hrClearanceNoteController.text);

      request.fields['sales_clearance'] = salesClearance.toString();
      addField('sales_clearance_date', salesClearanceDateController.text);
      addDropdownField('sales_clearance_by', selectedSalesClearanceById);
      addField('sales_clearance_note', salesClearanceNoteController.text);

      request.fields['it_clearance'] = itClearance.toString();
      addField('it_clearance_date', itClearanceDateController.text);
      addDropdownField('it_clearance_by', selectedItClearanceById);
      addField('it_clearance_note', itClearanceNoteController.text);

      addField('exit_form_date', exitFormDateController.text);

      if (logisticsSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logistics_clearence_signature',
            logisticsSignatureFile!.path,
          ),
        );
      }

      if (financeSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'finance_clearance_signature',
            financeSignatureFile!.path,
          ),
        );
      }

      if (hrSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'hr_clearance_signature',
            hrSignatureFile!.path,
          ),
        );
      }

      if (salesSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'sales_clearance_signature',
            salesSignatureFile!.path,
          ),
        );
      }

      if (itSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'it_clearance_signature',
            itSignatureFile!.path,
          ),
        );
      }

      if (employeeSignatureFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'employee_signature',
            employeeSignatureFile!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        showMessage(
          isEditMode
              ? 'Employee exit updated successfully'
              : 'Employee exit added successfully',
        );

        if (widget.popOnSuccess) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          clearAllFields();
        }
      } else {
        showMessage('Failed: ${response.body}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(title, icon),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool isDateField = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: isDateField
              ? IconButton(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF2563EB),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStaffDropdown({
    required String label,
    required String? selectedId,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final selectedStaff = getStaffById(selectedId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownSearch<Map<String, dynamic>>(
        selectedItem: selectedStaff,
        items: staffList,
        itemAsString: (item) => getStaffDisplayText(item),
        validator: (value) {
          if (validator != null) {
            return validator(value?['id']?.toString());
          }
          return null;
        },
        onChanged: (value) {
          onChanged(value?['id']?.toString());
        },
        popupProps: PopupProps.modalBottomSheet(
          showSearchBox: true,
          fit: FlexFit.loose,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search staff...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget buildImagePickerCard({
    required String title,
    required String type,
    File? file,
    String? imageUrl,
  }) {
    final bool hasLocalFile = file != null;
    final bool hasNetworkImage =
        imageUrl != null && imageUrl.trim().isNotEmpty && !hasLocalFile;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: hasLocalFile
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : hasNetworkImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 38,
                          color: Colors.grey,
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => pickImage(type),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Signature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildClearanceSection({
    required String title,
    required bool value,
    required Function(bool) onToggle,
    required TextEditingController dateController,
    required String? selectedByValue,
    required Function(String?) onByChanged,
    required TextEditingController noteController,
    required File? signatureFile,
    required String? signatureUrl,
    required String imageType,
    required IconData icon,
  }) {
    return buildSectionCard(
      title: title,
      icon: icon,
      children: [
        buildSwitchTile(
          title: '$title Status',
          value: value,
          onChanged: onToggle,
        ),
        buildTextField(
          controller: dateController,
          label: '$title Date',
          readOnly: true,
          isDateField: true,
          onTap: () => pickDate(dateController),
        ),
        buildStaffDropdown(
          label: '$title By',
          selectedId: selectedByValue,
          onChanged: onByChanged,
        ),
        buildTextField(
          controller: noteController,
          label: '$title Note',
          maxLines: 3,
        ),
        buildImagePickerCard(
          title: '$title Signature',
          type: imageType,
          file: signatureFile,
          imageUrl: signatureUrl,
        ),
      ],
    );
  }

   Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } 
    else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
      );
    } 

    else if (dep == "HR") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
      );
    } 
    else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
         leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF111827)),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          isEditMode ? 'Edit Employee Exit' : 'Add Employee Exit',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  if (isStaffLoading) const LinearProgressIndicator(),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1E3A8A),
                                  Color(0xFF2563EB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.16),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.assignment_ind_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditMode
                                            ? 'Update Employee Exit'
                                            : 'Create Employee Exit',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Fill exit, handover, clearance and signature details',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          buildSectionCard(
                            title: 'Basic Exit Details',
                            icon: Icons.badge_outlined,
                            children: [
                              buildStaffDropdown(
                                label: 'Employee',
                                selectedId: selectedEmployeeId,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Employee is required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    selectedEmployeeId = value;
                                  });
                                },
                              ),
                              buildTextField(
                                controller: exitDateController,
                                label: 'Exit Date',
                                readOnly: true,
                                isDateField: true,
                                onTap: () => pickDate(exitDateController),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Exit date is required';
                                  }
                                  return null;
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: DropdownButtonFormField<String>(
                                  value: selectedReasonType,
                                  decoration: InputDecoration(
                                    labelText: 'Reason Type',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'resignation',
                                      child: Text('Resignation'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'termination',
                                      child: Text('Termination'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'absconding',
                                      child: Text('Absconding'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedReasonType =
                                          value ?? 'resignation';
                                    });
                                  },
                                ),
                              ),
                              buildTextField(
                                controller: reasonController,
                                label: 'Reason',
                                maxLines: 3,
                              ),
                              buildTextField(
                                controller: exitReasonNoteController,
                                label: 'Exit Reason Note',
                                maxLines: 3,
                              ),
                              buildTextField(
                                controller: assetResponsibilityController,
                                label: 'Asset Responsibility',
                                maxLines: 3,
                              ),
                              buildTextField(
                                controller: exitFormDateController,
                                label: 'Exit Form Date',
                                readOnly: true,
                                isDateField: true,
                                onTap: () => pickDate(exitFormDateController),
                              ),
                            ],
                          ),
                          buildSectionCard(
                            title: 'Handover Details',
                            icon: Icons.handshake_outlined,
                            children: [
                              buildStaffDropdown(
                                label: 'Handover To',
                                selectedId: selectedHandoverToId,
                                onChanged: (value) {
                                  setState(() {
                                    selectedHandoverToId = value;
                                  });
                                },
                              ),
                              buildTextField(
                                controller: handoverDateController,
                                label: 'Handover Date',
                                readOnly: true,
                                isDateField: true,
                                onTap: () => pickDate(handoverDateController),
                              ),
                            ],
                          ),
                          buildClearanceSection(
                            title: 'Logistics Clearance',
                            value: logisticsClearance,
                            onToggle: (value) {
                              setState(() {
                                logisticsClearance = value;
                              });
                            },
                            dateController: logisticsClearanceDateController,
                            selectedByValue: selectedLogisticsClearanceById,
                            onByChanged: (value) {
                              setState(() {
                                selectedLogisticsClearanceById = value;
                              });
                            },
                            noteController: logisticsClearanceNoteController,
                            signatureFile: logisticsSignatureFile,
                            signatureUrl: logisticsSignatureUrl,
                            imageType: 'logistics',
                            icon: Icons.local_shipping_outlined,
                          ),
                          buildClearanceSection(
                            title: 'Finance Clearance',
                            value: financeClearance,
                            onToggle: (value) {
                              setState(() {
                                financeClearance = value;
                              });
                            },
                            dateController: financeClearanceDateController,
                            selectedByValue: selectedFinanceClearanceById,
                            onByChanged: (value) {
                              setState(() {
                                selectedFinanceClearanceById = value;
                              });
                            },
                            noteController: financeClearanceNoteController,
                            signatureFile: financeSignatureFile,
                            signatureUrl: financeSignatureUrl,
                            imageType: 'finance',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          buildClearanceSection(
                            title: 'HR Clearance',
                            value: hrClearance,
                            onToggle: (value) {
                              setState(() {
                                hrClearance = value;
                              });
                            },
                            dateController: hrClearanceDateController,
                            selectedByValue: selectedHrClearanceById,
                            onByChanged: (value) {
                              setState(() {
                                selectedHrClearanceById = value;
                              });
                            },
                            noteController: hrClearanceNoteController,
                            signatureFile: hrSignatureFile,
                            signatureUrl: hrSignatureUrl,
                            imageType: 'hr',
                            icon: Icons.people_alt_outlined,
                          ),
                          buildClearanceSection(
                            title: 'Sales Clearance',
                            value: salesClearance,
                            onToggle: (value) {
                              setState(() {
                                salesClearance = value;
                              });
                            },
                            dateController: salesClearanceDateController,
                            selectedByValue: selectedSalesClearanceById,
                            onByChanged: (value) {
                              setState(() {
                                selectedSalesClearanceById = value;
                              });
                            },
                            noteController: salesClearanceNoteController,
                            signatureFile: salesSignatureFile,
                            signatureUrl: salesSignatureUrl,
                            imageType: 'sales',
                            icon: Icons.trending_up_outlined,
                          ),
                          buildClearanceSection(
                            title: 'IT Clearance',
                            value: itClearance,
                            onToggle: (value) {
                              setState(() {
                                itClearance = value;
                              });
                            },
                            dateController: itClearanceDateController,
                            selectedByValue: selectedItClearanceById,
                            onByChanged: (value) {
                              setState(() {
                                selectedItClearanceById = value;
                              });
                            },
                            noteController: itClearanceNoteController,
                            signatureFile: itSignatureFile,
                            signatureUrl: itSignatureUrl,
                            imageType: 'it',
                            icon: Icons.computer_outlined,
                          ),
                          buildSectionCard(
                            title: 'Employee Signature',
                            icon: Icons.draw_outlined,
                            children: [
                              buildImagePickerCard(
                                title: 'Employee Signature',
                                type: 'employee',
                                file: employeeSignatureFile,
                                imageUrl: employeeSignatureUrl,
                              ),
                            ],
                          ),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveExitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    )
                  : Text(
                      isEditMode ? 'Update Employee Exit' : 'Save Employee Exit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}