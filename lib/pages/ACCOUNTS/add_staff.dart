import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_Expense.dart';
import 'package:beposoft/pages/ACCOUNTS/update_staff.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class add_staff extends StatefulWidget {
  const add_staff({super.key});

  @override
  State<add_staff> createState() => _add_staffState();
}

class _add_staffState extends State<add_staff> {
  List<Map<String, dynamic>> statess = [];
  String staffId = '';

  List<bool> _checkboxValues = [];
  List<int> _selectedFamily = [];
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> Warehouses = [];
  int? selectedPostingStateId;

  @override
  void initState() {
    super.initState();
    getdepartments();
    getmanegers();
    getstaff();
    getwarehouse();
    getcountry();
    initdata();
  }

  void initdata() async {
    await getstates();
    getfamily();
  }

  var url = "$api/api/add/department/";
  String? selectstate;
  int? selectedStateId;
  List stat = [];
  List<int> dynamicStatid = [];

  TextEditingController name = TextEditingController();
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController alternate_number = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController driving_license = TextEditingController();
  TextEditingController employment_status = TextEditingController();
  TextEditingController designation = TextEditingController();
  TextEditingController grade = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController Country = TextEditingController();
  TextEditingController staff_id = TextEditingController();
  TextEditingController emergency_contact_name = TextEditingController();
  TextEditingController emergency_contact_number = TextEditingController();
  TextEditingController experience = TextEditingController();
  TextEditingController previous_company = TextEditingController();
  TextEditingController education = TextEditingController();
  TextEditingController aadhar_no = TextEditingController();
  TextEditingController pan_no = TextEditingController();
  TextEditingController place = TextEditingController();
  List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  String? selectedBloodGroup;
  File? selectedExpLetter;
  File? selectedSalarySlip;

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  List<String> gender = ["Female", 'Male', 'Other'];
  String selectgender = "Female";
  List<String> material = ["Married", 'Single', 'Other'];
  String selectmarital = "Single";
  List<String> approval = ["approved", 'disapproved'];
  String approvalstatus = "approved";

  DateTime selectedDate = DateTime.now();
  var date4;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
        date4 = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  DateTime selecteExp = DateTime.now();
  DateTime selectejoin = DateTime.now();
  DateTime selecteconf = DateTime.now();

