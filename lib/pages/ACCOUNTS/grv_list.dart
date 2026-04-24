import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class GrvList extends StatefulWidget {
  var status;
  GrvList({super.key, required this.status});

  @override
  State<GrvList> createState() => _GrvListState();
}

class _GrvListState extends State<GrvList> {
  List<Map<String, dynamic>> grvlist = [];
  List<String> remarkOptions = ["exchange", "return", "refund", 'cod_return'];
  List<String> statusOptions = ["Waiting For Approval", "approved", "rejected"];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  String selectedStatus = ""; // Default selected status
  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getGrvList();
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';

    try {
      DateTime parsedDate = DateTime.parse(isoDate);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  // Fetch GRV list data from the API
  Future<void> getGrvList() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grv/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        for (var productData in productsData) {
          if (widget.status == null) {
            grvDataList.add({
              'id': productData['id'],
              'product': productData['product'],
              'returnreason': productData['returnreason'],
              'invoice': productData['invoice'],
              'customer': productData['customer'],
              'shipping_customer': productData['shipping_customer'],
              'staff': productData['staff'],
              'remark': productData['remark'],
              'cod_amount': productData['cod_amount'],
              'rack_details': productData['rack_details'],
              'status': productData['status'] ?? statusOptions[0],
              'order_date': productData['order_date'],
              'note': productData['note'],
              'updated_at': productData['updated_at'] ??
                  DateTime.now().toIso8601String().split('T')[0],
            });
          } else if (widget.status == productData['status']) {
            grvDataList.add({
              'id': productData['id'],
              'product': productData['product'],
              'returnreason': productData['returnreason'],
              'invoice': productData['invoice'],
              'customer': productData['customer'],
              'shipping_customer': productData['shipping_customer'],
              'cod_amount': productData['cod_amount'],
              'rack_details': productData['rack_details'],
              'staff': productData['staff'],
              'remark': productData['remark'],
              'status': productData['status'] ?? statusOptions[0],
              'order_date': productData['order_date'],
              'note': productData['note'],
              'updated_at': productData['updated_at'] ??
                  DateTime.now().toIso8601String().split('T')[0],
            });
          }
        }
        setState(() {
          grvlist = grvDataList;
          filteredProducts = grvDataList; // Initially show all items
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch GRV data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching GRV data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update GRV item data
  Future<void> updateGrvItem(int id, String status, String remark) async {
    try {
      final token = await getTokenFromPrefs();

      // Get current time and format it correctly
      String formattedTime = DateFormat("HH:mm").format(DateTime.now());

      var response = await http.put(
        Uri.parse('$api/api/grv/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'remark': remark,
          'updated_at': DateTime.now().toIso8601String().split('T')[0],
          'time': formattedTime,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          grvlist = grvlist.map((item) {
            if (item['id'] == id) {
              item['status'] = status;
              item['remark'] = remark;
            }
            return item;
          }).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GRV updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update GRV'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating GRV'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Filter GRV list based on status and search query
  void _filterProducts(String query) {
    setState(() {
      filteredProducts = grvlist.where((product) {
        final matchesStatus =
            selectedStatus.isEmpty || product['status'] == selectedStatus;
        final matchesSearch = query.isEmpty ||
            product['product'].toLowerCase().contains(query.toLowerCase()) ||
            product['invoice'].toLowerCase().contains(query.toLowerCase()) ||
            product['customer'].toLowerCase().contains(query.toLowerCase()) ||
            product['staff'].toLowerCase().contains(query.toLowerCase());

        return matchesStatus && matchesSearch; // Both filters must match
      }).toList();
    });
  }

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

  void _filterOrdersByDateRange() {
    if (startDate != null && endDate != null) {
      setState(() {
        filteredProducts = filteredProducts.where((order) {
          // Parse the 'expense_date' from string to DateTime if needed
          final orderDate = DateFormat('yyyy-MM-dd')
              .parse(order['date']); // Adjust format if needed

          // Check if the order date is within the selected range
          return orderDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
              orderDate.isBefore(endDate!.add(Duration(days: 1)));
        }).toList();
      });
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
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
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
            "GRV List",
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
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
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
            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search GRV...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (query) =>
                          _filterProducts(query), // Pass the query here
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      value: selectedStatus.isEmpty ? null : selectedStatus,
                      items: statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedStatus = newValue;
                          });
                          _filterProducts(searchController
                              .text); // Re-filter based on the selected status
                        }
                      },
                      isExpanded: true,
                      hint: const Text("Search by Status"),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final item = filteredProducts[index];

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// 🧾 PRODUCT & INVOICE (Top Row)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shopping_bag,
                                              color: Colors.blueAccent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['product'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Invoice: ${item['invoice']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// 👤 CUSTOMER & STAFF
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child:
                                          Text("Customer: ${item['customer']}"),
                                    ),
                                    const Icon(Icons.supervisor_account,
                                        size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text("${item['staff']}"),
                                    ),
                                  ],
                                ),

                                const Divider(height: 24),

                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                          "Shipping Customer: ${item['shipping_customer']}"),
                                    ),
                                  ],
                                ),

                                const Divider(height: 24),

                                /// ❓ RETURN REASON
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.report_problem,
                                        size: 18, color: Colors.redAccent),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Return Reason: ${item['returnreason']}",
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Remark:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    DropdownButton<String>(
                                      key: Key("remark-${item['id']}"),
                                      value: item['remark'],
                                      items: remarkOptions.map((value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            item['remark'] = newValue;
                                          });
                                          updateGrvItem(item['id'],
                                              item['status'], newValue);
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                /// 📊 STATUS
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Status:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    DropdownButton<String>(
                                      key: Key("status-${item['id']}"),
                                      value: item['status'],
                                      items: statusOptions.map((value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            item['status'] = newValue;
                                          });
                                          updateGrvItem(item['id'], newValue,
                                              item['remark'] ?? '');
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                // ...existing code...
                                const Divider(height: 24),

// 🗄️ RACK DETAILS SECTION
                                if (item['rack_details'] != null &&
                                    (item['rack_details'] as List).isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Rack Details:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: (item['rack_details'] as List)
                                            .map<Widget>((rack) {
                                          final rackName =
                                              rack['rack_name'] ?? '';
                                          final col = rack['column_name'] ?? '';
                                          final qty = rack['quantity'] ?? '';
                                          return Chip(
                                            label: Text(
                                              "$rackName${col.isNotEmpty ? '-$col' : ''} x $qty",
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
// ...existing code...

                                const Divider(height: 24),
                                if (item['cod_amount'] != null &&
                                    item['cod_amount'] != 0)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes,
                                          size: 18, color: Colors.teal),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                            "COD Amount: ${item['cod_amount'] ?? 'N/A'}"),
                                      ),
                                    ],
                                  ),
                                if (item['cod_amount'] != null &&
                                    item['cod_amount'] != 0)
                                  const SizedBox(height: 10),

                                /// 📝 DESCRIPTION
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes,
                                        size: 18, color: Colors.teal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                          "Description: ${item['note'] ?? 'N/A'}"),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// 🕒 TIMESTAMPS
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Created: ${item['order_date']}",
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      "Updated: ${formatDate(item['updated_at'])}",
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
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
