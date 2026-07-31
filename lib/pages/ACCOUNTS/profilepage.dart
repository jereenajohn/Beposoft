import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isLoading = true;
  String? errorMessage;
  StaffProfile? profile;

  Map<int, String> departmentMap = {};
  Map<int, String> managerMap = {};
  Map<int, String> warehouseMap = {};
  Map<int, String> familyMap = {};
  Map<int, String> stateMap = {};

  final String viewProfileUrl = "$api/api/profile/";

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> loadInitialData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await Future.wait([
        getDepartments(),
        getManagers(),
        getWarehouses(),
        getFamilies(),
        getStates(),
      ]);

      await getProfileData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
        isLoading = false;
      });
    }
  }

  Future<void> getProfileData() async {
    final token = await gettokenFromPrefs();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token not found");
    }

    final response = await http.get(
      Uri.parse(viewProfileUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        setState(() {
          profile = StaffProfile.fromJson(decoded['data']);
          isLoading = false;
        });
      } else {
        throw Exception("Invalid profile response");
      }
    } else if (response.statusCode == 401) {
      throw Exception("Session expired. Please login again.");
    } else {
      throw Exception("Failed to load profile. Status: ${response.statusCode}");
    }
  }

  Future<void> getDepartments() async {
    final token = await gettokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/departments/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] ?? [];

      departmentMap = {
        for (final item in data)
          if (item['id'] != null) item['id']: item['name']?.toString() ?? '-'
      };
    }
  }

  Future<void> getManagers() async {
    final token = await gettokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/supervisors/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] ?? [];

      managerMap = {
        for (final item in data)
          if (item['id'] != null) item['id']: item['name']?.toString() ?? '-'
      };
    }
  }

  Future<void> getWarehouses() async {
    final token = await gettokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/warehouse/add/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed is List ? parsed : [];

      warehouseMap = {
        for (final item in data)
          if (item['id'] != null) item['id']: item['name']?.toString() ?? '-'
      };
    }
  }

  Future<void> getFamilies() async {
    final token = await gettokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/familys/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] ?? [];

      familyMap = {
        for (final item in data)
          if (item['id'] != null) item['id']: item['name']?.toString() ?? '-'
      };
    }
  }

  Future<void> getStates() async {
    final token = await gettokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/states/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] ?? [];

      stateMap = {
        for (final item in data)
          if (item['id'] != null) item['id']: item['name']?.toString() ?? '-'
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (!mounted) return;

    Widget page;

    if (dep == "BDO") {
      page = bdo_dashbord();
    } else if (dep == "BDM") {
      page = bdm_dashbord();
    } else if (dep == "warehouse") {
      page = WarehouseDashboard();
    } else if (dep == "CEO" || dep == "COO") {
      page = ceo_dashboard();
    } else if (dep == "CSO") {
      page = cso_dashboard();
    } 
     else if (dep == "HR") {
      page = HrDashboard();
    } 
     else if (dep == "Information Technology") {
      page = admin_dashboard();
    } 
    
     else if (dep == "ADMIN") {
      page = admin_dashboard();
    } 
     else if (dep == "Warehouse Admin") {
      page = WarehouseAdmin();
    } 
     else if (dep == "Accounts / Accounting") {
      page = admin_dashboard();
    } 

        else if (dep == "Marketing") {
      page = marketing_dashboard();
    } 
    
    
     else if (dep == "SD") {
      page = SdDashboard();
    } else if (dep == "Warehouse Admin") {
      page = WarehouseAdmin();
    } else {
      page = dashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '$api$imagePath';
  }

  String value(dynamic data) {
    if (data == null) return "-";
    final text = data.toString().trim();
    if (text.isEmpty || text == "null") return "-";
    return text;
  }

  String yesNo(bool? value) {
    if (value == null) return "-";
    return value ? "Yes" : "No";
  }

  String nameFromMap(Map<int, String> map, dynamic id) {
    if (id == null) return "-";
    final parsedId = int.tryParse(id.toString());
    if (parsedId == null) return "-";
    return map[parsedId] ?? id.toString();
  }

  String allocatedStateNames(List<dynamic>? ids) {
    if (ids == null || ids.isEmpty) return "-";

    return ids.map((id) {
      final parsedId = int.tryParse(id.toString());
      if (parsedId == null) return id.toString();
      return stateMap[parsedId] ?? id.toString();
    }).join(", ");
  }

  void _showProfileImage() {
    final imageUrl = getImageUrl(profile?.image);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 145,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage('lib/assets/profile.png')
                          as ImageProvider,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;

    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF111827),
            ),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              tooltip: "Refresh",
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF111827),
              ),
              onPressed: loadInitialData,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _buildErrorState()
                : p == null
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: loadInitialData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            children: [
                              _buildHeader(p),
                              Transform.translate(
                                offset: const Offset(0, -22),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      _buildQuickInfoCard(p),
                                      const SizedBox(height: 14),
                                      _buildSection(
                                        title: "Personal Details",
                                        icon: Icons.person_rounded,
                                        items: [
                                            // InfoItem(
                                            //   Icons.badge_outlined,
                                            //   "Employee ID",
                                            //   value(p.eid),
                                            // ),
                                          InfoItem(
                                            Icons.confirmation_number_outlined,
                                            "Staff ID",
                                            value(p.staffId),
                                          ),
                                          InfoItem(
                                            Icons.person_outline,
                                            "Name",
                                            value(p.name),
                                          ),
                                          InfoItem(
                                            Icons.account_circle_outlined,
                                            "Username",
                                            value(p.username),
                                          ),
                                          // InfoItem(
                                          //   Icons.email_outlined,
                                          //   "Email",
                                          //   value(p.email),
                                          // ),
                                          InfoItem(
                                            Icons.phone_outlined,
                                            "Phone",
                                            value(p.phone),
                                          ),
                                          InfoItem(
                                            Icons.phone_android_outlined,
                                            "Alternate Number",
                                            value(p.alternateNumber),
                                          ),
                                          InfoItem(
                                            Icons.cake_outlined,
                                            "Date of Birth",
                                            value(p.dateOfBirth),
                                          ),
                                          InfoItem(
                                            Icons.wc_outlined,
                                            "Gender",
                                            value(p.gender),
                                          ),
                                          InfoItem(
                                            Icons.favorite_border_rounded,
                                            "Marital Status",
                                            value(p.maritalStatus),
                                          ),
                                          InfoItem(
                                            Icons.bloodtype_outlined,
                                            "Blood Group",
                                            value(p.bloodGroup),
                                          ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Employment Details",
                                        icon: Icons.work_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.business_center_outlined,
                                            "Designation",
                                            value(p.designation),
                                          ),
                                          InfoItem(
                                            Icons.verified_user_outlined,
                                            "Employment Status",
                                            value(p.employmentStatus),
                                          ),
                                          // InfoItem(
                                          //   Icons.workspace_premium_outlined,
                                          //   "Grade",
                                          //   value(p.grade),
                                          // ),
                                          InfoItem(
                                            Icons.check_circle_outline,
                                            "Approval Status",
                                            value(p.approvalStatus),
                                          ),
                                          InfoItem(
                                            Icons.manage_accounts_outlined,
                                            "Manager",
                                            yesNo(p.isManager),
                                          ),
                                          // InfoItem(
                                          //   Icons.apartment_outlined,
                                          //   "Department",
                                          //   nameFromMap(
                                          //     departmentMap,
                                          //     p.departmentId,
                                          //   ),
                                          // ),
                                          InfoItem(
                                            Icons.supervisor_account_outlined,
                                            "Supervisor",
                                            nameFromMap(
                                              managerMap,
                                              p.supervisorId,
                                            ),
                                          ),
                                          InfoItem(
                                            Icons.warehouse_outlined,
                                            "Warehouse",
                                            nameFromMap(
                                              warehouseMap,
                                              p.warehouseId,
                                            ),
                                          ),
                                          InfoItem(
                                            Icons.calendar_today_outlined,
                                            "Join Date",
                                            value(p.joinDate),
                                          ),
                                          InfoItem(
                                            Icons.event_available_outlined,
                                            "Confirmation Date",
                                            value(p.confirmationDate),
                                          ),
                                          InfoItem(
                                            Icons.event_busy_outlined,
                                            "Termination Date",
                                            value(p.terminationDate),
                                          ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Family & Allocation",
                                        icon: Icons.groups_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.family_restroom_outlined,
                                            "Family",
                                            value(p.familyName) != "-"
                                                ? value(p.familyName)
                                                : nameFromMap(
                                                    familyMap,
                                                    p.familyId ?? p.family,
                                                  ),
                                          ),
                                          InfoItem(
                                            Icons.map_outlined,
                                            "Allocated States",
                                            allocatedStateNames(
                                              p.allocatedStates,
                                            ),
                                          ),
                                          InfoItem(
                                            Icons.flag_outlined,
                                            "State",
                                            value(p.state),
                                          ),
                                          InfoItem(
                                            Icons.public_outlined,
                                            "Country",
                                            value(p.country),
                                          ),
                                          // InfoItem(
                                          //   Icons.call_outlined,
                                          //   "Country Code",
                                          //   value(p.countryCode),
                                          // ),
                                          InfoItem(
                                            Icons.language_outlined,
                                            "Country Code ",
                                            value(p.countryCodeName),
                                          ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Address & Location",
                                        icon: Icons.location_on_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.home_outlined,
                                            "Address",
                                            value(p.address),
                                          ),
                                          InfoItem(
                                            Icons.place_outlined,
                                            "Place",
                                            value(p.place),
                                          ),
                                          InfoItem(
                                            Icons.location_city_outlined,
                                            "State",
                                            value(p.state),
                                          ),
                                          InfoItem(
                                            Icons.public_outlined,
                                            "Country",
                                            value(p.country),
                                          ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Identity & Documents",
                                        icon: Icons.assignment_ind_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.credit_card_outlined,
                                            "Aadhar Number",
                                            value(p.aadharNo),
                                          ),
                                          InfoItem(
                                            Icons.badge_outlined,
                                            "PAN Number",
                                            value(p.panNo),
                                          ),
                                          InfoItem(
                                            Icons.drive_eta_outlined,
                                            "Driving License",
                                            value(p.drivingLicense),
                                          ),
                                          InfoItem(
                                            Icons.event_outlined,
                                            "License Expiry Date",
                                            value(p.drivingLicenseExpDate),
                                          ),
                                          InfoItem(
                                            Icons.image_outlined,
                                            "Aadhar Image",
                                            value(p.aadharImage),
                                          ),
                                          InfoItem(
                                            Icons.image_outlined,
                                            "PAN Image",
                                            value(p.panImage),
                                          ),
                                          // InfoItem(
                                          //   Icons.draw_outlined,
                                          //   "Signature",
                                          //   value(p.signatureUp),
                                          // ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Experience & Education",
                                        icon: Icons.school_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.timeline_outlined,
                                            "Experience",
                                            value(p.experience),
                                          ),
                                          InfoItem(
                                            Icons.work_history_outlined,
                                            "Year Experience",
                                            value(p.yrExperience),
                                          ),
                                          InfoItem(
                                            Icons.business_outlined,
                                            "Previous Company",
                                            value(p.previousCompany),
                                          ),
                                          InfoItem(
                                            Icons.school_outlined,
                                            "Education",
                                            value(p.education),
                                          ),
                                          InfoItem(
                                            Icons.description_outlined,
                                            "Experience Letter",
                                            value(p.expLetter),
                                          ),
                                          InfoItem(
                                            Icons.receipt_long_outlined,
                                            "Salary Slip",
                                            value(p.salarySlip),
                                          ),
                                        ],
                                      ),
                                      _buildSection(
                                        title: "Emergency Contact",
                                        icon: Icons.emergency_rounded,
                                        items: [
                                          InfoItem(
                                            Icons.person_outline,
                                            "Emergency Contact Name",
                                            value(p.emergencyContactName),
                                          ),
                                          InfoItem(
                                            Icons.phone_outlined,
                                            "Emergency Contact Number",
                                            value(p.emergencyContactNumber),
                                          ),
                                          InfoItem(
                                            Icons.person_outline,
                                            "Emergency Contact Name 1",
                                            value(p.emergencyContactName1),
                                          ),
                                          InfoItem(
                                            Icons.phone_outlined,
                                            "Emergency Contact Number 1",
                                            value(p.emergencyContactNumber1),
                                          ),
                                        ],
                                      ),
                                      // _buildSection(
                                      //   title: "System Information",
                                      //   icon: Icons.settings_rounded,
                                      //   items: [
                                      //     InfoItem(
                                      //       Icons.numbers_outlined,
                                      //       "User ID",
                                      //       value(p.id),
                                      //     ),
                                      //     InfoItem(
                                      //       Icons.lock_outline_rounded,
                                      //       "Password",
                                      //       "Protected",
                                      //     ),
                                      //     InfoItem(
                                      //       Icons.image_outlined,
                                      //       "Profile Image",
                                      //       value(p.image),
                                      //     ),
                                      //     InfoItem(
                                      //       Icons.calendar_month_outlined,
                                      //       "Created At",
                                      //       value(p.createdAt),
                                      //     ),
                                      //     InfoItem(
                                      //       Icons.update_outlined,
                                      //       "Updated At",
                                      //       value(p.updatedAt),
                                      //     ),
                                      //   ],
                                      // ),
                                      const SizedBox(height: 26),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildHeader(StaffProfile p) {
    final imageUrl = getImageUrl(p.image);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0F4C81),
            Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showProfileImage,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage('lib/assets/profile.png')
                        as ImageProvider,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value(p.name),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              value(p.designation),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // const SizedBox(height: 10),
          // Text(
          //   "Email: ${value(p.email)}",
          //   style: TextStyle(
          //     fontSize: 13,
          //     color: Colors.white.withOpacity(0.9),
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(StaffProfile p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildMiniStat(
            Icons.phone_iphone_rounded,
            "Phone",
            value(p.phone),
          ),
          _buildDivider(),
          _buildMiniStat(
            Icons.email_rounded,
            "Staff ID",
            value(p.staffId),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 44,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<InfoItem> items,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => _buildInfoTile(item)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(InfoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 21,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadInitialData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No profile data found",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class InfoItem {
  final IconData icon;
  final String label;
  final String value;

  InfoItem(this.icon, this.label, this.value);
}

class StaffProfile {
  final int? id;
  final String? eid;
  final String? name;
  final String? username;
  final String? email;
  final String? phone;
  final String? alternateNumber;
  final String? password;
  final String? image;
  final String? dateOfBirth;
  final List<dynamic>? allocatedStates;
  final String? gender;
  final String? maritalStatus;
  final String? drivingLicense;
  final String? drivingLicenseExpDate;
  final String? employmentStatus;
  final String? designation;
  final String? grade;
  final String? address;
  final String? state;
  final String? country;
  final String? joinDate;
  final String? confirmationDate;
  final String? terminationDate;
  final int? supervisorId;
  final int? departmentId;
  final bool? isManager;
  final int? warehouseId;
  final int? countryCode;
  final String? signatureUp;
  final String? emergencyContactName1;
  final String? emergencyContactNumber1;
  final String? approvalStatus;
  final int? family;
  final String? createdAt;
  final String? updatedAt;
  final int? familyId;
  final String? familyName;
  final String? countryCodeName;
  final dynamic yrExperience;
  final String? staffId;
  final String? place;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final dynamic experience;
  final String? expLetter;
  final String? previousCompany;
  final String? bloodGroup;
  final String? education;
  final String? salarySlip;
  final String? aadharNo;
  final String? panNo;
  final String? aadharImage;
  final String? panImage;

  StaffProfile({
    this.id,
    this.eid,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.alternateNumber,
    this.password,
    this.image,
    this.dateOfBirth,
    this.allocatedStates,
    this.gender,
    this.maritalStatus,
    this.drivingLicense,
    this.drivingLicenseExpDate,
    this.employmentStatus,
    this.designation,
    this.grade,
    this.address,
    this.state,
    this.country,
    this.joinDate,
    this.confirmationDate,
    this.terminationDate,
    this.supervisorId,
    this.departmentId,
    this.isManager,
    this.warehouseId,
    this.countryCode,
    this.signatureUp,
    this.emergencyContactName1,
    this.emergencyContactNumber1,
    this.approvalStatus,
    this.family,
    this.createdAt,
    this.updatedAt,
    this.familyId,
    this.familyName,
    this.countryCodeName,
    this.yrExperience,
    this.staffId,
    this.place,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.experience,
    this.expLetter,
    this.previousCompany,
    this.bloodGroup,
    this.education,
    this.salarySlip,
    this.aadharNo,
    this.panNo,
    this.aadharImage,
    this.panImage,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      id: json['id'],
      eid: json['eid']?.toString(),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      alternateNumber: json['alternate_number']?.toString(),
      password: json['password']?.toString(),
      image: json['image']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      allocatedStates:
          json['allocated_states'] is List ? json['allocated_states'] : [],
      gender: json['gender']?.toString(),
      maritalStatus: json['marital_status']?.toString(),
      drivingLicense: json['driving_license']?.toString(),
      drivingLicenseExpDate: json['driving_license_exp_date']?.toString(),
      employmentStatus: json['employment_status']?.toString(),
      designation: json['designation']?.toString(),
      grade: json['grade']?.toString(),
      address: json['address']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      joinDate: json['join_date']?.toString(),
      confirmationDate: json['confirmation_date']?.toString(),
      terminationDate: json['termination_date']?.toString(),
      supervisorId: json['supervisor_id'],
      departmentId: json['department_id'],
      isManager: json['is_manager'],
      warehouseId: json['warehouse_id'],
      countryCode: json['country_code'],
      signatureUp: json['signatur_up']?.toString(),
      emergencyContactName1: json['emergency_contact_name1']?.toString(),
      emergencyContactNumber1: json['emergency_contact_number1']?.toString(),
      approvalStatus: json['approval_status']?.toString(),
      family: json['family'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      familyId: json['family_id'],
      familyName: json['family_name']?.toString(),
      countryCodeName: json['country_code_name']?.toString(),
      yrExperience: json['yr_experience'],
      staffId: json['staff_id']?.toString(),
      place: json['place']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactNumber: json['emergency_contact_number']?.toString(),
      experience: json['experience'],
      expLetter: json['exp_letter']?.toString(),
      previousCompany: json['previous_company']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      education: json['education']?.toString(),
      salarySlip: json['salrary_slip']?.toString(),
      aadharNo: json['aadhar_no']?.toString(),
      panNo: json['pan_no']?.toString(),
      aadharImage: json['aadhar_image']?.toString(),
      panImage: json['pan_image']?.toString(),
    );
  }
}