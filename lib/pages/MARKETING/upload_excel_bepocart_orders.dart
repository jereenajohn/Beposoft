import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/api.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderBulkUploadexcel extends StatefulWidget {
  const OrderBulkUploadexcel({super.key});

  @override
  State<OrderBulkUploadexcel> createState() => _OrderBulkUploadexcelState();
}

class _OrderBulkUploadexcelState extends State<OrderBulkUploadexcel> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> successLogs = [];
  List<Map<String, dynamic>> failureLogs = [];
  List<String> failedStockProducts = [];

  bool isLoading = false;
  String loadingText = "Processing orders...";
  String searchTerm = "";

  @override
  void initState() {
    super.initState();
    fetchStates();
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String cleanPhone(dynamic phone) {
    var value = phone?.toString().trim() ?? "";

    if (value.startsWith("+91")) {
      value = value.substring(3);
    } else if (value.startsWith("91") && value.length > 10) {
      value = value.substring(2);
    }

    value = value.replaceAll(RegExp(r'\D'), '');

    if (value.length > 10) {
      value = value.substring(value.length - 10);
    }

    return value;
  }

  int getStateId(dynamic provinceName) {
    final province = provinceName?.toString().trim().toLowerCase() ?? "";

    if (province.isEmpty) return 14;

    for (final state in states) {
      final name = state["name"]?.toString().trim().toLowerCase() ?? "";
      final provinceValue =
          state["province"]?.toString().trim().toLowerCase() ?? "";

      if (name == province || provinceValue == province) {
        final id = state["id"];
        return id is int ? id : int.tryParse(id.toString()) ?? 14;
      }
    }

    return 14;
  }

  dynamic getValue(
    Map<String, dynamic> row,
    List<String> keys, [
    dynamic defaultValue = "",
  ]) {
    for (final key in keys) {
      if (row.containsKey(key) &&
          row[key] != null &&
          row[key].toString().trim().isNotEmpty) {
        return row[key];
      }
    }

    return defaultValue;
  }

  String extractApiError(dynamic error) {
    try {
      if (error is http.Response) {
        final data = jsonDecode(error.body);

        if (data is Map<String, dynamic>) {
          return data.entries.map((entry) {
            final value = entry.value;

            if (value is List) {
              return "${entry.key}: ${value.join(', ')}";
            }

            if (value is Map) {
              return "${entry.key}: ${jsonEncode(value)}";
            }

            return "${entry.key}: $value";
          }).join(" | ");
        }

        return error.body;
      }

      if (error is Map || error is List) {
        return jsonEncode(error);
      }

      return error.toString();
    } catch (_) {
      return error.toString();
    }
  }

  Map<String, dynamic> getOrderDetails(Map<String, dynamic> order) {
    final usedAddress = order["shippingAddress"] ?? order["billingAddress"];

    return {
      "orderName": order["name"] ?? "Unknown",
      "orderId": order["id"] ?? "N/A",
      "customerName":
          "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                  .trim()
                  .isNotEmpty
              ? "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                  .trim()
              : "Unknown Customer",
      "phone": cleanPhone(usedAddress?["phone"] ?? order["customer"]?["phone"]),
      "email": order["customer"]?["email"] ?? "N/A",
      "amount": order["totalPriceSet"]?["shopMoney"]?["amount"] ?? "0",
      "paymentStatus": order["displayFinancialStatus"] ?? "N/A",
      "paymentMethod": order["paymentGatewayNames"] is List &&
              order["paymentGatewayNames"].isNotEmpty
          ? order["paymentGatewayNames"][0]
          : "N/A",
      "address": "${usedAddress?["address1"] ?? ""}, ${usedAddress?["address2"] ?? ""}",
      "city": usedAddress?["city"] ?? "N/A",
      "state": usedAddress?["province"] ?? "N/A",
      "products": ((order["lineItems"]?["edges"] ?? []) as List).map((item) {
        return {
          "title": item["node"]?["title"] ?? "Unknown Product",
          "sku": item["node"]?["variant"]?["sku"] ?? "No SKU",
          "quantity": item["node"]?["quantity"] ?? 0,
        };
      }).toList(),
    };
  }

  void addSuccessLog(
    Map<String, dynamic> order,
    String message,
    Map<String, dynamic> extra,
  ) {
    setState(() {
      successLogs.add({
        ...getOrderDetails(order),
        "message": message,
        ...extra,
      });
    });
  }

  void addFailureLog(
    Map<String, dynamic> order,
    String reason,
    String step, [
    dynamic error,
    dynamic statusCode,
  ]) {
    setState(() {
      failureLogs.add({
        ...getOrderDetails(order),
        "reason": reason,
        "step": step,
        "backendError": error == null ? "No backend error response" : extractApiError(error),
        "statusCode": statusCode ?? "N/A",
      });
    });
  }

  String mapPaymentStatus(dynamic status) {
    if (status == null) return "PENDING";

    final value = status.toString().toUpperCase();

    switch (value) {
      case "PAID":
        return "paid";
      case "PENDING":
      case "COD":
        return "COD";
      case "VOIDED":
        return "VOIDED";
      default:
        return "PENDING";
    }
  }

  Future<void> fetchStates() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data["data"] ?? [];

        setState(() {
          states = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("fetchStates error: $e");
    }
  }

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      final token = await gettokenFromPrefs();
      final cleanedPhone = cleanPhone(phone);

      final uri = Uri.parse('$api/api/customers/').replace(
        queryParameters: {
          "search": cleanedPhone,
          "page": "1",
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final List results = data["results"] ?? [];

      for (final item in results) {
        if (cleanPhone(item["phone"]) == cleanedPhone) {
          return Map<String, dynamic>.from(item);
        }
      }

      return null;
    } catch (e) {
      debugPrint("getCustomerByPhone error: $e");
      return null;
    }
  }

  Future<int?> orderAlreadyExists(Map<String, dynamic> order) async {
    try {
      final token = await gettokenFromPrefs();

      final excelOrderId = order["id"]?.toString();
      if (excelOrderId == null || excelOrderId.isEmpty) return null;

      final orderName = order["name"]?.toString() ?? "";
      final customerName =
          "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
              .trim();

      final searchValue =
          customerName.isNotEmpty ? customerName : orderName.replaceAll("#", "");

      final uri = Uri.parse('$api/api/orders/all/').replace(
        queryParameters: searchValue.isNotEmpty ? {"search": searchValue} : {},
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      List orders = [];

      if (data is List) {
        orders = data;
      } else if (data is Map && data["data"] is List) {
        orders = data["data"];
      } else if (data is Map && data["results"] is List) {
        orders = data["results"];
      } else if (data is Map &&
          data["results"] is Map &&
          data["results"]["results"] is List) {
        orders = data["results"]["results"];
      }

      for (final ord in orders) {
        final existingExcelId = ord["shopify_order_id"]?.toString();

        if (existingExcelId != null && existingExcelId == excelOrderId) {
          final id = ord["id"];
          return id is int ? id : int.tryParse(id.toString());
        }
      }

      return null;
    } catch (e) {
      debugPrint("orderAlreadyExists error: $e");
      return null;
    }
  }

  List<Map<String, dynamic>> convertRowsToOrders(
    List<Map<String, dynamic>> rows,
  ) {
    final Map<String, Map<String, dynamic>> groupedOrders = {};

    for (int index = 0; index < rows.length; index++) {
      final row = rows[index];

      final orderName = getValue(
        row,
        ["Name", "Order Name", "Order", "Invoice", "Order No"],
        "EXCEL-${index + 1}",
      ).toString();

      final orderId = getValue(
        row,
        ["Id", "ID", "Order ID", "Order Id"],
        orderName,
      ).toString();

      final phone = getValue(row, [
        "Phone",
        "phone",
        "Shipping Phone",
        "Billing Phone",
        "Customer Phone",
      ]).toString();

      final customerName = getValue(row, [
        "Shipping Name",
        "Billing Name",
        "Customer Name",
        "Name",
      ]).toString();

      final email = getValue(row, ["Email", "Customer Email", "email"]).toString();

      final lineItemPrice = double.tryParse(
            getValue(row, ["Lineitem price", "Price", "Rate"], "0").toString(),
          ) ??
          0;

      final quantity = int.tryParse(
            getValue(row, ["Lineitem quantity", "Quantity", "Qty"], "0")
                .toString(),
          ) ??
          0;

      final shippingCharge = double.tryParse(
            getValue(row, ["Shipping", "Shipping Charge", "shipping_charge"], "0")
                .toString(),
          ) ??
          0;

      final paymentStatus = getValue(
        row,
        ["Financial Status", "Payment Status", "payment_status"],
        "PENDING",
      ).toString();

      final paymentMethod = getValue(
        row,
        ["Payment Method", "Payment Gateway", "Gateway"],
        "N/A",
      ).toString();

      groupedOrders.putIfAbsent(orderName, () {
        return {
          "id": orderId,
          "name": orderName,
          "email": email,
          "shippingCharge": shippingCharge,
          "createdAt": getValue(
            row,
            ["Created at", "Order Date", "Date"],
            DateTime.now().toIso8601String(),
          ).toString(),
          "displayFinancialStatus": paymentStatus,
          "paymentGatewayNames": [paymentMethod],
          "productErrors": <String>[],
          "totalPriceSet": {
            "shopMoney": {
              "amount": "0",
              "currencyCode": getValue(row, ["Currency"], "INR").toString(),
            },
          },
          "customer": {
            "id": "",
            "firstName": "",
            "lastName":
                customerName.trim().isNotEmpty ? customerName : "Unknown Customer",
            "email": email,
            "phone": phone,
            "defaultAddress": {
              "address1": getValue(row, [
                "Shipping Address1",
                "Shipping Street",
                "Address",
              ]).toString(),
              "address2": getValue(row, ["Shipping Address2"]).toString(),
              "city": getValue(row, ["Shipping City", "City"]).toString(),
              "province": getValue(row, [
                "Shipping Province Name",
                "Shipping Province",
                "State",
              ]).toString(),
              "country": getValue(row, ["Shipping Country", "Country"]).toString(),
              "zip": getValue(row, ["Shipping Zip", "Zip", "Pincode"]).toString(),
            },
          },
          "shippingAddress": {
            "address1": getValue(row, [
              "Shipping Address1",
              "Shipping Street",
              "Address",
            ]).toString(),
            "address2": getValue(row, ["Shipping Address2"]).toString(),
            "city": getValue(row, ["Shipping City", "City"]).toString(),
            "province": getValue(row, [
              "Shipping Province Name",
              "Shipping Province",
              "State",
            ]).toString(),
            "country": getValue(row, ["Shipping Country", "Country"]).toString(),
            "zip": getValue(row, ["Shipping Zip", "Zip", "Pincode"]).toString(),
            "phone": phone,
          },
          "billingAddress": {
            "address1": getValue(row, [
              "Billing Address1",
              "Billing Street",
              "Address",
            ]).toString(),
            "address2": getValue(row, ["Billing Address2"]).toString(),
            "city": getValue(row, ["Billing City", "City"]).toString(),
            "province": getValue(row, [
              "Billing Province Name",
              "Billing Province",
              "State",
            ]).toString(),
            "country": getValue(row, ["Billing Country", "Country"]).toString(),
            "zip": getValue(row, ["Billing Zip", "Zip", "Pincode"]).toString(),
            "phone": phone,
          },
          "lineItems": {
            "edges": <Map<String, dynamic>>[],
          },
        };
      });

      final sku = getValue(row, [
        "Lineitem sku",
        "SKU",
        "Sku",
        "Product SKU",
        "Product Code",
      ]).toString();

      final title = getValue(row, [
        "Lineitem name",
        "Product Name",
        "Product",
        "Item Name",
      ]).toString();

      if (sku.trim().isEmpty) {
        groupedOrders[orderName]!["productErrors"].add(
          "${title.trim().isNotEmpty ? title : 'Unknown Product'} has no SKU in Excel file",
        );
        continue;
      }

      if (quantity <= 0) {
        groupedOrders[orderName]!["productErrors"].add(
          "${title.trim().isNotEmpty ? title : 'Unknown Product'} has invalid quantity in Excel file",
        );
        continue;
      }

      final currentAmount = double.tryParse(
            groupedOrders[orderName]!["totalPriceSet"]["shopMoney"]["amount"]
                .toString(),
          ) ??
          0;

      groupedOrders[orderName]!["totalPriceSet"]["shopMoney"]["amount"] =
          (currentAmount + (lineItemPrice * quantity)).toStringAsFixed(2);

      groupedOrders[orderName]!["lineItems"]["edges"].add({
        "node": {
          "title": title.trim().isNotEmpty ? title : "Unknown Product",
          "quantity": quantity,
          "variant": {
            "id": "",
            "title": title,
            "price": lineItemPrice.toString(),
            "sku": sku,
            "product": {
              "id": "",
              "title": title,
              "vendor": "",
              "productType": "",
            },
          },
        },
      });
    }

    return groupedOrders.values.toList();
  }

  Future<void> pickExcelCsvAndProcessOrders() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["xlsx", "xls", "csv"],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      isLoading = true;
      loadingText = "Reading Excel/CSV file...";
      successLogs.clear();
      failureLogs.clear();
      failedStockProducts.clear();
      searchTerm = "";
    });

    try {
      final file = File(result.files.single.path!);
      final fileName = file.path.toLowerCase();

      List<Map<String, dynamic>> rows = [];

      if (fileName.endsWith(".csv")) {
        final csvString = await file.readAsString();
        final csvRows = const CsvToListConverter().convert(csvString);

        if (csvRows.isEmpty) {
          throw Exception("No rows found in uploaded CSV file");
        }

        final headers = csvRows.first.map((e) => e.toString().trim()).toList();

        for (int i = 1; i < csvRows.length; i++) {
          final row = csvRows[i];
          final map = <String, dynamic>{};

          for (int j = 0; j < headers.length; j++) {
            map[headers[j]] = j < row.length ? row[j] : "";
          }

          rows.add(map);
        }
      } else {
        final bytes = await file.readAsBytes();
        final excel = excel_pkg.Excel.decodeBytes(bytes);

        if (excel.tables.isEmpty) {
          throw Exception("Excel file is empty or contains no sheets");
        }

        final sheet = excel.tables.values.first;
        final rawRows = sheet.rows;

        if (rawRows.isEmpty) {
          throw Exception("No rows found in uploaded Excel file");
        }

        final headers = rawRows.first
            .map((cell) => cell?.value?.toString().trim() ?? "")
            .toList();

        for (int i = 1; i < rawRows.length; i++) {
          final row = rawRows[i];
          final map = <String, dynamic>{};

          for (int j = 0; j < headers.length; j++) {
            map[headers[j]] = j < row.length
                ? row[j]?.value?.toString().trim() ?? ""
                : "";
          }

          rows.add(map);
        }
      }

      rows = rows.where((row) {
        return row.values.any((value) => value.toString().trim().isNotEmpty);
      }).toList();

      if (rows.isEmpty) {
        throw Exception("No valid rows found in uploaded file");
      }

      final orders = convertRowsToOrders(rows);

      if (orders.isEmpty) {
        throw Exception("No valid orders found in uploaded file");
      }

      setState(() {
        loadingText = "Processing uploaded orders...";
      });

      await compareCustomers(orders);
    } catch (e) {
      addFailureLog(
        {
          "name": "Upload Failed",
          "id": "N/A",
          "customer": {},
          "shippingAddress": {},
          "billingAddress": {},
          "lineItems": {"edges": []},
          "totalPriceSet": {
            "shopMoney": {"amount": "0"}
          },
        },
        e.toString(),
        "File Processing",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> compareCustomers(List<Map<String, dynamic>> allOrders) async {
    for (final order in allOrders) {
      if (order["displayFinancialStatus"]?.toString().toUpperCase() == "VOIDED") {
        addFailureLog(order, "VOIDED order skipped", "Payment status check");
        continue;
      }

      final existingOrderId = await orderAlreadyExists(order);

      if (existingOrderId != null) {
        addFailureLog(
          order,
          "Already Created. Backend Order ID: $existingOrderId",
          "Duplicate order check",
        );
        continue;
      }

      final orderPhone = order["shippingAddress"]?["phone"] ??
          order["billingAddress"]?["phone"] ??
          order["customer"]?["phone"];

      if (orderPhone == null || orderPhone.toString().trim().isEmpty) {
        addFailureLog(order, "No phone number found", "Phone validation");
        continue;
      }

      final normalizedOrderPhone = cleanPhone(orderPhone);
      final usedAddress = order["shippingAddress"] ?? order["billingAddress"];

      if (usedAddress == null) {
        addFailureLog(
          order,
          "No shipping or billing address found",
          "Address validation",
        );
        continue;
      }

      try {
        final existingCustomer = await getCustomerByPhone(normalizedOrderPhone);

        int? customerId;

        if (existingCustomer != null && existingCustomer["id"] != null) {
          customerId = existingCustomer["id"] is int
              ? existingCustomer["id"]
              : int.tryParse(existingCustomer["id"].toString());
        } else {
          customerId = await addCustomer(
            order: order,
            name:
                "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                        .trim()
                        .isNotEmpty
                    ? "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                        .trim()
                    : "Unknown Customer",
            phone: normalizedOrderPhone,
            email: order["customer"]?["email"] ?? "",
            address:
                "${usedAddress["address1"] ?? ""}, ${usedAddress["address2"] ?? ""}",
            city: usedAddress["city"] ?? "",
            state: usedAddress["province"] ?? "",
            zipcode: usedAddress["zip"] ?? "",
          );
        }

        if (customerId == null) continue;

        final addressId = await addAddress(
          customerId: customerId,
          order: order,
          name:
              "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                      .trim()
                      .isNotEmpty
                  ? "${order["customer"]?["firstName"] ?? ""} ${order["customer"]?["lastName"] ?? ""}"
                      .trim()
                  : "Unknown Customer",
          phone: usedAddress["phone"] ?? normalizedOrderPhone,
          email: order["customer"]?["email"] ?? "",
          address:
              "${usedAddress["address1"] ?? ""}, ${usedAddress["address2"] ?? ""}",
          city: usedAddress["city"] ?? "",
          state: usedAddress["province"] ?? "",
          zipcode: usedAddress["zip"] ?? "",
          country: usedAddress["country"] ?? "",
        );

        if (addressId == null) continue;

        final shippingStateId = getStateId(usedAddress["province"]);
        final cartSuccess = await addToCart(order);

        if (!cartSuccess) continue;

        await createOrder(
          order: order,
          customerId: customerId,
          addressId: addressId,
          shippingStateId: shippingStateId,
          customerType:
              existingCustomer != null ? "Existing customer" : "New customer",
        );
      } catch (e) {
        addFailureLog(order, "Failed due to exception", "Processing", e);
        await deleteCartItems();
      }
    }
  }

  Future<int?> addCustomer({
    required Map<String, dynamic> order,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String zipcode,
  }) async {
    try {
      final token = await gettokenFromPrefs();
      final stateId = getStateId(state);

      final body = {
        "name": name.isNotEmpty ? name : "Unknown Customer",
        "manager": 103,
        "state": stateId,
        "phone": cleanPhone(phone),
        "alt_phone": "",
        "email": email.isNotEmpty ? email : "no-email@example.com",
        "address": address,
        "zip_code": zipcode,
        "city": city,
        "comment": "Auto-created from Excel order",
      };

      final response = await http.post(
        Uri.parse('$api/api/add/customer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final id = data["data"]?["id"];
        return id is int ? id : int.tryParse(id.toString());
      }

      addFailureLog(
        order,
        "Customer creation failed",
        "Add Customer API",
        response,
        response.statusCode,
      );

      return null;
    } catch (e) {
      addFailureLog(order, "Customer creation failed", "Add Customer API", e);
      return null;
    }
  }

  Future<int?> addAddress({
    required int customerId,
    required Map<String, dynamic> order,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String zipcode,
    required String country,
  }) async {
    try {
      final token = await gettokenFromPrefs();
      final stateId = getStateId(state);

      final body = {
        "customer": customerId,
        "name": name,
        "address": address,
        "zipcode": zipcode,
        "city": city,
        "state": stateId,
        "country": country,
        "phone": cleanPhone(phone).isNotEmpty ? cleanPhone(phone) : "0000000000",
        "email": email,
      };

      final response = await http.post(
        Uri.parse('$api/api/add/customer/address/$customerId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final id = data["data"]?["id"];
        return id is int ? id : int.tryParse(id.toString());
      }

      addFailureLog(
        order,
        "Address creation failed",
        "Add Address API",
        response,
        response.statusCode,
      );

      return null;
    } catch (e) {
      addFailureLog(order, "Address creation failed", "Add Address API", e);
      return null;
    }
  }

  Future<bool> addToCart(Map<String, dynamic> order) async {
    try {
      final token = await gettokenFromPrefs();
      final List itemsList = order["lineItems"]?["edges"] ?? [];

      if (itemsList.isEmpty) {
        final productErrors = order["productErrors"] as List? ?? [];

        addFailureLog(
          order,
          productErrors.isNotEmpty
              ? productErrors.join(", ")
              : "No valid products found. Check SKU and quantity in Excel file.",
          "Excel product validation",
        );

        return false;
      }

      for (final item in itemsList) {
        final node = item["node"];
        final productSku = node?["variant"]?["sku"];
        final quantity = node?["quantity"];
        final productTitle = node?["title"] ?? "";
        final excelPrice = node?["variant"]?["price"] ?? "0";

        if (productSku == null ||
            productSku.toString().trim().isEmpty ||
            quantity == null) {
          addFailureLog(
            order,
            "Invalid product data. SKU: ${productSku ?? 'Missing'}, Qty: ${quantity ?? 'Missing'}",
            "Product validation",
          );
          return false;
        }

        final response = await http.post(
          Uri.parse('$api/api/cart/product/excel/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "product": productSku.toString().trim(),
            "quantity": quantity,
            "price": excelPrice.toString(),
          }),
        );

        if (response.statusCode != 201) {
          await deleteCartItems();

          addFailureLog(
            order,
            "Failed to add SKU $productSku ($productTitle) to cart",
            "Cart API",
            response,
            response.statusCode,
          );

          return false;
        }
      }

      return true;
    } catch (e) {
      await deleteCartItems();
      addFailureLog(order, "Product add to cart failed", "Cart API", e);
      return false;
    }
  }

  Future<void> createOrder({
    required Map<String, dynamic> order,
    required int customerId,
    required int addressId,
    required int shippingStateId,
    required String customerType,
  }) async {
    try {
      final token = await gettokenFromPrefs();

      final productAmount = double.tryParse(
            order["totalPriceSet"]?["shopMoney"]?["amount"]?.toString() ?? "0",
          ) ??
          0;

      final shippingCharge =
          double.tryParse(order["shippingCharge"]?.toString() ?? "0") ?? 0;

      final totalAmount = productAmount + shippingCharge;

      final paymentMethod = order["paymentGatewayNames"] is List &&
              order["paymentGatewayNames"].isNotEmpty
          ? order["paymentGatewayNames"][0].toString()
          : "N/A";

      final today = DateTime.now().toIso8601String().split("T")[0];

      final body = {
        "manage_staff": 103,
        "company": 5,
        "customer": customerId,
        "billing_address": addressId,
        "order_date": today,
        "family": 3,
        "state": shippingStateId,
        "payment_status": mapPaymentStatus(order["displayFinancialStatus"]),
        "total_amount": totalAmount.toString(),
        "shipping_charge": shippingCharge.toString(),
        "bank": 8,
        "payment_method": paymentMethod,
        "warehouses": 1,
        "status": "Invoice Created",
        "shopify_order_id": order["id"],
      };

      final response = await http.post(
        Uri.parse('$api/api/order/create/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data["data"]?["id"];

        addSuccessLog(order, "Order created successfully", {
          "backendOrderId": orderId,
          "customerId": customerId,
          "addressId": addressId,
          "shippingStateId": shippingStateId,
          "customerType": customerType,
          "shippingCharge": shippingCharge,
          "finalAmount": totalAmount,
        });

        await updateAmount(order, orderId);
        await deleteCartItems();

        return;
      }

      final errorText = response.body;

      if (errorText.contains("Not enough available stock")) {
        final List itemsList = order["lineItems"]?["edges"] ?? [];

        for (final item in itemsList) {
          final sku = item["node"]?["variant"]?["sku"];
          final title = item["node"]?["title"];
          final qty = item["node"]?["quantity"];

          failedStockProducts.add(
            "[${order["name"]}] SKU $sku – $title (Qty $qty) → STOCK NOT AVAILABLE",
          );
        }

        setState(() {});
      }

      addFailureLog(
        order,
        "Order creation failed",
        "Create Order API",
        response,
        response.statusCode,
      );

      await deleteCartItems();
    } catch (e) {
      final errorText = e.toString();

      if (errorText.contains("Not enough available stock")) {
        final List itemsList = order["lineItems"]?["edges"] ?? [];

        for (final item in itemsList) {
          final sku = item["node"]?["variant"]?["sku"];
          final title = item["node"]?["title"];
          final qty = item["node"]?["quantity"];

          failedStockProducts.add(
            "[${order["name"]}] SKU $sku – $title (Qty $qty) → STOCK NOT AVAILABLE",
          );
        }

        setState(() {});
      }

      addFailureLog(order, "Order creation failed", "Create Order API", e);
      await deleteCartItems();
    }
  }

  Future<void> updateAmount(Map<String, dynamic> order, dynamic orderId) async {
    if (orderId == null) return;

    try {
      final token = await gettokenFromPrefs();

      final productAmount = double.tryParse(
            order["totalPriceSet"]?["shopMoney"]?["amount"]?.toString() ?? "0",
          ) ??
          0;

      final shippingCharge =
          double.tryParse(order["shippingCharge"]?.toString() ?? "0") ?? 0;

      final totalAmount = (productAmount + shippingCharge).toStringAsFixed(2);

      final response = await http.put(
        Uri.parse('$api/api/shipping/$orderId/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "total_amount": totalAmount,
        }),
      );

      if (response.statusCode != 200) {
        addFailureLog(
          order,
          "Amount update failed",
          "Update Amount API",
          response,
          response.statusCode,
        );
      }
    } catch (e) {
      addFailureLog(order, "Amount update failed", "Update Amount API", e);
    }
  }

  Future<bool> deleteCartItems() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.delete(
        Uri.parse('$api/api/cart/delete/all/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("deleteCartItems error: $e");
      return false;
    }
  }

  List<Map<String, dynamic>> get filteredSuccessLogs {
    final query = searchTerm.toLowerCase();

    return successLogs.where((item) {
      return item["orderName"].toString().toLowerCase().contains(query) ||
          item["customerName"].toString().toLowerCase().contains(query) ||
          item["phone"].toString().toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredFailureLogs {
    final query = searchTerm.toLowerCase();

    return failureLogs.where((item) {
      return item["orderName"].toString().toLowerCase().contains(query) ||
          item["customerName"].toString().toLowerCase().contains(query) ||
          item["phone"].toString().toLowerCase().contains(query) ||
          item["reason"].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Bulk Order Creation",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.8,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildSummaryGrid(),
            const SizedBox(height: 16),
            _buildUploadSearchCard(),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingCard()
            else ...[
              if (filteredFailureLogs.isNotEmpty)
                _buildOrderTable(
                  title: "Failed Orders",
                  subtitle:
                      "These orders were not created. Check the highlighted reason column.",
                  logs: filteredFailureLogs,
                  isFailed: true,
                ),
              if (filteredSuccessLogs.isNotEmpty)
                _buildOrderTable(
                  title: "Success Orders",
                  subtitle: "These orders were created successfully in backend.",
                  logs: filteredSuccessLogs,
                  isFailed: false,
                ),
              if (successLogs.isEmpty && failureLogs.isEmpty) _buildEmptyCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F2937),
            Color(0xFF334155),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.upload_file_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 14),
          const Text(
            "Bulk Order Creation",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload Excel or CSV file, validate products, create customers, addresses, and backend orders.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderBadge("Success: ${successLogs.length}", Colors.green),
              _buildHeaderBadge("Failed: ${failureLogs.length}", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == Colors.green
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.75,
      children: [
        _buildSummaryCard(
          title: "Total Processed",
          value: successLogs.length + failureLogs.length,
          icon: Icons.list_alt_rounded,
          bg: const Color(0xFFEEF2FF),
          color: const Color(0xFF4F46E5),
        ),
        _buildSummaryCard(
          title: "Success Orders",
          value: successLogs.length,
          icon: Icons.check_circle_rounded,
          bg: const Color(0xFFECFDF5),
          color: const Color(0xFF10B981),
        ),
        _buildSummaryCard(
          title: "Failed Orders",
          value: failureLogs.length,
          icon: Icons.error_rounded,
          bg: const Color(0xFFFEE2E2),
          color: const Color(0xFFDC2626),
        ),
        _buildSummaryCard(
          title: "Stock Issues",
          value: failedStockProducts.length,
          icon: Icons.inventory_2_rounded,
          bg: const Color(0xFFFFF7ED),
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color bg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSearchCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upload Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Required columns: Name, Phone, Customer Name, Address, City, State, SKU, Quantity, Total",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : pickExcelCsvAndProcessOrders,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text(
                      "Upload Excel / CSV",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEDF0F4)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchTerm = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search order, customer, phone or reason...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: Color(0xFF64748B),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "No orders uploaded yet",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload an Excel or CSV file to start bulk order creation.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTable({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> logs,
    required bool isFailed,
  }) {
    final color = isFailed ? const Color(0xFFDC2626) : const Color(0xFF15803D);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$title: ${logs.length}",
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFEDF0F4)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 22,
              dataRowMinHeight: 78,
              dataRowMaxHeight: 210,
              columns: [
                _tableColumn("#"),
                _tableColumn("Order"),
                _tableColumn("Customer"),
                _tableColumn("Amount"),
                _tableColumn("Products"),
                if (isFailed) _tableColumn("Failed Step"),
                if (isFailed) _tableColumn("Highlighted Reason"),
                if (!isFailed) _tableColumn("Status"),
                if (!isFailed) _tableColumn("Backend ID"),
              ],
              rows: logs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;

                return DataRow(
                  color: WidgetStateProperty.all(
                    isFailed ? const Color(0xFFFFFAFA) : Colors.white,
                  ),
                  cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(_orderCell(log)),
                    DataCell(_customerCell(log)),
                    DataCell(_amountCell(log["amount"])),
                    DataCell(_productsCell(log["products"] ?? [])),
                    if (isFailed) DataCell(_failedStepCell(log["step"])),
                    if (isFailed) DataCell(_reasonCell(log)),
                    if (!isFailed) DataCell(_successStatusCell()),
                    if (!isFailed) DataCell(_backendCell(log)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _tableColumn(String text) {
    return DataColumn(
      label: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _orderCell(Map<String, dynamic> log) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            log["orderName"].toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Excel ID: ${log["orderId"]}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text(
            "Payment: ${log["paymentMethod"]}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _customerCell(Map<String, dynamic> log) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            log["customerName"].toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Phone: ${log["phone"]}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text(
            "City: ${log["city"]}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text(
            "State: ${log["state"]}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _amountCell(dynamic amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "₹$amount",
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _productsCell(dynamic products) {
    final List list = products is List ? products : [];

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          "No products",
          style: TextStyle(
            color: Color(0xFFB91C1C),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return SizedBox(
      width: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: list.map((product) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["title"].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "SKU: ${product["sku"]} | Qty: ${product["quantity"]}",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _failedStepCell(dynamic step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        step.toString(),
        style: const TextStyle(
          color: Color(0xFFC2410C),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _reasonCell(Map<String, dynamic> log) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: const Text(
              "REASON",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              log["reason"].toString(),
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFFECACA))),
            ),
            child: Text(
              "Status Code: ${log["statusCode"]}",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successStatusCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 16),
          SizedBox(width: 4),
          Text(
            "Created",
            style: TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backendCell(Map<String, dynamic> log) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${log["backendOrderId"] ?? "N/A"}",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Customer ID: ${log["customerId"] ?? "N/A"}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}