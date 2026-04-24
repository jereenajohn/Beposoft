import 'dart:convert';
import 'dart:io';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'package:pdf/pdf.dart';

import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';

class bod_oredr_list extends StatefulWidget {
  var status;
  bod_oredr_list({super.key, required this.status});

  @override
  State<bod_oredr_list> createState() => _bod_oredr_listState();
}

class _bod_oredr_listState extends State<bod_oredr_list> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  String searchQuery = '';

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  int currentPage = 1;
  int totalPages = 1;
  String? nextUrl;
  String? prevUrl;

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

  @override
  void initState() {
    super.initState();
    fetchOrderData();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> fetchOrderData({int page = 1}) async {
    try {
      final token = await getTokenFromPrefs();
      final dep = await getdepFromPrefs();

      if (token == null) {
        ;
        return;
      }

      // final jwt = Jwt.parseJwt(token);
      // var name = jwt['name']; // Extract user name (if needed)

      var response = await http.get(
        Uri.parse('$api/api/staff/orders/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

    

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        nextUrl = parsed['next'];
        prevUrl = parsed['previous'];

        int count = parsed['count'] ?? 0;
        int pageSize = parsed['results']['data'].length;

        if (pageSize > 0) {
          totalPages = (count / pageSize).ceil();
        }

        currentPage = page;

        if (parsed is Map<String, dynamic> &&
            parsed.containsKey('results') &&
            parsed['results'].containsKey('data')) {
          List<dynamic> productsData = parsed['results']['data'];
          List<Map<String, dynamic>> orderList = [];

          for (var productData in productsData) {
            // Handle missing or null values safely
            String rawOrderDate = productData['order_date'] ?? "";
            String formattedOrderDate =
                rawOrderDate; // Fallback in case of failure

            try {
              DateTime parsedOrderDate =
                  DateFormat('yyyy-MM-dd').parse(rawOrderDate);
              formattedOrderDate =
                  DateFormat('yyyy-MM-dd').format(parsedOrderDate);
            } catch (e) {
              ;
            }

            if (widget.status == null ||
                widget.status == productData['status']) {
              orderList.add({
                'id': productData['id'],
                'invoice': productData['invoice'],
                'manage_staff': productData['manage_staff'],
                'customer': productData['customer'] ?? {},
                'customerid': productData['customerID'],
                'warehouse': productData['warehouse'],
                'billing_address': productData['billing_address'] ?? {},
                'bank': productData['bank'] ?? {},
                'items': productData['items'] != null
                    ? List<Map<String, dynamic>>.from(
                        productData['items'].map((item) => {
                              'id': item['id'],
                              'name': item['name'],
                              'quantity': item['quantity'],
                              'price': item['price'],
                              'tax': item['tax'],
                              'discount': item['discount'],
                              'images': item['images'],
                            }))
                    : [],
                'received_payment': productData['recived_payment'] != null
                    ? List<Map<String, dynamic>>.from(
                        productData['recived_payment'].map((payment) => {
                              'id': payment['id'],
                              'created_by': payment['created_by'],
                              'bank': payment['bank'],
                              'payment_receipt': payment['payment_receipt'],
                              'amount': payment['amount'],
                              'transactionID': payment['transactionID'],
                              'received_at': payment['received_at'],
                              'remark': payment['remark'],
                            }))
                    : [],
                'status': productData['status'],
                'total_amount': productData['total_amount'],
                'order_date': formattedOrderDate,
              });
            }
          }

          setState(() {
            orders = orderList;
            filteredOrders = orderList;
          });
          ;
        } else {
          ;
        }
      } else {
        ;
      }
    } catch (error) {
      ;
    }
  }

  void _filterOrders(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredOrders = orders;
      } else {
        filteredOrders = orders.where((order) {
          final customerName =
              order['customer']['name']?.toString().toLowerCase() ?? '';
          final invoice = order['invoice']?.toString().toLowerCase() ?? '';
          final manageStaff =
              order['manage_staff']?.toString().toLowerCase() ?? '';
          final totalAmount =
              order['total_amount']?.toString().toLowerCase() ?? '';

          return customerName.contains(query.toLowerCase()) ||
              invoice.contains(query.toLowerCase()) ||
              manageStaff.contains(query.toLowerCase()) ||
              totalAmount.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Method to filter orders by single date
  void _filterOrdersBySingleDate() {
    if (selectedDate != null) {
      setState(() {
        filteredOrders = orders.where((order) {
          final orderDate = DateTime.parse(order['order_date']);
          return orderDate.year == selectedDate!.year &&
              orderDate.month == selectedDate!.month &&
              orderDate.day == selectedDate!.day;
        }).toList();
      });
    }
  }

  // Method to filter orders between two dates
  // Method to filter orders between two dates, inclusive of start and end dates
  void _filterOrdersByDateRange() {
    if (startDate != null && endDate != null) {
      setState(() {
        filteredOrders = orders.where((order) {
          final orderDate = DateTime.parse(order['order_date']);
          return (orderDate.isAtSameMomentAs(startDate!) ||
              orderDate.isAtSameMomentAs(endDate!) ||
              (orderDate.isAfter(startDate!) && orderDate.isBefore(endDate!)));
        }).toList();
      });
    }
  }

  Future<void> _selectSingleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _filterOrdersBySingleDate();
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _filterOrdersByDateRange();
    }
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

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Order List'];

    // Add header row
    sheetObject.appendRow([
      'Invoice',
      'Manager',
      'Customer Name',
      'Customer Phone',
      'Customer Email',
      'Customer Address',
      'Billing Name',
      'Billing Email',
      'Billing Phone',
      'Billing Address',
      'Billing City',
      'Billing State',
      'Billing Zipcode',
      'Bank Name',
      'Bank Account Number',
      'Bank IFSC Code',
      'Bank Branch',
      'Item Name',
      'Item Quantity',
      'Item Price',
      'Item Tax',
      'Item Discount',
      'Order Status',
      'Total Amount',
      'Order Date',
    ]);

    // Populate rows with data
    for (var order in filteredOrders) {
      // Iterate through items to create separate rows for each item
      for (var item in order['items']) {
        sheetObject.appendRow([
          order['invoice'] ?? '',
          order['manage_staff'] ?? '',
          order['customer']['name'] ?? '',
          order['customer']['phone'] ?? '',
          order['customer']['email'] ?? '',
          order['customer']['address'] ?? '',
          order['billing_address']['name'] ?? '',
          order['billing_address']['email'] ?? '',
          order['billing_address']['phone'] ?? '',
          order['billing_address']['address'] ?? '',
          order['billing_address']['city'] ?? '',
          order['billing_address']['state'] ?? '',
          order['billing_address']['zipcode'] ?? '',
          order['bank']['name'] ?? '',
          order['bank']['account_number'] ?? '',
          order['bank']['ifsc_code'] ?? '',
          order['bank']['branch'] ?? '',
          item['name'] ?? '',
          item['quantity'] ?? '',
          item['price'] ?? '',
          item['tax'] ?? '',
          item['discount'] ?? '',
          order['status'] ?? '',
          order['total_amount'] ?? '',
          order['order_date'] ?? '',
        ]);
      }
    }

    // Save the Excel file
    final tempDir = await getTemporaryDirectory();
    final tempPath = "${tempDir.path}/order_list.xlsx";
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(await excel.encode()!);

    // Open the file
    await OpenFilex.open(tempPath);
  }

  Future<pw.Document> createPdf() async {
    final pdf = pw.Document();

    // Iterate through each order and add a new page for it
    for (var order in filteredOrders) {
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
                      'Order Details',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Invoice and Manager
                  pw.Text(
                    'Invoice: ${order['invoice']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Manager: ${order['manage_staff'] ?? ''}'),
                  pw.SizedBox(height: 10),

                  // Customer Details
                  pw.Text(
                    'Customer Details',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Name: ${order['customer']['name'] ?? ''}'),
                  pw.Text('Phone: ${order['customer']['phone'] ?? ''}'),
                  pw.Text('Email: ${order['customer']['email'] ?? ''}'),
                  pw.Text('Address: ${order['customer']['address'] ?? ''}'),
                  pw.SizedBox(height: 10),

                  // Billing Address
                  pw.Text(
                    'Billing Address',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Name: ${order['billing_address']['name'] ?? ''}'),
                  pw.Text('Email: ${order['billing_address']['email'] ?? ''}'),
                  pw.Text('Phone: ${order['billing_address']['phone'] ?? ''}'),
                  pw.Text(
                      'Address: ${order['billing_address']['address'] ?? ''}'),
                  pw.Text('City: ${order['billing_address']['city'] ?? ''}'),
                  pw.Text('State: ${order['billing_address']['state'] ?? ''}'),
                  pw.Text(
                      'Zipcode: ${order['billing_address']['zipcode'] ?? ''}'),
                  pw.SizedBox(height: 10),

                  // Bank Details
                  pw.Text(
                    'Bank Details',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Name: ${order['bank']['name'] ?? ''}'),
                  pw.Text(
                      'Account Number: ${order['bank']['account_number'] ?? ''}'),
                  pw.Text('IFSC Code: ${order['bank']['ifsc_code'] ?? ''}'),
                  pw.Text('Branch: ${order['bank']['branch'] ?? ''}'),
                  pw.SizedBox(height: 10),

                  // Items Table
                  pw.Text(
                    'Items',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Table.fromTextArray(
                    headers: ['Name', 'Quantity', 'Price', 'Tax', 'Discount'],
                    data: [
                      for (var item in order['items'])
                        [
                          item['name'] ?? '',
                          item['quantity'].toString(),
                          item['price'].toString(),
                          item['tax'].toString(),
                          item['discount'].toString(),
                        ],
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
                  pw.SizedBox(height: 10),

                  // Order Summary
                  pw.Text(
                    'Order Summary',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Status: ${order['status'] ?? ''}'),
                  pw.Text('Total Amount: ${order['total_amount'].toString()}'),
                  pw.Text('Order Date: ${order['order_date'] ?? ''}'),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  Future<void> downloadPdf() async {
    final pdf = await createPdf();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/order_list.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'order_list.pdf');
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
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Trigger the navigation logic when the back swipe occurs
        _navigateBack();
        return false; // Prevent the default back navigation behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order List',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
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
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today), // Calendar icon
              onPressed: () => _selectSingleDate(
                  context), // Call the method to select start date
            ),
            // Icon button to open date range picker
            IconButton(
              icon: Icon(Icons.date_range), // Date range icon
              onPressed: () => _selectDateRange(
                  context), // Call the method to select date range
            ),
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
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterOrders,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        prevUrl == null ? Colors.grey : Colors.blue,
                  ),
                  onPressed: prevUrl == null
                      ? null
                      : () {
                          fetchOrderData(page: currentPage - 1);
                        },
                  child: Text(
                    "Prev",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  "Page $currentPage / $totalPages",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        nextUrl == null ? Colors.grey : Colors.blue,
                  ),
                  onPressed: nextUrl == null
                      ? null
                      : () {
                          fetchOrderData(page: currentPage + 1);
                        },
                  child: Text("Next", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            // Date Filters
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       SizedBox(
            //         width: 160,
            //         child: ElevatedButton(
            //           onPressed: () => _selectSingleDate(context),
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: const Color.fromARGB(
            //                 255, 2, 65, 96), // Set button color to grey
            //             shape: RoundedRectangleBorder(
            //               borderRadius:
            //                   BorderRadius.circular(8), // Set the border radius
            //             ),
            //           ),
            //           child: Text(
            //             'Select Date',
            //             style: TextStyle(color: Colors.white),
            //           ),
            //         ),
            //       ),
            //       SizedBox(width: 10),
            //       ElevatedButton(
            //         onPressed: () => _selectDateRange(context),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: const Color.fromARGB(
            //               255, 2, 65, 96), // Set button color to grey
            //           shape: RoundedRectangleBorder(
            //             borderRadius:
            //                 BorderRadius.circular(8), // Set the border radius
            //           ),
            //         ),
            //         child: Text(
            //           'Select Date Range',
            //           style: TextStyle(
            //               color: Colors.white), // Set text color to white
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Display Orders
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Text(
                        selectedDate != null ||
                                (startDate != null && endDate != null)
                            ? 'No orders available in this date range'
                            : 'No orders available',
                        style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 2, 65, 96)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OrderReview(
                                          id: order['id'],
                                          customer: order['customerid'])));
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              color: Colors.white,
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header section with Invoice and Order Date
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15.0),
                                        topRight: Radius.circular(15.0),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#${order['invoice']}',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          DateFormat('dd MMM yy').format(
                                              DateTime.parse(
                                                  order['order_date'])),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Order details section
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer: ${order['customer']['name']}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        // SizedBox(height: 4.0),
                                        // Text(
                                        //   'Staff: ${order['manage_staff']}',
                                        //   style: TextStyle(
                                        //     fontSize: 13,
                                        //   ),
                                        // ),
                                        SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            Text(
                                              'Status: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${order['status']}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.0),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Billing Amount:',
                                              style: TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${(order['total_amount'] as num).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (order['warehouse'] != null &&
                                            (order['warehouse'] as List)
                                                .isNotEmpty) ...[
                                          SizedBox(height: 4.0),
                                          Text(
                                            'Warehouse Info:',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                          SizedBox(height: 4.0),
                                          Table(
                                            border: TableBorder.symmetric(
                                              inside: BorderSide(
                                                  color: Colors.grey.shade300),
                                              outside: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 1),
                                            ),
                                            columnWidths: {
                                              0: FlexColumnWidth(1),
                                              1: FlexColumnWidth(2),
                                              2: FlexColumnWidth(3),
                                            },
                                            defaultVerticalAlignment:
                                                TableCellVerticalAlignment
                                                    .middle,
                                            children: [
                                              // Header Row
                                              TableRow(
                                                decoration: BoxDecoration(
                                                    color: Colors.blue.shade50),
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0,
                                                            horizontal: 6.0),
                                                    child: Text(
                                                      'Box',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade900,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0,
                                                            horizontal: 6.0),
                                                    child: Text(
                                                      'Tracking ID',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade900,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Data Rows
                                              ...(order['warehouse'] as List)
                                                  .map<TableRow>((wh) {
                                                return TableRow(
                                                  decoration: BoxDecoration(
                                                      color: Colors.white),
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        wh['box'] ?? 'N/A',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        wh['tracking_id'] ??
                                                            'N/A',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ] else
                                          Text(
                                            'No warehouse data available',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12),
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
        ),
      ),
    );
  }
}
