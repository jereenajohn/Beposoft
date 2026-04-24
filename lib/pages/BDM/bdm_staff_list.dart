import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_address.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_ledger.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_singleview.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_Expense.dart';
import 'package:beposoft/pages/ACCOUNTS/update_staff.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';

class bdm_staff_list extends StatefulWidget {
  var family;
  bdm_staff_list({super.key, required this.family});

  @override
  State<bdm_staff_list> createState() => _bdm_staff_listState();
}

class _bdm_staff_listState extends State<bdm_staff_list> {
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  String? _selectedFamily;
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    getstaff();
  }

  List<String> categories = ["cycling", 'skating', 'fitness', 'bepocart'];
  String selectededu = "cycling";
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
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
          },
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> customer = [];
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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
      ;
      List<Map<String, dynamic>> stafflist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          if (widget.family == productData['family_name']) {
            stafflist.add({
              'id': productData['id'],
              'name': productData['name'],
              'email': productData['email'],
              'designation': productData['designation'],
              'image': productData['image'],
              'approval_status': productData['approval_status']
            });
          }
        }
        setState(() {
          sta = stafflist;
          filteredProducts = List.from(sta); // Show all customers initially
        });
      }
    } catch (error) {}
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(sta); // Show all if search is empty
      } else {
        filteredProducts = sta
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter based on query
      }
    });
  }

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Staff List'];

    sheetObject
        .appendRow(['ID', 'Name', 'Email', 'Designation', 'Approval Status']);

    for (var staff in filteredProducts) {
      sheetObject.appendRow([
        staff['id'] ?? '',
        staff['name'] ?? '',
        staff['email'] ?? '',
        staff['designation'] ?? '',
        staff['approval_status'] ?? '',
      ]);
    }

    final tempDir = await getTemporaryDirectory();
    final tempPath = "${tempDir.path}/staff_list.xlsx";
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(await excel.encode()!);

    await OpenFilex.open(tempPath);
  }

  Future<pw.Document> createPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title Section
                pw.Center(
                  child: pw.Text(
                    'Staff List',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table Headers
                pw.Table.fromTextArray(
                  headers: [
                    'ID',
                    'Name',
                    'Email',
                    'Designation',
                    'Approval Status'
                  ],
                  data: [
                    for (var staff in filteredProducts)
                      [
                        staff['id'] ?? '',
                        staff['name'] ?? '',
                        staff['email'] ?? '',
                        staff['designation'] ?? '',
                        staff['approval_status'] ?? '',
                      ]
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: pw.TextStyle(
                    fontSize: 8,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> downloadPdf() async {
    final pdf = await createPdf();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/staff_list.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'staff_list.pdf');
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    // Use a post-frame callback to show the SnackBar after the current frame
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

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
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
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              "Staff List",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back), // Custom back arrow
              onPressed: () async {
                final dep = await getdepFromPrefs();
                if (dep == "BDO") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            bdo_dashbord()), // Replace AnotherPage with your target page
                  );
                } else if (dep == "SD") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SdDashboard()), // Replace AnotherPage with your target page
                  );
                } else if (dep == "BDM") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            bdm_dashbord()), // Replace AnotherPage with your target page
                  );
                } else if (dep == "warehouse") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WarehouseDashboard()), // Replace AnotherPage with your target page
                  );
                } else if (dep == "Warehouse Admin") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WarehouseAdmin()), // Replace AnotherPage with your target page
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            dashboard()), // Replace AnotherPage with your target page
                  );
                }
              },
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert), // 3-dot icon
                onSelected: (value) {
                  // Handle menu item selection
                  switch (value) {
                    case 'Option 1':
                      exportToExcel();
                      break;
                    case 'Option 2':
                      downloadPdf();
                      break;

                    default:
                      // Handle default case
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Option 1',
                      child: Text('Export Excel'),
                    ),
                    PopupMenuItem<String>(
                      value: 'Option 2',
                      child: Text('Download Pdf'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search Staff...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color:
                            Colors.blue, // Set your desired border color here
                        width: 2.0, // Set the border width
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: Colors
                            .blue, // Border color when TextField is not focused
                        width: 2.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: Colors
                            .blueAccent, // Border color when TextField is focused
                        width: 2.0,
                      ),
                    ),
                  ),
                  onChanged: _filterProducts,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final staffData = filteredProducts[index];
                    ;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Staff_Update(
                              id: staffData['id'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Image with Approval Status circle around it
                              Stack(
                                clipBehavior: Clip
                                    .none, // Allow text to go outside the boundary
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: staffData['image'] != null &&
                                            staffData['image'].isNotEmpty
                                        ? Image.network(
                                            "$api${staffData['image']}", // Profile image from network
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "lib/assets/user.png", // Default profile image
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  // Circular Approval Status ring around the image
                                  Positioned(
                                    bottom: -4,
                                    right: -4,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: staffData['approval_status'] ==
                                                'approved'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      child: Center(
                                        child: Text(
                                          staffData['approval_status'] ==
                                                  'approved'
                                              ? 'A'
                                              : 'I',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Staff Name - Bold and larger size
                                        Flexible(
                                          child: Text(
                                            staffData['name'] ?? 'No Name',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow
                                                .ellipsis, // This handles overflow by showing ellipsis
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "-",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        // Staff Designation - Smaller and lighter weight
                                        Flexible(
                                          child: Text(
                                            staffData['designation'] ??
                                                'No Designation',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blueGrey,
                                            ),
                                            overflow: TextOverflow
                                                .ellipsis, // This handles overflow by showing ellipsis
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),
                                    // Staff Email - Grey color for subtlety
                                    Text(
                                      staffData['email'] ?? 'No Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }
}
