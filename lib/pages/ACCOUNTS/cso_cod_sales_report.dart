  import 'dart:convert';
  import 'package:beposoft/pages/ACCOUNTS/codsale_date_report.dart';
  import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
  import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
  import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
  import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
  import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
  import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
  import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
  import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
  import 'package:beposoft/pages/api.dart';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class csoCodSales2 extends StatefulWidget {
    const csoCodSales2({super.key});

    @override
    State<csoCodSales2> createState() => _csoCodSales2State();
  }

  class _csoCodSales2State extends State<csoCodSales2> {
    List<Map<String, dynamic>> allCodReportList = [];
      List<Map<String, dynamic>> filterCodReportList = [];
    List<Map<String, dynamic>> stat = [];

    List<Map<String, dynamic>> fam = [];
    String? selectedFamily;
    String? selectedStaff;
    String? selectedState; 
    List<Map<String, dynamic>> sta = [];
    bool isStaffLoading = false;


    @override
    void initState() {
      super.initState();
      getCODsaleReport();
      getfamily();
      getstaff();
      getstate();
    }

    Future<String?> getTokenFromPrefs() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    }

    Future<void> getstate() async {
      try {
        final token = await getTokenFromPrefs();

        var response = await http.get(
          Uri.parse('$api/api/states/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        List<Map<String, dynamic>> statelist = [];

        if (response.statusCode == 200) {
          final parsed = jsonDecode(response.body);
          var productsData = parsed['data'];

          for (var productData in productsData) {
            statelist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
          setState(() {
            stat = statelist;
          });
        }
      } catch (error) {}
    }

    // Fetch staff list from the API
  Future<void> getstaff({String? familyName}) async {
    try {
      final token = await getTokenFromPrefs();

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

        for (var staff in productsData) {
          final staffFamily = staff['family_name']?.toLowerCase();

          if (staffFamily == 'bepocart') continue; // Always exclude bepocart

          if (familyName != null && staffFamily != familyName.toLowerCase()) {
            continue; // Only include staff from selected family
          }

          stafflist.add({
            'id': staff['id'],
            'name': staff['name'],
          });
        }

        setState(() {
          sta = stafflist;
          selectedStaff = null; // Clear any previous selection
        });
      }
    } catch (error) {
    }
  }

    // Fetch family list from the API
    Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> familylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          // Skip 'bepocart' family
          if (productData['name']?.toLowerCase() == 'bepocart') continue;

          familylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
        });
      }
    } catch (error) {
      // Handle error
    }
  }