  var date3;
  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selecteExp,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selecteExp) {
      setState(() {
        selecteExp = DateTime(picked.year, picked.month, picked.day);
        date3 = DateFormat('yyyy-MM-dd').format(selecteExp);
      });
    }
  }

  var date1;
  Future<void> _selectDate3(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectejoin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectejoin) {
      setState(() {
        selectejoin = DateTime(picked.year, picked.month, picked.day);
        date1 = DateFormat('yyyy-MM-dd').format(selectejoin);
      });
    }
  }

  var date2;
  Future<void> _selectDate4(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selecteconf,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selecteconf) {
      setState(() {
        selecteconf = DateTime(picked.year, picked.month, picked.day);
        date2 = DateFormat('yyyy-MM-dd').format(selecteconf);
      });
    }
  }

  void pickExpLetter() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          selectedExpLetter = File(result.files.single.path!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Experience letter selected successfully."),
            backgroundColor: Color.fromARGB(173, 120, 249, 126),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error while selecting experience letter."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void pickSalarySlip() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          selectedSalarySlip = File(result.files.single.path!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Salary slip selected successfully."),
            backgroundColor: Color.fromARGB(173, 120, 249, 126),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error while selecting salary slip."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> country = [];

  Future<void> getcountry() async {
    final token = await gettokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> countrylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          countrylist.add({
            'id': productData['id'],
            'country_code': productData['country_code'],
          });
        }
        setState(() {
          country = countrylist;
        });
      }
    } catch (e) {}
  }

  Future<void> getwarehouse() async {
    final token = await gettokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/warehouse/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> warehouselist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          warehouselist.add({
            'id': productData['id'],
            'name': productData['name'],
            'location': productData['location']
          });
        }
        setState(() {
          Warehouses = warehouselist;
        });
      }
    } catch (e) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> familylist = [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'].toString(),
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
        });
      }
    } catch (error) {}
  }

  Future<void> getstates() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stateslist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          stateslist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          statess = stateslist;
          _checkboxValues = List<bool>.filled(statess.length, false);
        });
      }
    } catch (error) {}
  }

  File? selectedImage;

  void imageSelect() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          selectedImage = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("image1 selected successfully."),
          backgroundColor: Color.fromARGB(173, 120, 249, 126),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error while selecting the file."),
        backgroundColor: Colors.red,
      ));
    }
  }

  File? selectedImage1;

  void imageSelect1() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          selectedImage1 = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("image1 selected successfully."),
          backgroundColor: Color.fromARGB(173, 120, 249, 126),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error while selecting the file."),
        backgroundColor: Colors.red,
      ));
    }
  }

  var departments;
  List<Map<String, dynamic>> dep = [];
  List<Map<String, dynamic>> manager = [];

  Future<void> getdepartments() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/departments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> departmentlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          departmentlist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          dep = departmentlist;
        });
      }
    } catch (error) {}
  }

  int? selectedCountryId;
  String? selectedCountryName;

  List<Map<String, dynamic>> sta = [];
  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'email': productData['email']
          });
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  Future<void> getmanegers() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/supervisors/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      List<Map<String, dynamic>> managerlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'department_name': productData['department_name'],
          });
        }
        setState(() {
          manager = managerlist;
        });
      }
    } catch (error) {}
  }

  void addsupervisor(String name, BuildContext context) async {
    final token = await gettokenFromPrefs();

    try {
      var response = await http.post(
        Uri.parse("$api/api/add/supervisor/"),
        headers: {
          'Authorization': '$token',
        },
        body: {
          "name": name,
          "department": selectedDepartmentId.toString(),
        },
      );

      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => add_staff()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('sucess'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  void removeProduct(int index) {
    setState(() {
      sta.removeAt(index);
    });
  }

  int? selectedmanagerId;
  int? selectedwarehouseId;

  String? selectedmanagerName;
  String? selectedwarehouseName;
  int? selectedDepartmentId;
  String? selectedDepartmentName;
  drower d = drower();

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<void> RegisterUserData(
    int selectedDepartmentId,
    DateTime selectedDate,
    String selectgender,
    String selectmarital,
    DateTime selecteExp,
    DateTime selectejoin,
    DateTime selecteconf,
    BuildContext scaffoldContext,
  ) async {
    final token = await gettokenFromPrefs();

    try {
      var request = http.Request(
        'POST',
        Uri.parse('$api/api/add/staff2/'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      Map<String, dynamic> data = {
        'date_of_birth': selectedDate.toIso8601String().substring(0, 10),
        'driving_license_exp_date':
            selecteExp.toIso8601String().substring(0, 10),
        'join_date': selectejoin.toIso8601String().substring(0, 10),
        'confirmation_date': selecteconf.toIso8601String().substring(0, 10),

        // THIS IS THE IMPORTANT PART
        'allocated_states': dynamicStatid,

        'name': name.text,
        'username': username.text,
        'email': email.text,
        'phone': phone.text,
        'password': password.text,
        'alternate_number': alternate_number.text,
        'designation': designation.text,
        'grade': grade.text,
        'address': address.text,
        'city': city.text,
        'country': Country.text,
        'country_code': selectedCountryId,
        'driving_license': driving_license.text,
        'department_id': selectedDepartmentId.toString(),
        'supervisor_id': selectedmanagerId?.toString(),
        'warehouse_id': selectedwarehouseId?.toString(),
        'gender': selectgender,
        'marital_status': selectmarital,
        'employment_status': employment_status.text,
        'approval_status': approvalstatus,
        'family': _selectedFamily.isNotEmpty ? _selectedFamily[0] : null,

        'staff_id': staff_id.text,
        'emergency_contact_name': emergency_contact_name.text,
        'emergency_contact_number': emergency_contact_number.text,
        'experience': int.tryParse(experience.text) ?? 0,
        'previous_company': previous_company.text,
        'blood_group': selectedBloodGroup ?? '',
        'education': education.text,
        'aadhar_no': aadhar_no.text,
        'pan_no': pan_no.text,
        'state': selectedPostingStateId,
        'place': place.text,
      };

      request.body = jsonEncode(data);

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 201) {
        final Map<String, dynamic> responseJson = jsonDecode(responseData.body);
        staffId = responseJson['data']['id'].toString();

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Data Added Successfully.'),
          ),
        );

        Navigator.pushReplacement(
          scaffoldContext,
          MaterialPageRoute(builder: (context) => const add_staff()),
        );
      } else if (responseData.statusCode == 400) {
        final Map<String, dynamic> responseJson = jsonDecode(responseData.body);

        if (responseJson['errors'] != null) {
          String errorMessage = responseJson['errors'].entries.map((e) {
            return "${e.key}: ${e.value.join(', ')}";
          }).join('\n');

          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(
              content: Text('Validation failed. Please check your input.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again later.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  bool isLoading = false;

  Future<void> updateStaffFiles(
    String staffId,
    File? image1,
    File? image2,
    File? expLetter,
    File? salarySlip,
    BuildContext scaffoldContext,
  ) async {
    final token = await gettokenFromPrefs();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$api/api/staff/update/$staffId/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (image1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image1.path),
        );
      }

      if (image2 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('signatur_up', image2.path),
        );
      }

      if (expLetter != null) {
        request.files.add(
          await http.MultipartFile.fromPath('exp_letter', expLetter.path),
        );
      }

      if (salarySlip != null) {
        request.files.add(
          await http.MultipartFile.fromPath('salrary_slip', salarySlip.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Files Updated Successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(
              'File upload failed. Status: ${response.statusCode}\n${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    name.dispose();
    username.dispose();
    email.dispose();
    phone.dispose();
    alternate_number.dispose();
    password.dispose();
    driving_license.dispose();
    employment_status.dispose();
    designation.dispose();
    grade.dispose();
    address.dispose();
    city.dispose();
    Country.dispose();
    staff_id.dispose();
    emergency_contact_name.dispose();
    emergency_contact_number.dispose();
    experience.dispose();
    previous_company.dispose();
    education.dispose();
    aadhar_no.dispose();
    pan_no.dispose();

    place.dispose();
    super.dispose();
  }

  Widget _buildBloodGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("Blood Group"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBloodGroup,
              hint: const Text('Select Blood Group'),
              underline: const SizedBox(),
              icon:
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              onChanged: (String? newValue) {
                setState(() {
                  selectedBloodGroup = newValue;
                });
              },
              items: bloodGroups.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
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
    } 
        else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
    else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "HR") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
      );
    } else if (dep == "warehouse") {
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

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBFD7FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        decoration: _inputDecoration(label, icon: icon),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFD7FF)),
      ),
      child: child,
    );
  }

  Widget _buildDateField({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel(title),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFD7FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd / MM / yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.date_range_outlined, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionMiniLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String fallbackText,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel(title),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFD7FF)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file != null ? file.path.split('/').last : fallbackText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: file != null ? Colors.black : Colors.black54,
                        fontWeight:
                            file != null ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Browse",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFD7FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.blue,
        boxShadow: const [
          BoxShadow(
            color: Color(0x220000FF),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Add Staff",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Create employee profile, assign department, manager, warehouse and upload documents.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableStaffSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 55),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFD7FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Available Staff"),
          if (sta.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: const Center(
                child: Text(
                  "No staff available",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: sta.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(
                height: 18,
                color: Color(0xFFBFD7FF),
              ),
              itemBuilder: (context, i) {
                return Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${sta[i]['name']}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${sta[i]['email'] ?? ''}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Staff_Update(id: sta[i]['id']),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFamilyDropdown() {
    if (fam.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return _buildDropdownContainer(
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedFamily.isEmpty ? null : _selectedFamily[0].toString(),
        hint: const Text("Select Family"),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
        items: fam.map<DropdownMenuItem<String>>((family) {
          return DropdownMenuItem<String>(
            value: family['id'],
            child: Text(family['name']),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            if (newValue != null) {
              _selectedFamily = [int.parse(newValue)];
            }
          });
        },
      ),
    );
  }

  Widget _buildStateSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("Allocated States"),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFD7FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                hint: const Text(
                  'Select State',
                  style: TextStyle(fontSize: 14),
                ),
                value: statess.isNotEmpty && selectstate != null
                    ? statess.firstWhere(
                        (element) => element['name'] == selectstate,
                        orElse: () => statess[0],
                      )
                    : null,
                items: statess.isNotEmpty
                    ? statess.map<DropdownMenuItem<Map<String, dynamic>>>(
                        (Map<String, dynamic> state) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: state,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  state['name'],
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (stat.contains(state['name']))
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                            ],
                          ),
                        );
                      }).toList()
                    : [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No states available'),
                        ),
                      ],
                onChanged: (Map<String, dynamic>? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectstate = newValue['name'];
                      selectedStateId = newValue['id'];
                      if (!stat.contains(selectstate) &&
                          !dynamicStatid.contains(selectedStateId)) {
                        stat.add(selectstate!);
                        dynamicStatid.add(selectedStateId!);
                      } else {
                        stat.remove(selectstate!);
                        dynamicStatid.remove(selectedStateId);
                      }
                    });
                  }
                },
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: Colors.blue),
              ),
            ),
          ),
          if (stat.isNotEmpty) const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: stat.map((value) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFBFD7FF)),
                ),
                child: Chip(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  deleteIcon:
                      const Icon(Icons.close, size: 18, color: Colors.blue),
                  onDeleted: () {
                    setState(() {
                      int index = stat.indexOf(value);
                      stat.removeAt(index);
                      dynamicStatid.removeAt(index);
                      if (stat.isEmpty) {
                        selectstate = null;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("Gender"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<String>(
              value: selectgender,
              underline: const SizedBox(),
              isExpanded: true,
              icon:
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              onChanged: (String? newValue) {
                setState(() {
                  selectgender = newValue!;
                });
              },
              items: gender.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaritalDropdown(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("Marital Status"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<String>(
              value: selectmarital,
              underline: const SizedBox(),
              isExpanded: true,
              icon:
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              onChanged: (String? newValue) {
                setState(() {
                  selectmarital = newValue!;
                });
              },
              items: material.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalDropdown(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("Status"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<String>(
              value: approvalstatus,
              underline: const SizedBox(),
              isExpanded: true,
              icon:
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              onChanged: (String? newValue) {
                setState(() {
                  approvalstatus = newValue!;
                });
              },
              items: approval.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedDepartmentId,
        hint: const Text('Select Department'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
        onChanged: (int? newValue) {
          setState(() {
            selectedDepartmentId = newValue;
            selectedDepartmentName =
                dep.firstWhere((element) => element['id'] == newValue)['name'];
          });
        },
        items: dep.map<DropdownMenuItem<int>>((department) {
          return DropdownMenuItem<int>(
            value: department['id'],
            child: Text(department['name']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagerDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedmanagerId,
        hint: const Text('Select Manager'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
        onChanged: (int? newValue) {
          setState(() {
            selectedmanagerId = newValue;
            selectedmanagerName = manager
                .firstWhere((element) => element['id'] == newValue)['name'];
          });
        },
        items: manager.map<DropdownMenuItem<int>>((manager) {
          return DropdownMenuItem<int>(
            value: manager['id'],
            child: Text(manager['name']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWarehouseDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedwarehouseId,
        hint: const Text('Select Warehouse'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
        onChanged: (int? newValue) {
          setState(() {
            selectedwarehouseId = newValue;
            selectedwarehouseName = Warehouses.firstWhere(
                (element) => element['id'] == newValue)['name'];
          });
        },
        items: Warehouses.map<DropdownMenuItem<int>>((warehouse) {
          return DropdownMenuItem<int>(
            value: warehouse['id'],
            child: Text(warehouse['name']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountryCodeDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedCountryId,
        hint: const Text('Select Country Code'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
        onChanged: (int? newValue) {
          setState(() {
            selectedCountryId = newValue;
            selectedCountryName =
                country.firstWhere((c) => c['id'] == newValue)['country_code'];
          });
        },
        items: country.map<DropdownMenuItem<int>>((countryItem) {
          return DropdownMenuItem<int>(
            value: countryItem['id'],
            child: Text(countryItem['country_code']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostingStateDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniLabel("State"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedPostingStateId,
              hint: const Text('Select State'),
              underline: const SizedBox(),
              icon:
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              onChanged: (int? newValue) {
                setState(() {
                  selectedPostingStateId = newValue;
                });
              },
              items: statess.map<DropdownMenuItem<int>>((state) {
                return DropdownMenuItem<int>(
                  value: state['id'],
                  child: Text(state['name']),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "Add Staff",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => bdo_dashbord()),
                );
              } 
                  else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
              else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => bdm_dashbord()),
                );
              } else if (dep == "HR") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HrDashboard()),
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WarehouseDashboard()),
                );
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WarehouseAdmin()),
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
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => dashboard()),
                );
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('lib/assets/profile.png'),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: Builder(
          builder: (BuildContext scaffoldContext) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      _buildSectionCard(
                        title: "Basic Information",
                        children: [
                          _buildTextField(name, 'Full Name',
                              icon: Icons.person_outline),
                          _buildTextField(username, 'Username',
                              icon: Icons.alternate_email),
                          _buildTextField(email, 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          _buildTextField(phone, 'Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          _buildTextField(alternate_number, 'Alternate Number',
                              icon: Icons.phone_android_outlined,
                              keyboardType: TextInputType.phone),
                          _buildTextField(password, 'Password',
                              icon: Icons.lock_outline, obscureText: true),
                          _buildTextField(staff_id, 'Staff ID',
                              icon: Icons.badge_outlined),
                          _buildDateField(
                            title: "Date of Birth",
                            date: selectedDate,
                            onTap: () => _selectDate(context),
                          ),
                          _buildGenderDropdown(constraints),
                          _buildMaritalDropdown(constraints),
                        ],
                      ),
                      _buildSectionCard(
                        title: "Work Assignment",
                        children: [
                          _buildDepartmentDropdown(),
                          _buildManagerDropdown(),
                          _buildWarehouseDropdown(),
                          _buildStateSelector(),
                          _buildFamilyDropdown(),
                          _buildTextField(
                              employment_status, 'Employment Status',
                              icon: Icons.work_outline),
                          _buildTextField(designation, 'Designation',
                              icon: Icons.assignment_ind_outlined),
                          _buildTextField(grade, 'Grade',
                              icon: Icons.stacked_bar_chart_outlined),
                          _buildDateField(
                            title: "Joining Date",
                            date: selectejoin,
                            onTap: () => _selectDate3(context),
                          ),
                          _buildDateField(
                            title: "Confirmation Date",
                            date: selecteconf,
                            onTap: () => _selectDate4(context),
                          ),
                          _buildApprovalDropdown(constraints),
                        ],
                      ),
                      _buildSectionCard(
                        title: "Emergency & Personal Details",
                        children: [
                          _buildTextField(
                              emergency_contact_name, 'Emergency Contact Name',
                              icon: Icons.contact_phone_outlined),
                          _buildTextField(emergency_contact_number,
                              'Emergency Contact Number',
                              icon: Icons.call_outlined,
                              keyboardType: TextInputType.phone),
                          _buildTextField(experience, 'Experience',
                              icon: Icons.timeline_outlined,
                              keyboardType: TextInputType.number),
                          _buildTextField(previous_company, 'Previous Company',
                              icon: Icons.business_outlined),
                          _buildTextField(education, 'Education',
                              icon: Icons.school_outlined),
                          _buildBloodGroupDropdown(),
                          _buildTextField(aadhar_no, 'Aadhar Number',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number),
                          _buildTextField(pan_no, 'PAN Number',
                              icon: Icons.account_box_outlined,
                              textCapitalization:
                                  TextCapitalization.characters),
                        ],
                      ),
                      _buildSectionCard(
                        title: "License, Address & Country",
                        children: [
                          _buildTextField(driving_license, 'Driving License',
                              icon: Icons.drive_eta_outlined),
                          _buildDateField(
                            title: "License Expiry Date",
                            date: selecteExp,
                            onTap: () => _selectDate2(context),
                          ),
                          _buildTextField(address, 'Address',
                              icon: Icons.location_on_outlined, maxLines: 3),
                          _buildTextField(city, 'City',
                              icon: Icons.location_city_outlined),
                          _buildTextField(Country, 'Country',
                              icon: Icons.public_outlined),
                          _buildPostingStateDropdown(),
                          _buildTextField(place, 'Place',
                              icon: Icons.place_outlined),
                          _buildCountryCodeDropdown(),
                        ],
                      ),
                      _buildSectionCard(
                        title: "Uploads",
                        children: [
                          _buildUploadTile(
                            title: "Profile Image",
                            fallbackText: "Select Profile Image",
                            file: selectedImage,
                            onTap: imageSelect,
                          ),
                          _buildUploadTile(
                            title: "Signature",
                            fallbackText: "Select Signature",
                            file: selectedImage1,
                            onTap: imageSelect1,
                          ),
                          _buildUploadTile(
                            title: "Experience Letter",
                            fallbackText: "Select Experience Letter",
                            file: selectedExpLetter,
                            onTap: pickExpLetter,
                          ),
                          _buildUploadTile(
                            title: "Salary Slip",
                            fallbackText: "Select Salary Slip",
                            file: selectedSalarySlip,
                            onTap: pickSalarySlip,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() => isLoading = true);

                                await RegisterUserData(
                                  selectedDepartmentId!,
                                  selectedDate,
                                  selectgender,
                                  selectmarital,
                                  selecteExp,
                                  selectejoin,
                                  selecteconf,
                                  scaffoldContext,
                                );

                                await updateStaffFiles(
                                  staffId,
                                  selectedImage,
                                  selectedImage1,
                                  selectedExpLetter,
                                  selectedSalarySlip,
                                  scaffoldContext,
                                );

                                setState(() => isLoading = false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Text(
                                      "Submit",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      _buildAvailableStaffSection(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
