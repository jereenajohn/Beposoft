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
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class trackingReport extends StatefulWidget {
  const trackingReport({super.key});

  @override
  State<trackingReport> createState() => _trackingReportState();
}

class _trackingReportState extends State<trackingReport> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  Map<String, Map<String, double>> parcelData = {};
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
  @override
  void initState() {
    super.initState();
    fetchtracking();
    getcourierservices();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void applyFilters() {
    final courierFiltered = filterOrdersByCourier();

    final lowerSearch = searchText.toLowerCase().trim();

    final result = courierFiltered.where((order) {
      final customerName =
          order['customerName']?.toString().toLowerCase() ?? '';
      final invoice = order['invoice']?.toString().toLowerCase() ?? '';
      final tracking_id = order['tracking_id']?.toString().toLowerCase() ?? '';

      return customerName.contains(lowerSearch) ||
          invoice.contains(lowerSearch) ||
          tracking_id.contains(lowerSearch);
    }).toList();

    setState(() {
      filteredOrders = result;
    });
  }

  void applyFilters2() {
    final all = orders;
    if (selectedCourierId == null) {
      setState(() => filteredOrders = all);
      return;
    }

    final selectedName = courierdata
        .firstWhere((c) => c['id'].toString() == selectedCourierId,
            orElse: () => {'name': ''})['name']
        .toString()
        .toLowerCase()
        .trim();

    final result = all.where((order) {
      final customerName =
          order['customerName']?.toString().toLowerCase() ?? '';
      final invoice = order['invoice']?.toString().toLowerCase() ?? '';
      final trackingId = order['tracking_id']?.toString().toLowerCase() ?? '';
      final parcelSvc = order['parcel_service']?.toString().toLowerCase() ?? '';
      return customerName.contains(selectedName) ||
          invoice.contains(selectedName) ||
          trackingId.contains(selectedName) ||
          parcelSvc.contains(selectedName);
    }).toList();

    setState(() => filteredOrders = result);
  }

  Future<void> fetchtracking() async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/orders/parcel/service/data/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final services = parsed['services'] as List<dynamic>? ?? [];
        List<Map<String, dynamic>> orderlist = [];

        for (var service in services) {
          final serviceName = service['parcel_service_name'] ?? '';
          final items = service['items'] as List<dynamic>? ?? [];

          for (var item in items) {
            // keep only valid tracking IDs
            final trackingId = item['tracking_id']?.toString().trim() ?? '';
            if (trackingId.isEmpty || trackingId == "0") continue;

            double actualKg =
                (double.tryParse(item['actual_weight']?.toString() ?? '0') ??
                        0.0) /
                    1000;
            double trackAmt =
                double.tryParse(item['parcel_amount']?.toString() ?? '0') ??
                    0.0;

            orderlist.add({
              'shipped_date': item['shipped_date'],
              'invoice': item['invoice'],
              'customerName': item['customerName'],
              'total_amount':
                  double.tryParse(item['total_amount']?.toString() ?? '0') ??
                      0.0,
              'parcel_amount': trackAmt,
              'tracking_id': trackingId,
              'parcel_service': serviceName,
              'weight': item['weight'],
              'actual_weight': actualKg,
              'volume_weight':
                  double.tryParse(item['volume_weight']?.toString() ?? '0') ??
                      0.0,
              'box': item['box'],
              'average': actualKg > 0 ? (trackAmt / actualKg) : 0,
            });
          }
        }

        setState(() {
          orders = orderlist;
          filteredOrders = orderlist;
        });
      } else {}
    } catch (e) {}
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
      fetchtracking(); // Fetch orders based on the selected date
    }
  }

  List<Map<String, dynamic>> filterOrdersByCourier() {
    if (selectedCourierId == null) return orders;

    final selectedCourierName = courierdata
        .firstWhere((c) => c['id'].toString() == selectedCourierId,
            orElse: () => {'name': ''})['name']
        .toString()
        .toLowerCase()
        .trim();

    return orders.where((order) {
      final warehouseList = order['warehouse_data'] as List<dynamic>?;

      return warehouseList != null &&
          warehouseList.any((parcel) =>
              parcel['parcel_service'] != null &&
              parcel['parcel_service'].toString().toLowerCase().trim() ==
                  selectedCourierName);
    }).toList();
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
      filterOrdersByDateRange();
    }
  }

  void filterOrdersByDateRange() {
    if (startDate == null || endDate == null) return;

    // Convert start and end to date-only for clean comparison
    final DateTime start =
        DateTime(startDate!.year, startDate!.month, startDate!.day);
    final DateTime end = DateTime(endDate!.year, endDate!.month, endDate!.day);

    List<Map<String, dynamic>> filtered = filteredOrders.where((order) {
      final dateStr = order['shipped_date'];

      if (dateStr == null || dateStr.toString().trim().isEmpty) return false;

      try {
        DateTime shippedDate = DateTime.parse(dateStr.toString());

        // Convert to date-only (removes time)
        shippedDate =
            DateTime(shippedDate.year, shippedDate.month, shippedDate.day);

        // Inclusive comparison:
        return shippedDate.isAtSameMomentAs(start) ||
            shippedDate.isAtSameMomentAs(end) ||
            (shippedDate.isAfter(start) && shippedDate.isBefore(end));
      } catch (e) {
        return false;
      }
    }).toList();

    setState(() {
      filteredOrders = filtered;
    });
  }

  List<Map<String, dynamic>> courierdata = [];
  String? selectedCourierId; // store ID as string

  Future<void> getcourierservices() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/parcal/service/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<Map<String, dynamic>> list = [];

        if (parsed is Map && parsed.containsKey('data')) {
          for (final item in parsed['data']) {
            list.add({
              'id': item['id'],
              'name': (item['name'] ?? '').toString().trim(),
            });
          }
        }

        // ✅ Deduplicate by id
        final seen = <String>{};
        list.removeWhere((e) {
          final id = e['id']?.toString() ?? '';
          if (seen.contains(id)) return true;
          seen.add(id);
          return false;
        });

        setState(() {
          courierdata = list;

          // ✅ If current selection no longer exists, clear it
          final stillExists =
              courierdata.any((c) => c['id'].toString() == selectedCourierId);
          if (!stillExists) selectedCourierId = null;
        });
      }
    } catch (error) {
      // handle/log error if needed
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
        final orderdata = parsed['results'];

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
            double average = totalActualWeight / totalParcelAmount;
            parcelAverages[parcelService] = average;
          });

          orders = orderlist;
        });
      }
    } catch (e) {}
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

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied')),
        );
      }
    }
  }

  Future<void> generateExcelAndShare() async {
    await requestStoragePermission();

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      final s = v.toString().trim().replaceAll(',', '');
      return double.tryParse(s) ?? 0.0;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Tracking Report'];

      final headerStyle = CellStyle(
        backgroundColorHex: "#87CEEB",
        fontColorHex: "#000000",
        bold: true,
      );

      final totalStyle = CellStyle(
        backgroundColorHex: "#FFFF00",
        fontColorHex: "#FF0000",
        bold: true,
      );

      final groupHeaderStyle = CellStyle(
        backgroundColorHex: "#FFA500",
        fontColorHex: "#000000",
        bold: true,
      );

      final headers = [
        'DATE',
        'INVOICE NO',
        'CUSTOMER NAME',
        'INVOICE AMOUNT',
        'TRACKING AMOUNT',
        'TRACKING NUMBER',
        'WEIGHT',
        'ACTUAL WEIGHT (KG)',
        'VOLUME WEIGHT',
        'BOX',
        'AVERAGE'
      ];

      //----------------------------------------------------------------------
      // 1. INDIVIDUAL TOTALS: BEPARCEL, SPEED, GRAND TOTAL
      //----------------------------------------------------------------------
      double totalInvoiceBe = 0,
          totalTrackingBe = 0,
          totalPostBe = 0,
          totalActualBe = 0,
          totalVolumeBe = 0;
      int totalBoxesBe = 0;

      double totalInvoiceSp = 0,
          totalTrackingSp = 0,
          totalPostSp = 0,
          totalActualSp = 0,
          totalVolumeSp = 0;
      int totalBoxesSp = 0;

      double totalInvoice = 0,
          totalTrackingAmt = 0,
          totalPostWeight = 0,
          totalActualWeight = 0,
          totalVolumeWeight = 0;
      int totalBoxes = 0;

      // row-wise processing
      for (final row in filteredOrders) {
        final service =
            (row['parcel_service'] ?? '').toString().toUpperCase().trim();
        final amt = _toDouble(row['total_amount']);
        final track = _toDouble(row['parcel_amount']);
        final post = _toDouble(row['weight']);
        final actual = _toDouble(row['actual_weight']); // already KG
        final volume = _toDouble(row['volume_weight']);

        double rowAvg = actual > 0 ? (track / actual) : 0;

        // Grand totals
        totalInvoice += amt;
        totalTrackingAmt += track;
        totalPostWeight += post;
        totalActualWeight += actual;
        totalVolumeWeight += volume;
        totalBoxes++;

        // BEPARCEL totals
        if (service.contains("BEPARCEL")) {
          totalInvoiceBe += amt;
          totalTrackingBe += track;
          totalPostBe += post;
          totalActualBe += actual;
          totalVolumeBe += volume;
          totalBoxesBe++;
        }

        // SPEED totals
        if (service.contains("SPEED")) {
          totalInvoiceSp += amt;
          totalTrackingSp += track;
          totalPostSp += post;
          totalActualSp += actual;
          totalVolumeSp += volume;
          totalBoxesSp++;
        }
      }

      double avgBe = totalActualBe > 0 ? totalTrackingBe / totalActualBe : 0;
      double avgSp = totalActualSp > 0 ? totalTrackingSp / totalActualSp : 0;
      double avgGrand =
          totalActualWeight > 0 ? totalTrackingAmt / totalActualWeight : 0;

      //----------------------------------------------------------------------
      // 2. HEADER ROW
      //----------------------------------------------------------------------
      final headerRowIndex = sheet.maxRows;

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: headerRowIndex));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      //----------------------------------------------------------------------
      // 3. BEPARCEL TOTAL ROW
      //----------------------------------------------------------------------
      int rowIndex = headerRowIndex + 1;

      List<dynamic> beRow = [
        'BEPARCEL TOTAL',
        '',
        '',
        totalInvoiceBe.toStringAsFixed(2),
        totalTrackingBe.toStringAsFixed(2),
        '-',
        totalPostBe.toStringAsFixed(2),
        totalActualBe.toStringAsFixed(2),
        totalVolumeBe.toStringAsFixed(2),
        totalBoxesBe.toString(),
        avgBe.toStringAsFixed(2)
      ];

      for (int i = 0; i < beRow.length; i++) {
        var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = beRow[i];
        cell.cellStyle = totalStyle;
      }

      //----------------------------------------------------------------------
      // 4. SPEED TOTAL ROW
      //----------------------------------------------------------------------
      rowIndex++;

      List<dynamic> spRow = [
        'SPEED TOTAL',
        '',
        '',
        totalInvoiceSp.toStringAsFixed(2),
        totalTrackingSp.toStringAsFixed(2),
        '-',
        totalPostSp.toStringAsFixed(2),
        totalActualSp.toStringAsFixed(2),
        totalVolumeSp.toStringAsFixed(2),
        totalBoxesSp.toString(),
        avgSp.toStringAsFixed(2)
      ];

      for (int i = 0; i < spRow.length; i++) {
        var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = spRow[i];
        cell.cellStyle = totalStyle;
      }

      //----------------------------------------------------------------------
      // 5. GRAND TOTAL ROW
      //----------------------------------------------------------------------
      rowIndex++;

      List<dynamic> grandRow = [
        'GRAND TOTAL',
        '',
        '',
        totalInvoice.toStringAsFixed(2),
        totalTrackingAmt.toStringAsFixed(2),
        '-',
        totalPostWeight.toStringAsFixed(2),
        totalActualWeight.toStringAsFixed(2),
        totalVolumeWeight.toStringAsFixed(2),
        totalBoxes.toString(),
        avgGrand.toStringAsFixed(2)
      ];

      for (int i = 0; i < grandRow.length; i++) {
        var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = grandRow[i];
        cell.cellStyle = totalStyle;
      }

      sheet.appendRow([]); // empty row

      //----------------------------------------------------------------------
      // 6. DATE-WISE GROUPING
      //----------------------------------------------------------------------
      final serviceGroups = {
        'BEPARCEL': ['BEPARCEL', 'BEPARCEL COD'],
        'SPEED': ['SPEED POST', 'SPEED COD'],
      };

      final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};

      for (final row in filteredOrders) {
        final trackingId = (row['tracking_id'] ?? '').toString().trim();
        if (trackingId.isEmpty || trackingId == '0') continue;

        final service =
            (row['parcel_service'] ?? '').toString().toUpperCase().trim();

        String? groupName;
        serviceGroups.forEach((key, list) {
          if (list.contains(service)) groupName = key;
        });
        if (groupName == null) continue;

        final date = (row['shipped_date'] ?? 'Unknown').toString();

        grouped.putIfAbsent(date, () => {});
        grouped[date]!.putIfAbsent(groupName!, () => []);
        grouped[date]![groupName]!.add(row);
      }

      final sortedDates = grouped.keys.toList()..sort();
      rowIndex = sheet.maxRows + 1;

      for (final date in sortedDates) {
        sheet.appendRow(['']);
        rowIndex++;

        final dateCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        dateCell.value = date;
        dateCell.cellStyle = groupHeaderStyle;
        rowIndex++;

        for (final group in ['BEPARCEL', 'SPEED']) {
          final rows = grouped[date]![group];
          if (rows == null || rows.isEmpty) continue;

          final groupCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
          groupCell.value = group;
          groupCell.cellStyle = groupHeaderStyle;
          rowIndex++;

          double amt = 0, track = 0, post = 0, actual = 0, vol = 0;
          int boxCount = 0;

          for (final p in rows) {
            double trAmt = _toDouble(p['parcel_amount']);
            double acKg = _toDouble(p['actual_weight']);
            double rowAvg = acKg > 0 ? trAmt / acKg : 0;

            sheet.appendRow([
              p['shipped_date'],
              p['invoice'],
              p['customerName'],
              p['total_amount'],
              trAmt,
              p['tracking_id'],
              p['weight'],
              acKg.toStringAsFixed(2),
              p['volume_weight'],
              p['box'],
              rowAvg.toStringAsFixed(2)
            ]);
            rowIndex++;

            amt += _toDouble(p['total_amount']);
            track += trAmt;
            post += _toDouble(p['weight']);
            actual += acKg;
            vol += _toDouble(p['volume_weight']);
            boxCount++;
          }

          double groupAvg = actual > 0 ? track / actual : 0;

          final totalRow = [
            '',
            'TOTAL',
            '',
            amt.toStringAsFixed(2),
            track.toStringAsFixed(2),
            '-',
            post.toStringAsFixed(2),
            actual.toStringAsFixed(2),
            vol.toStringAsFixed(2),
            boxCount.toString(),
            groupAvg.toStringAsFixed(2)
          ];

          for (int i = 0; i < totalRow.length; i++) {
            final cell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
            cell.value = totalRow[i];
            cell.cellStyle = totalStyle;
          }

          rowIndex++;
        }
      }

      //----------------------------------------------------------------------
      // 7. SAVE + SHARE FILE
      //----------------------------------------------------------------------
      final bytes = excel.encode();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Tracking_Report_ByDate_Grouped.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes!);

      await Share.shareXFiles([XFile(file.path)],
          text: "📦 Date-wise Courier Tracking Report");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Export failed: $e')),
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
            "Post Office Report",
            style: TextStyle(color: Colors.grey, fontSize: 14),
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
              icon: Icon(Icons.refresh),
              onPressed: () {
                fetchtracking();
                selectedCourierId = null;
                searchController.text = "";
              },
            ),
            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
            IconButton(
              icon: Icon(Icons.file_download),
              tooltip: "Export Excel",
              onPressed: generateExcelAndShare, // ✅ NEW
            ),
          ],
        ),
        body: orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by Customer, Invoice, Courier, Tracking ID',
                        prefixIcon: Icon(Icons.search, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.teal, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                          applyFilters();
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "📦 Courier Service",
                        labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal),
                        prefixIcon: const Icon(Icons.local_shipping,
                            color: Colors.teal),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.teal),

                          // ✅ Keep value only if it exists in the items
                          value: courierdata.any((c) =>
                                  c['id'].toString() == selectedCourierId)
                              ? selectedCourierId
                              : null,

                          items: courierdata.map((c) {
                            final id = c['id'].toString();
                            final name = c['name'] ?? '';
                            return DropdownMenuItem<String>(
                              value: id, // ✅ value is the UNIQUE id
                              child: Text(name,
                                  style: const TextStyle(fontSize: 15)),
                            );
                          }).toList(),

                          onChanged: (id) {
                            setState(() {
                              selectedCourierId = id; // ✅ store id
                            });
                            applyFilters2(); // or whatever filtering you need
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final warehouseList =
                            order['warehouse_data'] as List<dynamic>?;

                        final filteredParcels = warehouseList != null
                            ? warehouseList
                                .where((parcel) =>
                                    parcel['tracking_id'] != 0 &&
                                    parcel['tracking_id']
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                .toList()
                            : [];

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Invoice and Total
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("🧾 ${order['invoice'] ?? 'N/A'}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        "₹ ${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 0, 36, 1)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Customer name
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "👤 ${order['customerName'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        " ${order['box'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${order['tracking_id'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${order['parcel_service'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Parcel amount:${order['parcel_amount'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            "A/W : ${order['actual_weight']?.toStringAsFixed(2)} KG")),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${order['weight'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
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
