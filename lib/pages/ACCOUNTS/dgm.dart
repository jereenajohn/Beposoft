import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Dgm extends StatefulWidget {
  final String shipped_date;
  final List<Map<String, dynamic>> topFiveProducts;

  const Dgm({
    super.key,
    required this.shipped_date,
    this.topFiveProducts = const [],
  });

  @override
  State<Dgm> createState() => _DgmState();
}

class _DgmState extends State<Dgm> {
  List<Map<String, dynamic>> courierdata = [];
  List<Map<String, dynamic>> allWarehouses = [];
  Map<String, List<dynamic>> tableDataByFamily = {};
  Map<String, Map<String, Map<String, int>>> parcelServiceCountsByFamily = {};
  Map<String, int> totalOrdersByFamily =
      {}; // New map to store total orders by family
  Map<String, int> totalBoxesByFamily =
      {}; // New map to store total boxes by family
  int totalRowsCount = 0;
  Map<String, int> courierBoxCount = {
    'speed': 0,
    'beparcel': 0,
    'total': 0, // New key for combined total
  };
  Map<String, double> parcelAmountByCourier = {
    'speed': 0.0,
    'beparcel': 0.0,
    'total': 0.0,
  };

  int grandTotal = 0;
  @override
  void initState() {
    super.initState();
    fetchdgmData();
    fetchorders();
    getcourierservices();
  }

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> warehouseList = [
    // ...populate from your API as shown in your sample...
  ];

// Step 1: Aggregate data by parcel_service
  Map<String, Map<String, dynamic>> summary = {};
  Map<String, Map<String, double>> parcelData = {};
  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Set<String> selectedRowKeys = {}; // to store selected rows by unique key

  Future<void> updatecheckedby() async {
    try {
      ;
      final token = await gettokenFromPrefs();
      final jwt = JWT.decode(token!);
      var id = jwt.payload['id']; // Expected to be an int
      var response = await http.put(
        Uri.parse('$api/warehouse/update-checked-by/${widget.shipped_date}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'checked_by': id,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipping charge updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchdgmData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update shipping charge'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shipping charge'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> getcourierservices() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/parcal/service/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed.containsKey('data')) {
          setState(() {
            courierdata = List<Map<String, dynamic>>.from(
                parsed['data'].map((service) => {
                      'id': service['id'],
                      'name': service['name'],
                    }));
          });

          ;
        }
      }
    } catch (error) {}
  }

