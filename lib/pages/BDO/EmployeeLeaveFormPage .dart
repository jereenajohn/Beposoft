// import 'dart:convert';
// import 'package:beposoft/pages/api.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class EmployeeLeaveFormPage extends StatefulWidget {
//   const EmployeeLeaveFormPage({super.key});

//   @override
//   State<EmployeeLeaveFormPage> createState() => _EmployeeLeaveFormPageState();
// }

// class _EmployeeLeaveFormPageState extends State<EmployeeLeaveFormPage> {
//   final _formKey = GlobalKey<FormState>();

//   bool isLoading = false;
//   bool isSaving = false;

//   List<Map<String, dynamic>> leaveList = [];

//   List<Map<String, dynamic>> supervisorList = [];
//   String? selectedManagerId;
//   bool isSupervisorLoading = false;

//   String selectedLeaveType = 'casual_leave';

//   final startDateController = TextEditingController();
//   final endDateController = TextEditingController();
//   final reasonController = TextEditingController();
//   final noOfDaysController = TextEditingController();
//   final managerController = TextEditingController();

//   final leaveTypes = const [
//     {'value': 'sick_leave', 'label': 'Sick Leave'},
//     {'value': 'casual_leave', 'label': 'Casual Leave'},
//     {'value': 'earned_leave', 'label': 'Earned Leave'},
//     {'value': 'maternity_leave', 'label': 'Maternity Leave'},
//     {'value': 'paternity_leave', 'label': 'Paternity Leave'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     getEmployeeLeaves();
//     getSupervisors();
//   }

//   @override
//   void dispose() {
//     startDateController.dispose();
//     endDateController.dispose();
//     reasonController.dispose();
//     noOfDaysController.dispose();
//     managerController.dispose();
//     super.dispose();
//   }

//   Future<String?> getTokenFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }

//   Future<void> pickDate(TextEditingController controller) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       controller.text =
//           '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
//       setState(() {});
//     }
//   }

//   Future<void> getEmployeeLeaves() async {
//     try {
//       setState(() => isLoading = true);

//       final token = await getTokenFromPrefs();

//       final response = await http.get(
//         Uri.parse('$api/api/employee/leaves/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         List data = [];

//         if (decoded is List) {
//           data = decoded;
//         } else if (decoded is Map<String, dynamic>) {
//           if (decoded['results'] is List) {
//             data = decoded['results'];
//           } else if (decoded['data'] is List) {
//             data = decoded['data'];
//           } else if (decoded['results'] is Map &&
//               decoded['results']['data'] is List) {
//             data = decoded['results']['data'];
//           }
//         }

//         setState(() {
//           leaveList = data.map((e) => Map<String, dynamic>.from(e)).toList();
//         });
//       } else {
//         showMessage('Failed to load leaves');
//       }
//     } catch (e) {
//       showMessage('Error loading leaves');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> postEmployeeLeave() async {
//     if (!_formKey.currentState!.validate()) return;

//     try {
//       setState(() => isSaving = true);

//       final token = await getTokenFromPrefs();

//       final body = {
//         'leave_type': selectedLeaveType,
//         'start_date': startDateController.text.trim(),
//         'end_date': endDateController.text.trim(),
//         'reason': reasonController.text.trim(),
//         'no_of_days': noOfDaysController.text.trim(),
//         'manager': selectedManagerId,
//       };

//       final response = await http.post(
//         Uri.parse('$api/api/employee/leaves/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         showMessage('Leave request submitted successfully');

//         startDateController.clear();
//         endDateController.clear();
//         reasonController.clear();
//         noOfDaysController.clear();
//         selectedManagerId = null;

//         await getEmployeeLeaves();
//       } else {
//         showMessage('Failed: ${response.body}');
//       }
//     } catch (e) {
//       showMessage('Error: $e');
//     } finally {
//       setState(() => isSaving = false);
//     }
//   }

//   Future<void> getSupervisors() async {
//     try {
//       setState(() => isSupervisorLoading = true);

//       final token = await getTokenFromPrefs();

//       final response = await http.get(
//         Uri.parse('$api/api/supervisors/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         final data = decoded['data'];

//         if (data is List) {
//           setState(() {
//             supervisorList =
//                 data.map((e) => Map<String, dynamic>.from(e)).toList();
//           });
//         }
//       } else {
//         showMessage('Failed to load supervisors');
//       }
//     } catch (e) {
//       showMessage('Error loading supervisors');
//     } finally {
//       setState(() => isSupervisorLoading = false);
//     }
//   }