Future<void> getCODsaleReport() async {
  try {
    final token = await getTokenFromPrefs();

    var response = await http.get(
      Uri.parse('$api/api/COD/sales/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final salesData = jsonDecode(response.body);
      List<Map<String, dynamic>> salesReportDataList = [];

      for (var reportData in salesData) {
        final date = reportData['date'];
        final orders = reportData['orders'] ?? [];

        List<Map<String, dynamic>> formattedOrders = orders.map<Map<String, dynamic>>((order) {
          return {
            'staff_name': order['staff_name'] ?? '',
            'family_name': order['family_name'] ?? '',
            'state': order['state'] ?? '',
            'total_amount':order['total_amount'],
            'total_paid_amount':order['total_paid_amount'],
            'balance_amount':order['balance_amount'],

          };
        }).toList();

        // Totals
        double totalAmount = 0;
        double totalPaidAmount = 0;
        double totalBalanceAmount = 0;

        for (var order in orders) {
          totalAmount += (order['total_amount'] ?? 0).toDouble();
          totalPaidAmount += (order['total_paid_amount'] ?? 0).toDouble();
          totalBalanceAmount += (order['balance_amount'] ?? 0).toDouble();
        }

        salesReportDataList.add({
          'date': date,
          'total_orders': orders.length,
          'total_amount': totalAmount,
          'total_paid_amount': totalPaidAmount,
          'balance_amount': totalBalanceAmount,
          'orders': formattedOrders,
        });
      }

      setState(() {
        allCodReportList = salesReportDataList;
        filterCodReportList = salesReportDataList;
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch sales report data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error fetching sales report data'),
        duration: Duration(seconds: 2),
      ),
    );
  } finally {
    setState(() {});
  }
}


List<Map<String, dynamic>> filterReportByFamily({
  required List<Map<String, dynamic>> originalReportList,
  required String selectedFamily,
}) {
  List<Map<String, dynamic>> filteredList = [];

  for (var report in originalReportList) {
    List<dynamic> originalOrders = report['orders'] ?? [];

    List<Map<String, dynamic>> filteredOrders = originalOrders
        .where((order) => order['family_name'] == selectedFamily)
        .cast<Map<String, dynamic>>()
        .toList();
    if (filteredOrders.isEmpty) continue;

    double totalAmount = 0;
    double totalPaidAmount = 0;
    double balanceAmount = 0;

    for (var order in filteredOrders) {
  totalAmount += double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
  totalPaidAmount += double.tryParse(order['paid_amount']?.toString() ?? '0') ?? 0.0;
  balanceAmount += double.tryParse(order['balance_amount']?.toString() ?? '0') ?? 0.0;
}


    filteredList.add({
      'date': report['date'],
      'orders': filteredOrders,
      'total_orders': filteredOrders.length,
      'total_amount': totalAmount,
      'total_paid_amount': totalPaidAmount,
      'balance_amount': balanceAmount,
    });
  }
  return filteredList;
}

List<Map<String, dynamic>> filterReportBystaff({
  required List<Map<String, dynamic>> originalReportList,
  required String selectedStaff,
}) {
  List<Map<String, dynamic>> filteredList = [];

  for (var report in originalReportList) {
    List<dynamic> originalOrders = report['orders'] ?? [];

    List<Map<String, dynamic>> filteredOrders = originalOrders
        .where((order) => order['staff_name'] == selectedStaff)
        .cast<Map<String, dynamic>>()
        .toList();
    if (filteredOrders.isEmpty) continue;

    double totalAmount = 0;
    double totalPaidAmount = 0;
    double balanceAmount = 0;

    for (var order in filteredOrders) {
  totalAmount += double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
  totalPaidAmount += double.tryParse(order['paid_amount']?.toString() ?? '0') ?? 0.0;
  balanceAmount += double.tryParse(order['balance_amount']?.toString() ?? '0') ?? 0.0;
}


    filteredList.add({
      'date': report['date'],
      'orders': filteredOrders,
      'total_orders': filteredOrders.length,
      'total_amount': totalAmount,
      'total_paid_amount': totalPaidAmount,
      'balance_amount': balanceAmount,
    });
  }
  return filteredList;
}



List<Map<String, dynamic>> filterReportBystate({
  required List<Map<String, dynamic>> originalReportList,
  required String selectedState,
}) {
  List<Map<String, dynamic>> filteredList = [];

  for (var report in originalReportList) {
    List<dynamic> originalOrders = report['orders'] ?? [];

    List<Map<String, dynamic>> filteredOrders = originalOrders
        .where((order) => order['state'] == selectedState)
        .cast<Map<String, dynamic>>()
        .toList();
    if (filteredOrders.isEmpty) continue;

    double totalAmount = 0;
    double totalPaidAmount = 0;
    double balanceAmount = 0;

    for (var order in filteredOrders) {
  totalAmount += double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
  totalPaidAmount += double.tryParse(order['paid_amount']?.toString() ?? '0') ?? 0.0;
  balanceAmount += double.tryParse(order['balance_amount']?.toString() ?? '0') ?? 0.0;
}


    filteredList.add({
      'date': report['date'],
      'orders': filteredOrders,
      'total_orders': filteredOrders.length,
      'total_amount': totalAmount,
      'total_paid_amount': totalPaidAmount,
      'balance_amount': balanceAmount,
    });
  }
  return filteredList;
}



  Future<String?> getdepFromPrefs() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('department');
    }

    Future<void> _navigateBack() async {
      final dep = await getdepFromPrefs();
    if(dep=="BDO" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
              );

  }
  else if(dep=="BDM" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
              );
  }
  else if(dep=="warehouse" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
              );
  }
  else if(dep=="CEO" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
              );
  }
  else if(dep=="CSO" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => cso_dashboard()), // Replace AnotherPage with your target page
              );
  }

  else if(dep=="Warehouse Admin" ){
    Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
              );
  }else {
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
          appBar: AppBar(
  title: Text(
    "COD Sales Report",
    style: TextStyle(fontSize: 14, color: Colors.grey),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () async {
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
      } else if (dep == "CEO") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ceo_dashboard()),
        );
      } else if (dep == "CSO") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => cso_dashboard()),
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
      padding: const EdgeInsets.only(left: 10),
      child: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          // Your refresh logic here
          getCODsaleReport(); // Or setState or any fetch function
          selectedFamily=null;
          selectedStaff=null;
          selectedState=null;
        },
      ),
    ),
  ],
),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Family',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text("Select Family"),
                      value: selectedFamily,
                    onChanged: (String? newValue) {
    setState(() {
      selectedFamily = newValue;
      selectedStaff = null;
       filterCodReportList = filterReportByFamily(
      originalReportList: allCodReportList,
      selectedFamily: newValue!,
    );
    });
  getstaff(familyName: newValue); // Fetch staff of selected family only
    //filterReportList(filterCodReportList);
  },

                      items: fam.map((family) {
                        return DropdownMenuItem<String>(
                          value: family['name'],
                          child: Text(family['name']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
           Padding(
  padding: const EdgeInsets.all(8.0),
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Select Staff',
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.5),
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        hint: Text("Select Staff"),
        value: selectedStaff,
        disabledHint: selectedStaff != null
            ? Text(selectedStaff!)
            : null,
        onChanged: selectedStaff == null
            ? (String? newValue) {
                setState(() {
                  selectedStaff = newValue;
                  filterCodReportList = filterReportBystaff(
                    originalReportList: filterCodReportList,
                    selectedStaff: newValue!,
                  );
                });
              }
            : null, // Disable dropdown if staff already selected
        items: sta.map((staff) {
          return DropdownMenuItem<String>(
            value: staff['name'],
            child: Text(staff['name']),
          );
        }).toList(),
      ),
    ),
  ),
),

            Padding(
  padding: const EdgeInsets.all(8.0),
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Select State',
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.5),
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedState,
        hint: Text("Select State"),
        disabledHint: selectedState != null
            ? Text(selectedState!) // Show selected state when disabled
            : null,
        onChanged: selectedState == null
            ? (String? newValue) {
                setState(() {
                  selectedState = newValue;
                  filterCodReportList = filterReportBystate(
                    originalReportList: filterCodReportList,
                    selectedState: newValue!,
                  );
                });
              }
            : null, // disables dropdown after selection
        items: stat.map((state) {
          return DropdownMenuItem<String>(
            value: state['name'],
            child: Text(state['name']),
          );
        }).toList(),
      ),
    ),
  ),
),

              // Show the total orders and amounts for the selected family
        
              filterCodReportList.isEmpty
                  ? Center(child: CircularProgressIndicator()) // Loading indicator
                  : Expanded(
                      child: ListView.builder(
                        itemCount: filterCodReportList.length,
                        itemBuilder: (context, index) {
                          final report = filterCodReportList[index];
                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.all(8.0),
                            elevation: 5.0,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.0),
                              title: Text(
                                'Date: ${report['date']}',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(color: Colors.grey),
                                  Text(
                                    'Total Orders: ${report['total_orders']}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                 Text(
  'Total Amount: ₹${(report['total_amount'] ?? 0).toDouble().toStringAsFixed(2)}',
  style: TextStyle(fontWeight: FontWeight.bold),
),

Text(
  'Paid Amount: ₹${(report['total_paid_amount'] ?? 0).toDouble().toStringAsFixed(2)}',
  style: TextStyle(fontWeight: FontWeight.bold),
),

Text(
  'Balance Amount: ₹${(report['balance_amount'] ?? 0).toDouble().toStringAsFixed(2)}',
  style: TextStyle(fontWeight: FontWeight.bold),
),

                                  SizedBox(
                                    height: 10,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  codsalereport_datewise_view(
                                                      date: report['date'])));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                    child: Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      );
    }
  }