  Future<void> fetchorders() async {
    ;
    final token = await gettokenFromPrefs();
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

        for (var orderData in orderdata) {
          if (orderData['warehouses'] != null &&
              orderData['warehouses'] is List) {
            allWarehouses.addAll(
                List<Map<String, dynamic>>.from(orderData['warehouses']));
            for (var warehouse in orderData['warehouses']) {
              String? parcelService = warehouse['parcel_service'];
              String? postofficeDate = warehouse['postoffice_date'];
              ;

              double actualWeight =
                  double.tryParse(warehouse['actual_weight'].toString()) ?? 0.0;
              double parcelAmount =
                  double.tryParse(warehouse['parcel_amount'].toString()) ?? 0.0;

              String parcelServiceKey = parcelService ?? '-';

              if (!parcelData.containsKey(parcelServiceKey)) {
                parcelData[parcelServiceKey] = {
                  'total_actual_weight': 0.0,
                  'total_parcel_amount': 0.0,
                };
              }

              parcelData[parcelServiceKey]!['total_actual_weight'] =
                  (parcelData[parcelServiceKey]!['total_actual_weight'] ?? 0) +
                      actualWeight;
              parcelData[parcelServiceKey]!['total_parcel_amount'] =
                  (parcelData[parcelServiceKey]!['total_parcel_amount'] ?? 0) +
                      parcelAmount;
            }
          }
        }

        setState(() {
          orders = orderlist;
        });
      }
    } catch (e) {}
  }

  /// Returns a list of summary maps for each parcel service.
  /// Each map contains: service name, total count, total weight (kg), total amount, and average.
  List<Map<String, dynamic>> getParcelServiceSummary(
      List<Map<String, dynamic>> warehouseList) {
    final Map<String, Map<String, dynamic>> summary = {};

    for (var warehouse in warehouseList) {
      String service = warehouse['parcel_service'] ?? '-';
      double actualWeight =
          double.tryParse(warehouse['actual_weight'].toString()) ?? 0.0;
      double parcelAmount =
          double.tryParse(warehouse['parcel_amount'].toString()) ?? 0.0;

      if (!summary.containsKey(service)) {
        summary[service] = {
          'service': service,
          'count': 0,
          'totalWeight': 0.0,
          'totalAmount': 0.0,
        };
      }
      summary[service]!['count'] += 1;
      summary[service]!['totalWeight'] += actualWeight;
      summary[service]!['totalAmount'] += parcelAmount;
    }

    // Convert to list and calculate average
    return summary.values.map((entry) {
      double totalWeightKg = entry['totalWeight'] / 1000; // grams to KG
      double totalAmount = entry['totalAmount'];
      double avg = totalWeightKg > 0 ? totalAmount / totalWeightKg : 0.0;
      return {
        'service': entry['service'],
        'count': entry['count'],
        'totalWeightKg': totalWeightKg,
        'totalAmount': totalAmount,
        'average': avg,
      };
    }).toList();
  }

  var checked;
  Future<void> fetchdgmData() async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/warehousesdataget/${widget.shipped_date}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Map<String, List<dynamic>> resultsByFamily = {};
        Map<String, Map<String, Map<String, int>>> parcelServiceCounts = {};
        Map<String, int> totalOrdersByFamily = {};
        Map<String, int> totalBoxesByFamily = {};

        String? checked;

        for (var family in data['results']) {
          for (var order in family['orders']) {
            for (var warehouse in order['warehouses']) {
              checked = warehouse['checked_by'];
              break;
            }
            if (checked != null) break;
          }
          if (checked != null) break;
        }

        if (data.containsKey('results')) {
          for (var family in data['results']) {
            String familyName = family['family'];

            resultsByFamily.putIfAbsent(familyName, () => []);
            parcelServiceCounts.putIfAbsent(familyName, () => {});
            totalOrdersByFamily.putIfAbsent(familyName, () => 0);
            totalBoxesByFamily.putIfAbsent(familyName, () => 0);

            for (var order in family['orders']) {
              totalOrdersByFamily[familyName] =
                  totalOrdersByFamily[familyName]! + 1;

              /// ✅ EFFECTIVE BOX COUNT
              int effectiveBoxCount =
                  (order['box_count'] != null && order['box_count'] > 0)
                      ? int.tryParse(order['box_count'].toString()) ??
                          order['warehouses'].length
                      : order['warehouses'].length;

              totalBoxesByFamily[familyName] =
                  totalBoxesByFamily[familyName]! + effectiveBoxCount;

              /// ✅ TOTAL ORDER COD
              double orderCodAmount =
                  double.tryParse(order['cod_amount']?.toString() ?? '0') ??
                      0.0;

              /// ✅ COD PER BOX (RAW)
              double codPerBoxRaw = effectiveBoxCount > 0
                  ? orderCodAmount / effectiveBoxCount
                  : 0.0;

              /// ✅ CEIL ROUNDING (2.5 → 3)
              int codPerBox = codPerBoxRaw.ceil();

              for (var warehouse in order['warehouses']) {
                grandTotal++;

                String parcelService = warehouse['parcel_service_name'] ?? '';

                double parcelAmount = double.tryParse(
                        warehouse['parcel_amount']?.toString() ?? '0') ??
                    0.0;

                /// COURIER COUNTS
                if (parcelService == 'SPEED POST' ||
                    parcelService == 'SPEED COD') {
                  courierBoxCount['speed'] = courierBoxCount['speed']! + 1;
                  parcelAmountByCourier['speed'] =
                      parcelAmountByCourier['speed']! + parcelAmount;
                } else if (parcelService == 'BEPARCEL' ||
                    parcelService == 'BEPARCEL COD') {
                  courierBoxCount['beparcel'] =
                      courierBoxCount['beparcel']! + 1;
                  parcelAmountByCourier['beparcel'] =
                      parcelAmountByCourier['beparcel']! + parcelAmount;
                }

                courierBoxCount['total'] =
                    courierBoxCount['speed']! + courierBoxCount['beparcel']!;
                parcelAmountByCourier['total'] =
                    parcelAmountByCourier['speed']! +
                        parcelAmountByCourier['beparcel']!;

                Map<String, int> parcelServiceCountForOrder = {};
                if (parcelService.isNotEmpty) {
                  for (var courier in courierdata) {
                    String courierName = courier['name'];
                    parcelServiceCountForOrder[courierName] =
                        courierName == parcelService ? 1 : 0;
                  }
                }

                double height =
                    double.tryParse(warehouse['height']?.toString() ?? '0') ??
                        0;
                double length =
                    double.tryParse(warehouse['length']?.toString() ?? '0') ??
                        0;
                double breadth =
                    double.tryParse(warehouse['breadth']?.toString() ?? '0') ??
                        0;

                double volume = height * length * breadth;

                resultsByFamily[familyName]!.add({
                  'invoice_no': warehouse['invoice'] ?? '-',
                  'verified_by': warehouse['verified_by'] ?? '-',
                  'cod': codPerBox.toString(), // ✅ CEILLED COD
                  'phone': warehouse['phone'] ?? '-',
                  'customer': warehouse['customer'] ?? '-',
                  'zip_code': warehouse['zip_code'] ?? '-',
                  'height': warehouse['height']?.toString() ?? '-',
                  'length': warehouse['length']?.toString() ?? '-',
                  'breadth': warehouse['breadth']?.toString() ?? '-',
                  'boxes': effectiveBoxCount.toString(),
                  'aw_kg': warehouse['actual_weight']?.toString() ?? '-',
                  'parcel_amount':
                      warehouse['parcel_amount']?.toString() ?? '-',
                  'tracking_id': warehouse['tracking_id'] ?? '-',
                  'parcel_service_counts': parcelServiceCountForOrder,
                  'volume': volume,
                });

                parcelServiceCounts[familyName]![order['invoice']?.toString() ??
                    ''] = parcelServiceCountForOrder;
              }
            }
          }
        }

        int rowCount = 0;
        for (var family in resultsByFamily.values) {
          rowCount += family.length;
        }

        setState(() {
          tableDataByFamily = resultsByFamily;
          parcelServiceCountsByFamily = parcelServiceCounts;
          this.totalOrdersByFamily = totalOrdersByFamily;
          this.totalBoxesByFamily = totalBoxesByFamily;
          totalRowsCount = rowCount;
          this.courierBoxCount = courierBoxCount;
          this.parcelAmountByCourier = parcelAmountByCourier;
        });
      }
    } catch (e) {}
  }

  Widget _buildDateWiseTopProducts() {
    if (widget.topFiveProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Top 5 Products - ${widget.shipped_date}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade400,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowHeight: 34,
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.blueGrey.shade100,
              ),
              border: TableBorder(
                horizontalInside: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade400,
                ),
                verticalInside: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade400,
                ),
              ),
              columnSpacing: 10,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 55,
                    child: Text(
                      "Sl No",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 230,
                    child: Text(
                      "Product",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 70,
                    child: Text(
                      "Qty",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      "Amount",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
              rows: List<DataRow>.generate(
                widget.topFiveProducts.length,
                (index) {
                  final product = widget.topFiveProducts[index];

                  final String productName =
                      product['display_name']?.toString().isNotEmpty == true
                          ? product['display_name'].toString()
                          : product['product_name']?.toString() ?? '-';

                  final String quantity =
                      product['total_quantity']?.toString() ?? '0';

                  final double amount = double.tryParse(
                        product['total_amount']?.toString() ?? '0',
                      ) ??
                      0.0;

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 55,
                          child: Text(
                            "${index + 1}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 230,
                          child: Text(
                            productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 70,
                          child: Text(
                            quantity,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Text(
                            amount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total boxes by service across all families
    Map<String, int> totalBoxesByServiceAcrossAllFamilies = {};
    // ...existing code...
    final summaryList = getParcelServiceSummary(allWarehouses);
// Calculate total boxes, actual weight, and amount by service across all families
    Map<String, double> totalAwKgByService = {};
    Map<String, double> totalAmountByService = {};

    tableDataByFamily.forEach((familyName, tableData) {
      for (var row in tableData) {
        Map<String, int> parcelServiceCounts =
            row['parcel_service_counts'] ?? {};
        double awKg = double.tryParse(row['aw_kg']?.toString() ?? '0') ?? 0.0;
        double parcelAmount =
            double.tryParse(row['parcel_amount']?.toString() ?? '0') ?? 0.0;

        for (var service in parcelServiceCounts.keys) {
          int count = parcelServiceCounts[service] ?? 0;
          totalBoxesByServiceAcrossAllFamilies[service] =
              (totalBoxesByServiceAcrossAllFamilies[service] ?? 0) + count;

          // If this row is for this service, add its aw_kg and amount
          if (count > 0) {
            totalAwKgByService[service] =
                (totalAwKgByService[service] ?? 0) + awKg;
            totalAmountByService[service] =
                (totalAmountByService[service] ?? 0) + parcelAmount;
          }
        }
      }
    });

// ...existing code...

    return Scaffold(
      appBar: AppBar(
          title: const Text("Goods Movement (DGM)",
              style: TextStyle(fontSize: 12))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            _buildDateWiseTopProducts(),

            const SizedBox(height: 10),
            const Text(
              "Courier Box Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowHeight: 36,
                dataRowHeight: 32,
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.blueGrey.shade100),
                border: TableBorder(
                  horizontalInside:
                      BorderSide(width: 0.5, color: Colors.grey.shade400),
                  verticalInside:
                      BorderSide(width: 0.5, color: Colors.grey.shade400),
                ),
                columnSpacing: 10, // Reduced spacing between columns
                columns: const [
                  DataColumn(
                    label: FittedBox(
                      child: Text(
                        "Courier",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: FittedBox(
                      child: Text(
                        "Boxes",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: FittedBox(
                      child: Text(
                        "Amount",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(FittedBox(
                        child: Text("Speed", style: TextStyle(fontSize: 11)))),
                    DataCell(FittedBox(
                        child: Text(courierBoxCount['speed'].toString(),
                            style: TextStyle(fontSize: 11)))),
                    DataCell(FittedBox(
                        child: Text(
                            parcelAmountByCourier['speed']!.toStringAsFixed(2),
                            style: TextStyle(fontSize: 11)))),
                  ]),
                  DataRow(cells: [
                    DataCell(FittedBox(
                        child:
                            Text("Beparcel", style: TextStyle(fontSize: 11)))),
                    DataCell(FittedBox(
                        child: Text(courierBoxCount['beparcel'].toString(),
                            style: TextStyle(fontSize: 11)))),
                    DataCell(FittedBox(
                        child: Text(
                            parcelAmountByCourier['beparcel']!
                                .toStringAsFixed(2),
                            style: TextStyle(fontSize: 11)))),
                  ]),
                  DataRow(cells: [
                    DataCell(FittedBox(
                        child: Text("Total",
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)))),
                    DataCell(FittedBox(
                        child: Text(courierBoxCount['total'].toString(),
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)))),
                    DataCell(FittedBox(
                        child: Text(
                            parcelAmountByCourier['total']!.toStringAsFixed(2),
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)))),
                  ]),
                ],
              ),
            ),
// if (summaryList.isNotEmpty)
//   Container(
//     width: double.infinity,
//     decoration: BoxDecoration(
//       border: Border.all(color: Colors.grey.shade400),
//       borderRadius: BorderRadius.circular(8),
//     ),
//     margin: const EdgeInsets.symmetric(vertical: 8),
//     child: FittedBox(
//       child: DataTable(
//         headingRowHeight: 28,
//         dataRowHeight: 20,
//         columnSpacing: 20,
//         headingRowColor: MaterialStateColor.resolveWith(
//             (states) => const Color.fromARGB(255, 1, 133, 190)),
//         border: TableBorder(
//           horizontalInside: BorderSide(width: 0.5, color: Colors.grey.shade400),
//           verticalInside: BorderSide(width: 0.5, color: Colors.grey.shade400),
//         ),
//         columns: const [
//           DataColumn(
//             label: Text(
//               "Parcel Service",
//               style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               "Total Boxes",
//               style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               "Total AW (KG)",
//               style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               "Total Amount",
//               style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               "Average",
//               style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//         rows: [
//           ...summaryList.map((entry) {
//             return DataRow(
//               cells: [
//                 DataCell(FittedBox(child: Text(entry['service'].toString(), style: TextStyle(fontSize: 8)))),
//                 DataCell(FittedBox(child: Text(entry['count'].toString(), style: TextStyle(fontSize: 8)))),
//                 DataCell(FittedBox(child: Text(entry['totalWeightKg'].toStringAsFixed(2), style: TextStyle(fontSize: 8)))),
//                 DataCell(FittedBox(child: Text(entry['totalAmount'].toStringAsFixed(2), style: TextStyle(fontSize: 8)))),
//                 DataCell(FittedBox(child: Text(entry['average'].toStringAsFixed(2), style: TextStyle(fontSize: 8)))),
//               ],
//             );
//           }),
//           // --- GRAND TOTAL ROW ---
//           DataRow(
//             color: MaterialStateColor.resolveWith((states) => Colors.amber.shade200),
//             cells: [
//               DataCell(FittedBox(
//                 child: Text(
//                   "Grand Total",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
//                 ),
//               )),
//               DataCell(FittedBox(
//                 child: Text(
//                   '${summaryList.fold<int>(0, (sum, entry) => sum + (entry['count'] as int))}',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
//                 ),
//               )),
//               DataCell(FittedBox(
//                 child: Text(
//                   '${summaryList.fold<double>(0.0, (sum, entry) => sum + (entry['totalWeightKg'] as double)).toStringAsFixed(2)}',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
//                 ),
//               )),
//               DataCell(FittedBox(
//                 child: Text(
//                   '${summaryList.fold<double>(0.0, (sum, entry) => sum + (entry['totalAmount'] as double)).toStringAsFixed(2)}',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
//                 ),
//               )),
//               DataCell(FittedBox(
//                 child: Text(
//                   (() {
//                     double totalWeightKg = summaryList.fold<double>(0.0, (sum, entry) => sum + (entry['totalWeightKg'] as double));
//                     double totalAmount = summaryList.fold<double>(0.0, (sum, entry) => sum + (entry['totalAmount'] as double));
//                     return totalWeightKg > 0 ? (totalAmount / totalWeightKg).toStringAsFixed(2) : '0.00';
//                   })(),
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
//                 ),
//               )),
//             ],
//           ),
//         ],
//       ),
//     ),
//   ),
            SizedBox(height: 10),
            Text(
              "Summary",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            // Calculate grand total

            Container(
              width: double.infinity, // Ensures full width of parent
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                // Scales content to fit
                child: DataTable(
                  headingRowHeight: 28,
                  dataRowHeight: 20,
                  columnSpacing: 20,
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => const Color.fromARGB(255, 1, 133, 190)),
                  border: TableBorder(
                    horizontalInside:
                        BorderSide(width: 0.5, color: Colors.grey.shade400),
                    verticalInside:
                        BorderSide(width: 0.5, color: Colors.grey.shade400),
                  ),
                  // ...existing code...
// ...existing code...
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Parcel Service",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total Boxes",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total AW (KG)",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total Amount",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Average",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
// ...existing code...
                  rows: [
                    ...courierdata
                        .where((courier) =>
                            (totalBoxesByServiceAcrossAllFamilies[
                                    courier['name']] ??
                                0) >
                            0)
                        .map((courier) {
                      String serviceName = courier['name'];
                      int totalBoxes =
                          totalBoxesByServiceAcrossAllFamilies[serviceName] ??
                              0;
                      double totalAwKg = totalAwKgByService[serviceName] ?? 0.0;
                      double totalAmount =
                          totalAmountByService[serviceName] ?? 0.0;
                      double avgAmountPerKg = (totalAwKg > 0)
                          ? (totalAmount / (totalAwKg / 1000))
                          : 0.0;
                      return DataRow(
                        cells: [
                          DataCell(FittedBox(
                              child: Text(serviceName,
                                  style: TextStyle(fontSize: 8)))),
                          DataCell(FittedBox(
                              child: Text(totalBoxes.toString(),
                                  style: TextStyle(fontSize: 8)))),
                          DataCell(FittedBox(
                              child: Text((totalAwKg / 1000).toStringAsFixed(2),
                                  style: TextStyle(fontSize: 8)))),
                          DataCell(FittedBox(
                              child: Text(totalAmount.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 8)))),
                          DataCell(FittedBox(
                              child: Text(avgAmountPerKg.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 8)))),
                        ],
                      );
                    }),

                    // --- GRAND TOTAL ROW ---
                    DataRow(
                      color: MaterialStateColor.resolveWith(
                          (states) => Colors.amber.shade200),
                      cells: [
                        DataCell(FittedBox(
                          child: Text(
                            "Grand Total",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${totalBoxesByServiceAcrossAllFamilies.values.fold<int>(0, (a, b) => a + b)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${(totalAwKgByService.values.fold<double>(0.0, (a, b) => a + b) / 1000).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${totalAmountByService.values.fold<double>(0.0, (a, b) => a + b).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            (() {
                              double totalAwKg = totalAwKgByService.values
                                  .fold<double>(0.0, (a, b) => a + b);
                              double totalAmount = totalAmountByService.values
                                  .fold<double>(0.0, (a, b) => a + b);
                              double totalAwKgInKg = totalAwKg / 1000;
                              return totalAwKgInKg > 0
                                  ? (totalAmount / totalAwKgInKg)
                                      .toStringAsFixed(2)
                                  : '0.00';
                            })(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                      ],
                    ),

                    // --- TOTAL ROW (Speed COD + Beparcel COD) ---
                    DataRow(
                      color: MaterialStateColor.resolveWith(
                          (states) => const Color.fromARGB(255, 120, 199, 234)),
                      cells: [
                        DataCell(FittedBox(
                          child: Text(
                            "Total (Speed COD + Beparcel COD)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${(totalBoxesByServiceAcrossAllFamilies["SPEED COD"] ?? 0) + (totalBoxesByServiceAcrossAllFamilies["BEPARCEL COD"] ?? 0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${(((totalAwKgByService["SPEED COD"] ?? 0.0) + (totalAwKgByService["BEPARCEL COD"] ?? 0.0)) / 1000).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            '${((totalAmountByService["SPEED COD"] ?? 0.0) + (totalAmountByService["BEPARCEL COD"] ?? 0.0)).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                        DataCell(FittedBox(
                          child: Text(
                            (() {
                              double totalAwKg =
                                  (totalAwKgByService["SPEED COD"] ?? 0.0) +
                                      (totalAwKgByService["BEPARCEL COD"] ??
                                          0.0);
                              double totalAmount =
                                  (totalAmountByService["SPEED COD"] ?? 0.0) +
                                      (totalAmountByService["BEPARCEL COD"] ??
                                          0.0);
                              double totalAwKgInKg = totalAwKg / 1000;
                              return totalAwKgInKg > 0
                                  ? (totalAmount / totalAwKgInKg)
                                      .toStringAsFixed(2)
                                  : '0.00';
                            })(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            checked != null
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Final Confirmation by: ",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: "$checked",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  )
                : selectedRowKeys.length == totalRowsCount && totalRowsCount > 0
                    ? ElevatedButton(
                        onPressed: () {
                          updatecheckedby();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: Text("CHECK HERE",
                            style: TextStyle(color: Colors.white)),
                      )
                    : Container(),
            SizedBox(height: 10),
            ...tableDataByFamily.entries.map((entry) {
              // Your original card generation logic for each family
              String familyName = entry.key;
              List<dynamic> tableData = entry.value;
              int totalOrders = totalOrdersByFamily[familyName] ?? 0;
              int totalBoxes = totalBoxesByFamily[familyName] ?? 0;

              Map<String, int> totalBoxesByService = {};
              double totalAwKg = 0.0;
              double totalParcelAmount = 0.0;
              double totalvolume = 0.0;
              for (var row in tableData) {
                Map<String, int> parcelServiceCounts =
                    row['parcel_service_counts'] ?? {};
                for (var service in parcelServiceCounts.keys) {
                  totalBoxesByService[service] =
                      (totalBoxesByService[service] ?? 0) +
                          parcelServiceCounts[service]!;
                }
                totalAwKg += double.tryParse(row['aw_kg'].toString()) ?? 0.0;
                totalvolume += double.tryParse(row['volume'].toString()) ?? 0.0;
                totalParcelAmount +=
                    double.tryParse(row['parcel_amount'].toString()) ?? 0.0;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$familyName (Total Orders: $totalOrders, Total Boxes: $totalBoxes)",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 32,
                            dataRowHeight: 32,
                            columnSpacing: 12,
                            headingRowColor: MaterialStateColor.resolveWith(
                              (states) =>
                                  const Color.fromARGB(255, 1, 133, 190),
                            ),
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                  width: 0.5, color: Colors.grey.shade400),
                              verticalInside: BorderSide(
                                  width: 0.5, color: Colors.grey.shade300),
                            ),
                            columns: [
                              const DataColumn(
                                  label: Text("Sl No",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Invoice No",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Phone",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Customer",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Verified by",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("COD",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Boxes",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              ...courierdata.map((courier) {
                                return DataColumn(
                                  label: Text(
                                    courier['name'],
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                );
                              }),
                              const DataColumn(
                                  label: Text("AW (G)",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Amount",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Volume",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                              const DataColumn(
                                  label: Text("Tracking Id",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12))),
                            ],
                            rows: [
                              ...List<DataRow>.generate(tableData.length,
                                  (index) {
                                var row = tableData[index];
                                String rowKey =
                                    row["invoice_no"] ?? index.toString();
                                Map<String, int> parcelServiceCounts =
                                    row['parcel_service_counts'] ?? {};
                                bool isSelected =
                                    selectedRowKeys.contains(rowKey);

                                return DataRow(
                                  selected: isSelected,
                                  color:
                                      MaterialStateColor.resolveWith((states) {
                                    return isSelected
                                        ? const Color.fromARGB(
                                            255, 218, 248, 255)
                                        : Colors.transparent;
                                  }),
                                  onSelectChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedRowKeys.add(rowKey);
                                      } else {
                                        selectedRowKeys.remove(rowKey);
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(Text((index + 1).toString(),
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(row["invoice_no"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(row["phone"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(row["customer"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(row["verified_by"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(row["cod"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(
                                        row["boxes"]?.toString() ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    ...courierdata.map((courier) {
                                      String serviceName = courier['name'];
                                      int count =
                                          parcelServiceCounts[serviceName] ?? 0;
                                      return DataCell(Text(count.toString(),
                                          style: TextStyle(fontSize: 11)));
                                    }),
                                    DataCell(Text(
                                        row["aw_kg"]?.toString() ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(
                                        row["parcel_amount"]?.toString() ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                    DataCell(Text(
                                      (row["volume"] != null)
                                          ? (row["volume"] is int
                                              ? (row["volume"] as int)
                                                  .toDouble()
                                                  .toStringAsFixed(2)
                                              : (row["volume"] is double
                                                  ? (row["volume"] as double)
                                                      .toStringAsFixed(2)
                                                  : row["volume"].toString()))
                                          : '-',
                                      style: TextStyle(fontSize: 11),
                                    )),
                                    DataCell(Text(row["tracking_id"] ?? '-',
                                        style: TextStyle(fontSize: 11))),
                                  ],
                                );
                              }),
                              DataRow(
                                color: MaterialStateColor.resolveWith(
                                    (states) => const Color.fromARGB(
                                        255, 120, 199, 234)!),
                                cells: [
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),

                                  DataCell(Text('$totalBoxes',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11))),
                                  ...courierdata.map((courier) {
                                    String serviceName = courier['name'];
                                    int totalBoxes =
                                        totalBoxesByService[serviceName] ?? 0;
                                    return DataCell(Text(totalBoxes.toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)));
                                  }),
// ...existing code...summ
                                  DataCell(
                                    Text(
                                      "${totalAwKg.toStringAsFixed(2)} (${(totalAwKg / 1000).toStringAsFixed(2)} KG)",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    ),
                                  ),
// ...existing code...
                                  DataCell(Text(
                                      totalParcelAmount.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11))),
                                  DataCell(Text(totalvolume.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11))),
                                  DataCell(Text('')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