//   Widget buildTextField({
//     required TextEditingController controller,
//     required String label,
//     bool readOnly = false,
//     bool isDate = false,
//     int maxLines = 1,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextFormField(
//         controller: controller,
//         readOnly: readOnly,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         onTap: isDate ? () => pickDate(controller) : null,
//         validator: (value) {
//           if (value == null || value.trim().isEmpty) {
//             return '$label is required';
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: Colors.white,
//           suffixIcon: isDate ? const Icon(Icons.calendar_month) : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildLeaveCard(Map<String, dynamic> item) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         title: Text(
//           item['leave_type']?.toString() ?? '',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           '${item['start_date']} to ${item['end_date']}\n'
//           'Days: ${item['no_of_days']} | Status: ${item['status'] ?? 'pending'}\n'
//           'Reason: ${item['reason'] ?? ''}',
//         ),
//       ),
//     );
//   }

//   void showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: const Color(0xFF111827),
//         title: const Text(
//           'Employee Leave Form',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: getEmployeeLeaves,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             Form(
//               key: _formKey,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   border: Border.all(color: const Color(0xFFE5E7EB)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 14,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Leave Request Details',
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w800,
//                         color: Color(0xFF111827),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedLeaveType,
//                       decoration: InputDecoration(
//                         labelText: 'Leave Type',
//                         filled: true,
//                         fillColor: const Color(0xFFF9FAFB),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       items: leaveTypes.map((item) {
//                         return DropdownMenuItem<String>(
//                           value: item['value'],
//                           child: Text(item['label']!),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedLeaveType = value ?? 'casual_leave';
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 14),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: buildTextField(
//                             controller: startDateController,
//                             label: 'Start Date',
//                             readOnly: true,
//                             isDate: true,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: buildTextField(
//                             controller: endDateController,
//                             label: 'End Date',
//                             readOnly: true,
//                             isDate: true,
//                           ),
//                         ),
//                       ],
//                     ),
//                     buildTextField(
//                       controller: noOfDaysController,
//                       label: 'No Of Days',
//                       keyboardType: TextInputType.number,
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 14),
//                       child: DropdownButtonFormField<String>(
//                         value: selectedManagerId,
//                         decoration: InputDecoration(
//                           labelText: 'Manager',
//                           filled: true,
//                           fillColor: const Color(0xFFF9FAFB),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                         ),
//                         items: supervisorList.map((item) {
//                           return DropdownMenuItem<String>(
//                             value: item['id'].toString(),
//                             child: Text(
//                               '${item['name']} - ${item['department']}',
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedManagerId = value;
//                           });
//                         },
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Manager is required';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     buildTextField(
//                       controller: reasonController,
//                       label: 'Reason',
//                       maxLines: 3,
//                     ),
//                     const SizedBox(height: 4),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 54,
//                       child: ElevatedButton.icon(
//                         onPressed: isSaving ? null : postEmployeeLeave,
//                         // icon: isSaving
//                         //     ? const SizedBox(
//                         //         height: 20,
//                         //         width: 20,
//                         //         child: CircularProgressIndicator(
//                         //           color: Colors.white,
//                         //           strokeWidth: 2,
//                         //         ),
//                         //       )
//                         //     : const Icon(Icons.send_rounded),
//                         label: Text(
//                           isSaving ? 'Submitting...' : 'Submit Leave Request',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 15,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF2563EB),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 22),
//             Row(
//               children: [
//                 const Expanded(
//                   child: Text(
//                     'My Leave Requests',
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w800,
//                       color: Color(0xFF111827),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: getEmployeeLeaves,
//                   icon: const Icon(Icons.refresh_rounded),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             if (isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(30),
//                 child: Center(child: CircularProgressIndicator()),
//               )
//             else if (leaveList.isEmpty)
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     'No leave requests found',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               )
//             else
//               ...leaveList.map((item) => buildLeaveCard(item)),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeLeaveFormPage extends StatefulWidget {
  const EmployeeLeaveFormPage({super.key});

  @override
  State<EmployeeLeaveFormPage> createState() => _EmployeeLeaveFormPageState();
}

