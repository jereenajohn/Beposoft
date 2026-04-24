import 'dart:convert';
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
import 'package:intl/intl.dart';

class PostofficeReport_monthly extends StatefulWidget {
  const PostofficeReport_monthly({super.key});

  @override
  State<PostofficeReport_monthly> createState() => _PostofficeReport_monthlyState();
}

class _PostofficeReport_monthlyState extends State<PostofficeReport_monthly> {
  List<Map<String, dynamic>> orders = [];
  Map<String, Map<String, double>> parcelData = {};
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
  @override
  void initState() {
    super.initState();
    fetchorders();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
double grandTotalWeightKg = 0.0;
double grandTotalParcelAmount = 0.0;
Future<void> fetchorders() async {
  final token = await getTokenFromPrefs();
  try {
    final response = await http.get(
      Uri.parse('$api/api/warehouse/get/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final orderdata = parsed['results'];
      List<Map<String, dynamic>> orderlist = [];
      parcelData.clear();

      // Determine which date to use as the current month reference
      final DateTime selected = selectedDate ?? DateTime.now();
      final int selectedMonth = selected.month;
      final int selectedYear = selected.year;

      for (var orderData in orderdata) {
        if (orderData['warehouses'] != null && orderData['warehouses'] is List) {
          for (var warehouse in orderData['warehouses']) {
            String? parcelService = warehouse['parcel_service'];
            String? postofficeDate = warehouse['postoffice_date'];

            if (postofficeDate != null && postofficeDate.isNotEmpty) {
              final parsedDate = DateTime.tryParse(postofficeDate);

              if (parsedDate != null &&
                  parsedDate.month == selectedMonth &&
                  parsedDate.year == selectedYear &&
                  parcelService != null &&
                  parcelService.isNotEmpty) {
                    
                double actualWeight =
                    double.tryParse(warehouse['actual_weight'].toString()) ?? 0.0;
                double parcelAmount =
                    double.tryParse(warehouse['parcel_amount'].toString()) ?? 0.0;

                if (!parcelData.containsKey(parcelService)) {
                  parcelData[parcelService] = {
                    'total_actual_weight': 0.0,
                    'total_parcel_amount': 0.0,
                  };
                }

                parcelData[parcelService]!['total_actual_weight'] =
                    (parcelData[parcelService]!['total_actual_weight'] ?? 0) + actualWeight;
                parcelData[parcelService]!['total_parcel_amount'] =
                    (parcelData[parcelService]!['total_parcel_amount'] ?? 0) + parcelAmount;
              }
            }
          }
        }
      }

      setState(() {
        orders = orderlist;
      });
    }
  } catch (e) {
  }
}

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchorders(); // Fetch orders based on the selected date
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
     await fetchorders2();
    }
  }

  Future<void> fetchorders2() async {
    
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/get/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
         final orderdata=parsed['results'];


        List<Map<String, dynamic>> orderlist = [];
        parcelData.clear();

        for (var orderData in orderdata) {
          List<Map<String, dynamic>> warehouseList = [];

          if (orderData['warehouses'] != null) {
            for (var warehouse in orderData['warehouses']) {
              String parcelService = warehouse['parcel_service'] ??
                  ""; // Default to empty string if null
              String? postofficeDate = warehouse['postoffice_date'];
              String? shippedDateStr = warehouse['postoffice_date'];
              DateTime? shippedDate;

              // Parse the shipped_date to DateTime
              if (shippedDateStr != null && shippedDateStr.isNotEmpty) {
                shippedDate = DateTime.parse(shippedDateStr);
              }

            

              // Check if the shipped_date is within the selected date range
              if (shippedDate != null &&
                  shippedDate.isAfter(startDate!) &&
                  shippedDate.isBefore(endDate!)) {
                double actualWeight =
                    double.tryParse(warehouse['actual_weight'].toString()) ??
                        0.0;
                double parcelAmount =
                    double.tryParse(warehouse['parcel_amount'].toString()) ??
                        0.0;

                if (!parcelData.containsKey(parcelService)) {
                  parcelData[parcelService] = {
                    'total_actual_weight': 0.0,
                    'total_parcel_amount': 0.0,
                  };
                }

                parcelData[parcelService]!['total_actual_weight'] =
                    (parcelData[parcelService]!['total_actual_weight'] ?? 0) +
                        actualWeight;
                parcelData[parcelService]!['total_parcel_amount'] =
                    (parcelData[parcelService]!['total_parcel_amount'] ?? 0) +
                        parcelAmount;
              }
            }
          }
        }

        Map<String, double> parcelAverages = {};

        setState(() {
          parcelData.forEach((parcelService, data) {
            double totalActualWeight = data['total_actual_weight'] ?? 0.0;
            double totalParcelAmount = data['total_parcel_amount'] ?? 1.0;
               double average = totalParcelAmount / totalActualWeight;
            parcelAverages[parcelService] = average;


          });
          

          orders = orderlist;
          
        });
      }
    } catch (e) {
      
    }
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
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
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
            "Monthly Parcel Average",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
      
           leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
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
      else if(dep=="Warehouse Admin" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
              );
      }
           
           else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}

   else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          dashboard()), // Replace AnotherPage with your target page
                );
              }
            },
          ),
        
        ),
     body: parcelData.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text(
              "data is Fetching....",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
    : RefreshIndicator(
        onRefresh: fetchorders,
        child: Builder(
          builder: (context) {
            // Work on a stable list of entries
            final entries = parcelData.entries.toList();

            // Grand totals (compute ONCE)
            final double grandTotalWeightKg = entries.fold(
              0.0,
              (sum, e) => sum + ((e.value['total_actual_weight'] ?? 0.0) / 1000.0),
            );
            final double grandTotalParcelAmount = entries.fold(
              0.0,
              (sum, e) => sum + (e.value['total_parcel_amount'] ?? 0.0),
            );
            final double grandAverage = grandTotalWeightKg > 0
                ? grandTotalParcelAmount / grandTotalWeightKg
                : 0.0;

            return ListView.builder(
              itemCount: entries.length + 1, // +1 for GRAND TOTAL card
              itemBuilder: (context, index) {
                // Last index -> grand total card
                if (index == entries.length) {
                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [   Color(0xFF02347C),  Color(0xFF82E49D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.summarize, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "GRAND TOTAL",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white70),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Total Actual Weight",
                            "${grandTotalWeightKg.toStringAsFixed(3)} kg",
                          ),
                          _buildInfoRow(
                            "Total Parcel Amount",
                            "₹${grandTotalParcelAmount.toStringAsFixed(2)}",
                          ),
                          _buildInfoRow(
                            "Average",
                            grandAverage.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Regular item card
                final entry = entries[index];
                final parcelService = entry.key;
                final data = entry.value;

                final double totalWeightKg =
                    (data['total_actual_weight'] ?? 0.0) / 1000.0;
                final double totalAmount =
                    (data['total_parcel_amount'] ?? 0.0);
                final double average = totalWeightKg > 0
                    ? totalAmount / totalWeightKg
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 58, 143, 183),
                          Color.fromARGB(255, 64, 170, 251)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              parcelService.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white70),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "Total Actual Weight",
                          "${totalWeightKg.toStringAsFixed(3)} kg",
                        ),
                        _buildInfoRow(
                          "Total Parcel Amount",
                          "₹${totalAmount.toStringAsFixed(2)}",
                        ),
                        _buildInfoRow(
                          "Average",
                          average.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