class _EmployeeLeaveFormPageState extends State<EmployeeLeaveFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isSaving = false;

  List<Map<String, dynamic>> leaveList = [];
  List<Map<String, dynamic>> supervisorList = [];

  String? selectedManagerId;
  bool isSupervisorLoading = false;
  String selectedLeaveType = 'casual_leave';

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final reasonController = TextEditingController();
  final noOfDaysController = TextEditingController();
  final managerController = TextEditingController();

  final leaveTypes = const [
    {'value': 'sick_leave', 'label': 'Sick Leave'},
    {'value': 'casual_leave', 'label': 'Casual Leave'},
    {'value': 'earned_leave', 'label': 'Earned Leave'},
    {'value': 'maternity_leave', 'label': 'Maternity Leave'},
    {'value': 'paternity_leave', 'label': 'Paternity Leave'},
  ];

  @override
  void initState() {
    super.initState();
    getEmployeeLeaves();
    getSupervisors();
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    reasonController.dispose();
    noOfDaysController.dispose();
    managerController.dispose();
    super.dispose();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> getEmployeeLeaves() async {
    try {
      setState(() => isLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/employee/leaves/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            data = decoded['results'];
          } else if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['results'] is Map &&
              decoded['results']['data'] is List) {
            data = decoded['results']['data'];
          }
        }

        setState(() {
          leaveList = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        showMessage('Failed to load leaves');
      }
    } catch (e) {
      showMessage('Error loading leaves');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> postEmployeeLeave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isSaving = true);

      final token = await getTokenFromPrefs();

      final body = {
        'leave_type': selectedLeaveType,
        'start_date': startDateController.text.trim(),
        'end_date': endDateController.text.trim(),
        'reason': reasonController.text.trim(),
        'no_of_days': noOfDaysController.text.trim(),
        'manager': selectedManagerId,
      };

      final response = await http.post(
        Uri.parse('$api/api/employee/leaves/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage('Leave request submitted successfully');

        startDateController.clear();
        endDateController.clear();
        reasonController.clear();
        noOfDaysController.clear();
        selectedManagerId = null;

        await getEmployeeLeaves();
      } else {
        showMessage('Failed: ${response.body}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> getSupervisors() async {
    try {
      setState(() => isSupervisorLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/managers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];

        if (data is List) {
          setState(() {
            supervisorList =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      } else {
        showMessage('Failed to load managers');
      }
    } catch (e) {
      showMessage('Error loading managers');
    } finally {
      setState(() => isSupervisorLoading = false);
    }
  }

  InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool isDate = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: isDate ? () => pickDate(controller) : null,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
        decoration: inputDecoration(
          label: label,
          icon: icon,
          suffixIcon: isDate
              ? const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF2563EB))
              : null,
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('approved')) return const Color(0xFF16A34A);
    if (value.contains('rejected')) return const Color(0xFFDC2626);
    if (value.contains('pending')) return const Color(0xFFF59E0B);

    return const Color(0xFF6B7280);
  }

  String formatLeaveType(String value) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget buildLeaveCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'pending';
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatLeaveType(item['leave_type']?.toString() ?? ''),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item['start_date']} to ${item['end_date']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timelapse_rounded,
                        size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      'Days: ${item['no_of_days']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reason: ${item['reason'] ?? ''}',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle({
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        centerTitle: false,
        title: const Text(
          'Employee Leave Form',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: getEmployeeLeaves,
        color: const Color(0xFF2563EB),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     gradient: const LinearGradient(
            //       colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(24),
            //     boxShadow: [
            //       BoxShadow(
            //         color: const Color(0xFF2563EB).withOpacity(0.25),
            //         blurRadius: 18,
            //         offset: const Offset(0, 8),
            //       ),
            //     ],
            //   ),
            //   child: const Row(
            //     children: [
            //       Icon(Icons.beach_access_rounded,
            //           color: Colors.white, size: 34),
            //       SizedBox(width: 14),
            //       Expanded(
            //         child: Text(
            //           'Apply leave quickly and track your request status easily.',
            //           style: TextStyle(
            //             color: Colors.white,
            //             fontSize: 15,
            //             fontWeight: FontWeight.w700,
            //             height: 1.35,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 18),

            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                      title: 'Leave Request Details',
                      icon: Icons.edit_calendar_rounded,
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: selectedLeaveType,
                      isExpanded: true,
                      decoration: inputDecoration(
                        label: 'Leave Type',
                        icon: Icons.category_rounded,
                      ),
                      items: leaveTypes.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value ?? 'casual_leave';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: startDateController,
                            label: 'Start Date',
                            readOnly: true,
                            isDate: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            controller: endDateController,
                            label: 'End Date',
                            readOnly: true,
                            isDate: true,
                          ),
                        ),
                      ],
                    ),
                    buildTextField(
                      controller: noOfDaysController,
                      label: 'No Of Days',
                      keyboardType: TextInputType.number,
                      icon: Icons.numbers_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        value: selectedManagerId,
                        isExpanded: true,
                        decoration: inputDecoration(
                          label: isSupervisorLoading
                              ? 'Loading Manager...'
                              : 'Manager',
                          icon: Icons.supervisor_account_rounded,
                        ),
                        items: supervisorList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              '${item['name']} - ${item['department_name']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedManagerId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Manager is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    buildTextField(
                      controller: reasonController,
                      label: 'Reason',
                      maxLines: 3,
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : postEmployeeLeave,
                        icon: isSaving
                            ? const SizedBox(
                                height: 19,
                                width: 19,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          isSaving ? 'Submitting...' : 'Submit Leave Request',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            sectionTitle(
              title: 'My Leave Requests',
              icon: Icons.history_rounded,
              trailing: IconButton(
                onPressed: getEmployeeLeaves,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),

            const SizedBox(height: 12),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (leaveList.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 44,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No leave requests found',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...leaveList.map((item) => buildLeaveCard(item)),
          ],
        ),
      ),
    );
  }
}
