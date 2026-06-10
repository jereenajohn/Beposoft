import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/secret_config.dart';

class OrderBulkUpload extends StatefulWidget {
  const OrderBulkUpload({super.key});

  @override
  State<OrderBulkUpload> createState() => _OrderBulkUploadState();
}

class _OrderBulkUploadState extends State<OrderBulkUpload> {
  // ===================== STATE FIELDS =====================
  List<String> failedOrders = [];
  List<String> failedcustomer = [];
  List<String> successorders = [];
  List<String> successCustomers = [];
  List<String> failedStockProducts = [];
  List<String> missingSkuProducts = [];

  bool isLoading = false;
  String loadingText = "Processing orders...";
  double progress = 0.0;

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> stat = [];

  // Per-order context
  int? customerId;
  int? addressId;
  int? shippingstateId;
  bool allAdded = true;

  // ===================== SHOPIFY CONFIG =====================
  final String shopifyEndpoint =
      'https://ekve0y-1k.myshopify.com/admin/api/2025-01/graphql.json';
  final String accessToken = SecretConfig.shopifyAccessToken;
  @override
  void initState() {
    super.initState();
    initdata();
  }

  void initdata() async {
    await getstate();
  }

  // ===================== HELPERS =====================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('token');
    print("🔹 gettokenFromPrefs() → token present: ${t != null}");
    return t;
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('department');
    print("🔹 getdepFromPrefs() → department: $d");
    return d;
  }

  /// Normalize phone number to last 10 digits Indian mobile style
  String cleanPhone(String phone) {
    String original = phone;
    phone = phone.trim();
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(2);
    }
    phone = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.length > 10) {
      phone = phone.substring(phone.length - 10);
    }
    print("📞 cleanPhone(): '$original' → '$phone'");
    return phone;
  }

  /// Reset per-order context so each order starts clean
  void resetOrderContext() {
    customerId = null;
    addressId = null;
    shippingstateId = null;
    allAdded = true;
    print(
        "🔄 resetOrderContext() → customerId=null, addressId=null, shippingstateId=null, allAdded=true");
  }

  // ===================== FETCH STATES =====================
  Future<void> getstate() async {
    print("\n🌍 getstate() → Fetching /api/states/");
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🌍 /api/states/ → status: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("🌍 /api/states/ body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> statelist = [];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          stat = statelist;
        });
        print("🌍 States loaded: ${stat.length}");
      }
    } catch (error) {
      print("❌ getstate() error: $error");
    }
  }

  // ===================== FETCH CUSTOMERS (LOCAL) =====================
  Future<void> getcustomer() async {
    await fetchLatest300Orders();
  }

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      final token = await gettokenFromPrefs();
      final cleanedPhone = cleanPhone(phone);

      final uri = Uri.parse('$api/api/customers/').replace(
        queryParameters: {
          'search': cleanedPhone,
          'page': '1',
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

      final parsed = jsonDecode(response.body);

      final List<dynamic> results =
          parsed is Map<String, dynamic> && parsed['results'] is List
              ? parsed['results']
              : [];

      for (var item in results) {
        final apiPhone = cleanPhone(item['phone']?.toString() ?? '');

        if (apiPhone == cleanedPhone) {
          return Map<String, dynamic>.from(item);
        }
      }

      return null;
    } catch (e) {
      print("❌ getCustomerByPhone() error: $e");
      return null;
    }
  }

  Future<int?> orderAlreadyExists(Map<String, dynamic> shopOrder) async {
    try {
      final token = await gettokenFromPrefs();

      if (token == null) {
        print("❌ orderAlreadyExists(): token is null");
        return null;
      }

      final shopifyId = shopOrder["id"]?.toString();

      if (shopifyId == null || shopifyId.isEmpty) {
        print("❌ orderAlreadyExists(): Shopify order id missing");
        return null;
      }

      final orderName = shopOrder["name"]?.toString() ?? '';
      final customerName =
          "${shopOrder['customer']?['firstName'] ?? ''} ${shopOrder['customer']?['lastName'] ?? ''}"
              .trim();

      final searchValue = customerName.isNotEmpty
          ? customerName
          : orderName.replaceAll('#', '');

      final uri = Uri.parse('$api/api/orders/all/').replace(
        queryParameters: searchValue.isNotEmpty
            ? {
                'search': searchValue,
              }
            : null,
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("🔎 /api/orders/all/ status: ${response.statusCode}");
      print("🔎 /api/orders/all/ body: ${response.body}");

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      final List<dynamic> orders = data is List
          ? data
          : data is Map<String, dynamic> && data["data"] is List
              ? data["data"]
              : data is Map<String, dynamic> && data["results"] is List
                  ? data["results"]
                  : data is Map<String, dynamic> &&
                          data["results"] is Map &&
                          data["results"]["results"] is List
                      ? data["results"]["results"]
                      : [];

      for (var ord in orders) {
        final existingShopifyId = ord["shopify_order_id"]?.toString();

        if (existingShopifyId != null &&
            existingShopifyId.isNotEmpty &&
            existingShopifyId == shopifyId) {
          return ord["id"] is int
              ? ord["id"]
              : int.tryParse(ord["id"].toString());
        }
      }

      return null;
    } catch (e) {
      print("❌ orderAlreadyExists() error: $e");
      return null;
    }
  }

  String mapPaymentStatus(String? status) {
    if (status == null) return "PENDING";

    status = status.toUpperCase();

    switch (status) {
      case "PAID":
        return "paid"; // Django expects lowercase

      case "PENDING":
        return "COD"; // For COD

      case "VOIDED":
        return "VOIDED";

      default:
        return "PENDING"; // Safe fallback
    }
  }

  // ===================== FETCH LATEST ORDERS FROM SHOPIFY =====================
  Future<List<Map<String, dynamic>>> fetchLatest300Orders() async {
    const ordersQuery = '''
    query getOrdersWithAllLineItems(\$first: Int!) {
      orders(first: \$first, sortKey: CREATED_AT, reverse: true) {
        edges {
          node {
            id
            name
            email
            createdAt
            displayFinancialStatus
            paymentGatewayNames
            totalPriceSet {
              shopMoney {
                amount
                currencyCode
              }
            }
            customer {
              id
              firstName
              lastName
              email
              phone
              defaultAddress {
                address1
                address2
                city
                province
                country
                zip
              }
            }
            lineItems(first: 10) {
              edges {
                node {
                  title
                  quantity
                  variant {
                    id
                    title
                    price
                    sku
                    product {
                      id
                      title
                      vendor
                      productType
                    }
                  }
                  discountedTotalSet {
                    shopMoney {
                      amount
                      currencyCode
                    }
                  }
                }
              }
            }
            billingAddress {
              address1
              address2
              city
              province
              country
              zip
              phone
            }
            shippingAddress {
              address1
              address2
              city
              province
              country
              zip
              phone
            }
            fulfillments {
              id
              status
              trackingInfo {
                number
                url
              }
            }
            discountApplications(first: 10) {
              edges {
                node {
                  allocationMethod
                  targetType
                  value {
                    ... on MoneyV2 {
                      amount
                      currencyCode
                    }
                    ... on PricingPercentageValue {
                      percentage
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';

    // print("\n🛒 fetchLatest300Orders() → Shopify orders(first: 100)");
    try {
      final response = await http.post(
        Uri.parse(shopifyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
        body: jsonEncode({
          'query': ordersQuery,
          'variables': {
            'first': 20,
          },
        }),
      );

      print("🛒 Shopify orders status: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("🛒 Shopify error body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null ||
            data['data'] == null ||
            data['data']['orders'] == null) {
          print("❌ Shopify invalid response: $data");
          throw Exception("Invalid response format from Shopify API");
        }

        final orders = data['data']['orders'];
        final edgesList = orders['edges'] as List<dynamic>;
        print("🛒 Shopify orders fetched: ${edgesList.length}");

        final allOrders = edgesList.map<Map<String, dynamic>>((e) {
          final node = Map<String, dynamic>.from(e['node']);
          return {
            "id": node["id"],
            "name": node["name"],
            "email": node["email"],
            "createdAt": node["createdAt"],
            "displayFinancialStatus": node["displayFinancialStatus"],
            "paymentGatewayNames": node["paymentGatewayNames"],
            "totalPriceSet": node["totalPriceSet"],
            "customer": node["customer"],
            "lineItems": node["lineItems"],
            "billingAddress": node["billingAddress"],
            "shippingAddress": node["shippingAddress"],
            "fulfillments": node["fulfillments"],
            "discountApplications": node["discountApplications"],
          };
        }).toList();

        await compareCustomers(customer, allOrders);
        return allOrders;
      } else {
        throw Exception("Failed to fetch orders");
      }
    } catch (e) {
      print("❌ fetchLatest300Orders() error: $e");
      throw Exception("Failed to fetch latest 300 orders: $e");
    }
  }

  // ===================== COMPARE + PROCESS ORDERS =====================
// ===================== COMPARE + PROCESS ORDERS =====================
//   Future<void> compareCustomers(List<Map<String, dynamic>> customers,
//       List<Map<String, dynamic>> allOrders) async {
//     // print("\n🔁 compareCustomers() → start processing ${allOrders.length} orders");

//     // Build phone → customerId map
//     final Map<String, int> customerPhoneToId = {};
//     for (var c in customers) {
//       final phoneRaw = c['phone'];
//       if (phoneRaw != null) {
//         final normalized = cleanPhone(phoneRaw.toString());
//         if (normalized.isNotEmpty) {
//           customerPhoneToId[normalized] = c['id'] as int;
//         }
//       }
//     }

//     // print("👥 Built phone→customerId map with ${customerPhoneToId.length} entries");

//     // Iterate Shopify orders
//     for (var order in allOrders) {
//       // print("\n==============================================");
//       // print("🚀 START ORDER: ${order['name']} (${order['id']})");
//       // print("==============================================");

//       resetOrderContext();

//       // ----------------- 0. Skip VOIDED -----------------
//       // print("🧾 Order financial status: ${order['displayFinancialStatus']}");
//       if (order['displayFinancialStatus'] == "VOIDED") {
//         // print("⏭ SKIPPING VOIDED ORDER: ${order['name']}");
//         failedOrders.add("${order['name']} → VOIDED");
//         continue;
//       }

//       // ----------------- 1. Skip if Already Exists in Backend -----------------
//       if (await orderAlreadyExists(order)) {
//         // print("⏭ SKIPPING ORDER → Already exists in backend: ${order['name']}");
//         failedOrders.add("${order['name']} → Already Created");
//         continue;
//       }

//       // ----------------- 2. Extract Phone -----------------
//       String? orderPhone = order['shippingAddress']?['phone']?.toString() ??
//           order['billingAddress']?['phone']?.toString();

//       // print("📦 Shipping phone: ${order['shippingAddress']?['phone']}");
//       // print("📦 Billing phone: ${order['billingAddress']?['phone']}");

//       if (orderPhone == null || orderPhone.trim().isEmpty) {
//         // print("❌ No phone found for order ${order['name']}");
//         failedOrders.add("${order['name']} → No Phone");
//         continue;
//       }

//       final normalizedOrderPhone = cleanPhone(orderPhone);
//       // print("📞 Order phone normalized: $normalizedOrderPhone");

//       // ----------------- 3. Address Fallback -----------------
//       Map<String, dynamic>? shippingAddress = order['shippingAddress'];
//       Map<String, dynamic>? billingAddress = order['billingAddress'];

//       final usedAddress = shippingAddress ?? billingAddress;
//       if (usedAddress == null) {
//         // print("❌ No shipping/billing address found: ${order['name']}");
//         failedOrders.add("${order['name']} → No Address");
//         continue;
//       }

//       // ----------------- 4. Check Existing Customer -----------------
//       final existingCustomerId = customerPhoneToId[normalizedOrderPhone];
//       // print( "👥 Existing customerId for $normalizedOrderPhone: $existingCustomerId");

//       try {
//         // ===============================================================
//         // 🔥🔥🔥 EXISTING CUSTOMER → SKIP ORDER (YOUR NEW REQUIREMENT) 🔥🔥🔥
//         // ===============================================================
//         // if (existingCustomerId != null) {
//         //   // print("⏭ Customer already exists → Skipping order: ${order['name']}");

//         //   failedOrders.add("${order['name']} → Customer exists, skipped");
//         //   continue; // move to next Shopify order
//         // }

//         if (existingCustomerId != null) {
//   // Use existing customer
//   customerId = existingCustomerId;

//   // Set state ID from address if available
//   String provinceName = shippingAddress?['province']?.toString() ?? '';
//   shippingstateId = stat.firstWhere(
//     (s) => s['name'] == provinceName,
//     orElse: () => {'id': 14},
//   )['id'];

//   // If address exists in your DB, reuse it
//   // But your backend does not provide “GET addresses for customer”
//   // So safest: always create a new address
//   await addaddress(
//     stat: stat,
//     order: order,
//     name:
//         "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}".trim(),
//     phone: shippingAddress?['phone']?.toString() ?? cleanPhone(orderPhone),
//     email: order['customer']?['email']?.toString() ?? '',
//     address:
//         "${shippingAddress?['address1'] ?? ''}, ${shippingAddress?['address2'] ?? ''}",
//     city: shippingAddress?['city']?.toString() ?? '',
//     state: shippingAddress?['province']?.toString() ?? '',
//     zipcode: shippingAddress?['zip']?.toString() ?? '',
//     country: shippingAddress?['country']?.toString() ?? '',
//   );

//   continue; // IMPORTANT - STOP going to "new customer" block
// }

//         // ===============================================================
//         // 🔥 NEW CUSTOMER FLOW → CREATE CUSTOMER + ADDRESS + CART + ORDER
//         // ===============================================================
//         // print("🆕 New customer flow for ${order['name']}");

//         await addCustomer(
//           stat: stat,
//           order: order,
//           shipping: shippingAddress,
//           name:
//               "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}"
//                   .trim(),
//           phone: billingAddress?['phone']?.toString() ?? normalizedOrderPhone,
//           email: order['customer']?['email']?.toString() ?? '',
//           address:
//               "${billingAddress?['address1'] ?? ''}, ${billingAddress?['address2'] ?? ''}",
//           city: billingAddress?['city']?.toString() ?? '',
//           state: billingAddress?['province']?.toString() ?? '',
//           zipcode: billingAddress?['zip']?.toString() ?? '',
//           country: billingAddress?['country']?.toString() ?? '',
//         );
//       } catch (e) {
//         // print("❌ compareCustomers() exception for ${order['name']}: $e");
//         failedOrders.add("${order['name']} → Failed due to exception");
//         await deletecartitem();
//       }
//     }

//     // ----------------- FINISH -----------------
//     // print("\n✅ compareCustomers() finished");
//     // print("✔ successorders: ${successorders.length} → $successorders");
//     // print("❌ failedOrders: ${failedOrders.length} → $failedOrders");

//     if (mounted) setState(() {});
//   }

  Future<void> compareCustomers(
    List<Map<String, dynamic>> customers,
    List<Map<String, dynamic>> allOrders,
  ) async {
    for (var order in allOrders) {
      resetOrderContext();

      final orderName = order['name']?.toString() ?? 'Unknown Order';

      if (order['displayFinancialStatus'] == "VOIDED") {
        failedOrders.add("$orderName → VOIDED");
        continue;
      }

      final existingOrderId = await orderAlreadyExists(order);

      if (existingOrderId != null) {
        failedOrders.add(
          "$orderName → Already Created (Order ID: $existingOrderId)",
        );
        continue;
      }

      String? orderPhone = order['shippingAddress']?['phone']?.toString() ??
          order['billingAddress']?['phone']?.toString();

      if (orderPhone == null || orderPhone.trim().isEmpty) {
        failedOrders.add("$orderName → No Phone");
        continue;
      }

      final normalizedOrderPhone = cleanPhone(orderPhone);

      Map<String, dynamic>? shippingAddress = order['shippingAddress'];
      Map<String, dynamic>? billingAddress = order['billingAddress'];
      final usedAddress = shippingAddress ?? billingAddress;

      if (usedAddress == null) {
        failedOrders.add("$orderName → No Address");
        continue;
      }

      final existingCustomer = await getCustomerByPhone(normalizedOrderPhone);
      final existingCustomerId = existingCustomer?['id'];

      try {
        if (existingCustomerId != null) {
          customerId = existingCustomerId is int
              ? existingCustomerId
              : int.tryParse(existingCustomerId.toString());

          await addaddress(
            stat: stat,
            order: order,
            name:
                "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}"
                    .trim(),
            phone: usedAddress['phone']?.toString() ?? normalizedOrderPhone,
            email: order['customer']?['email']?.toString() ?? '',
            address:
                "${usedAddress['address1'] ?? ''}, ${usedAddress['address2'] ?? ''}",
            city: usedAddress['city']?.toString() ?? '',
            state: usedAddress['province']?.toString() ?? '',
            zipcode: usedAddress['zip']?.toString() ?? '',
            country: usedAddress['country']?.toString() ?? '',
          );

          continue;
        }

        await addCustomer(
          stat: stat,
          order: order,
          shipping: shippingAddress,
          name:
              "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}"
                  .trim(),
          phone: normalizedOrderPhone,
          email: order['customer']?['email']?.toString() ?? '',
          address:
              "${usedAddress['address1'] ?? ''}, ${usedAddress['address2'] ?? ''}",
          city: usedAddress['city']?.toString() ?? '',
          state: usedAddress['province']?.toString() ?? '',
          zipcode: usedAddress['zip']?.toString() ?? '',
          country: usedAddress['country']?.toString() ?? '',
        );
      } catch (e) {
        failedOrders.add("$orderName → Failed due to exception");
        await deletecartitem();
      }
    }

    if (mounted) setState(() {});
  }

  // ===================== ADD CUSTOMER =====================
  Future<void> addCustomer({
    required Map<String, dynamic> order,
    required Map<String, dynamic>? shipping,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String zipcode,
    required String country,
    required List<Map<String, dynamic>> stat, // Pass state list
  }) async {
    print("\n🟦 addCustomer() for order: ${order['name']}");
    print("Name: $name");
    print("Phone(raw): $phone");
    print("Email: $email");
    print("Address: $address, $city, $state, $zipcode, $country");

    final token = await gettokenFromPrefs();

    int? getStateId(String provinceName, List<Map<String, dynamic>> states) {
      for (var st in states) {
        if (st['name'] == provinceName) {
          return st['id'] as int;
        }
      }
      return null;
    }

    try {
      int? stateId = getStateId(state, stat);
      stateId ??= 14; // default to Kerala
      print("State '$state' mapped to ID: $stateId");

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
        "comment": "Auto-created from order",
      };

      print("🔼 POST → /api/add/customer/");
      print("Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/add/customer/'),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      print("Customer API status: ${response.statusCode}");
      print("Customer API body: ${response.body}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        customerId = responseData['data']['id'];

        if (shipping != null) {
          if (mounted) {
            setState(() {
              successCustomers.add(
                "${name.isNotEmpty ? name : 'Unknown Customer'} - ${cleanPhone(phone)}",
              );
            });
          }

          await addaddress(
            stat: stat,
            order: order,
            name:
                "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}"
                    .trim(),
            phone: shipping['phone']?.toString() ?? cleanPhone(phone),
            email: order['customer']?['email']?.toString() ?? email,
            address:
                "${shipping['address1'] ?? ''}, ${shipping['address2'] ?? ''}"
                    .trim(),
            city: shipping['city']?.toString() ?? '',
            state: shipping['province']?.toString() ?? '',
            zipcode: shipping['zip']?.toString() ?? '',
            country: shipping['country']?.toString() ?? '',
          );
        }

        return;
      } else {
        failedOrders.add(
          "${order['name'] ?? 'Unknown Order'} → Customer Create Failed: ${extractApiError(response)}",
        );
      }
      failedOrders.add(
        "${order['name'] ?? 'Unknown Order'} → Customer Create Failed: ${extractApiError(response)}",
      );
    } catch (e) {
      print("❌ addCustomer() exception: $e");
      failedOrders.add(
        "${order['name'] ?? 'Unknown Order'} → Exception: $e",
      );
    }
  }

  String extractApiError(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        List<String> errors = [];

        data.forEach((key, value) {
          if (value is List) {
            errors.add("$key: ${value.join(', ')}");
          } else {
            errors.add("$key: $value");
          }
        });

        return errors.join(" | ");
      }

      return response.body;
    } catch (e) {
      return response.body;
    }
  }

  // ===================== ADD ADDRESS =====================
  Future<void> addaddress({
    required Map<String, dynamic> order,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state, // province name
    required String zipcode,
    required String country,
    required List<Map<String, dynamic>> stat,
  }) async {
    print("\n🟧 addaddress() for order: ${order['name']}");
    print("CustomerId: $customerId");
    print("Address: $address, $city, $state, $zipcode, $country");
    print("Phone(raw): $phone");

    try {
      final token = await gettokenFromPrefs();

      int? getStateId(String provinceName, List<Map<String, dynamic>> states) {
        for (var st in states) {
          if (st['name'] == provinceName) {
            return st['id'] as int;
          }
        }
        return null;
      }

      shippingstateId = getStateId(state, stat);
      shippingstateId ??= 14;
      print("Shipping state '$state' mapped to ID: $shippingstateId");

      final body = {
        "customer": customerId,
        "name": name,
        "address": address,
        "zipcode": zipcode,
        "city": city,
        "state": shippingstateId,
        "country": country,
        "phone":
            cleanPhone(phone).isNotEmpty ? cleanPhone(phone) : "0000000000",
        "email": email,
      };

      print("🔼 POST → /api/add/customer/address/$customerId/");
      print("Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/add/customer/address/$customerId/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("Address API status: ${response.statusCode}");
      print("Address API body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        addressId = responseData["data"]["id"];
        print("✅ ADDRESS CREATED → addressId=$addressId");
        print("➡ Now calling addtocart() for order: ${order['name']}");
        await addtocart(order);
      } else {
        print("❌ Address creation FAILED for order: ${order['name']}");
        failedOrders.add(
          "${order['name'] ?? 'Unknown Order'} → Address Create Failed: ${extractApiError(response)}",
        );
      }
    } catch (e) {
      print("❌ addaddress() exception: $e");
      failedOrders.add(order['name'] ?? 'Unknown Order');
    }
  }

  // ===================== ADD TO CART =====================
  Future<void> addtocart(Map<String, dynamic> order) async {
    print("\n🟨 addtocart() for order: ${order['name']}");
    final token = await gettokenFromPrefs();
    allAdded = true; // reset per order
    print("allAdded reset to true");

    try {
      if (order.isEmpty) {
        print("⚠ order is empty in addtocart()");
        return;
      }

      var lineItems = order['lineItems'];
      if (lineItems == null || lineItems['edges'] == null) {
        print("⚠ No lineItems/edges found for this order");
        return;
      }

      var itemsList = lineItems['edges'];
      if (itemsList is! List) {
        print("⚠ itemsList is not a List");
        return;
      }

      print("🛒 Items to add to cart: ${itemsList.length}");

      for (var item in itemsList) {
        if (item['node'] == null || item['node']['variant'] == null) {
          // print("⚠ Invalid item format (no node/variant): $item");
          continue;
        }

        final productSku = item['node']['variant']['sku'];
        final quantity = item['node']['quantity'];
        final productTitle = item['node']['title']?.toString() ?? '';

        print("➡ Item: SKU=$productSku, QTY=$quantity, TITLE=$productTitle");

        if (productSku == null ||
            productSku.toString().trim().isEmpty ||
            quantity == null) {
          final message =
              "${order['name']} → SKU missing | QTY: ${quantity ?? '-'} | TITLE: $productTitle";

          print("⚠ $message");

          setState(() {
            missingSkuProducts.add(message);
            failedOrders.add(message);
          });

          allAdded = false;
          break;
        }

        final shopifyPrice =
            item['node']['variant']?['price']?.toString() ?? "0";

        final discountedTotal = item['node']['discountedTotalSet']?['shopMoney']
                ?['amount']
            ?.toString();

        final body = {
          'product': productSku,
          'quantity': quantity,
          'rate': shopifyPrice,
          'price': shopifyPrice,
          'shopify_price': shopifyPrice,
          'shopify_discounted_total': discountedTotal,
        };

        print("🔼 POST → /api/cart/product/");
        print("Body: ${jsonEncode(body)}");

        final response = await http.post(
          Uri.parse('$api/api/cart/product/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        print("Cart API status: ${response.statusCode}");
        print("Cart API body: ${response.body}");

        print("");
        print("========== CART API ==========");
        print("ORDER : ${order['name']}");
        print("SKU   : $productSku");
        print("TITLE : $productTitle");
        print("QTY   : $quantity");
        print("STATUS: ${response.statusCode}");
        print("BODY  : ${response.body}");
        print("==============================");
        print("");

        if (response.statusCode != 201) {
          print(
              "❌ CART ADD FAILED for SKU=$productSku in order: ${order['name']}, clearing cart");
          await deletecartitem();
          allAdded = false;

          // Add a detailed failed message for this product
          final msg =
              "${order['name']} → Cart Add Failed for SKU $productSku ($productTitle): ${extractApiError(response)}";
          failedOrders.add(msg);
          break;
        }
      }

      print("✅ addtocart() finished, allAdded=$allAdded");
      if (allAdded) {
        print("➡ Proceed to ordercreate() for order: ${order['name']}");
        await ordercreate(order);
      } else {
        print("⏭ Skipping ordercreate() because allAdded=false");
      }
    } catch (e) {
      print("❌ addtocart() exception: $e");
      await deletecartitem();
      failedOrders.add(order['name'] ?? 'Unknown Order');
    }
  }

  // Helper to prepare human-readable item summary for stock error
  String _buildOrderItemSummary(Map<String, dynamic> order) {
    final lineItems = order['lineItems'];
    if (lineItems == null || lineItems['edges'] == null) return "";
    final itemsList = lineItems['edges'] as List<dynamic>;

    final List<String> parts = [];
    for (var item in itemsList) {
      final node = item['node'];
      if (node == null) continue;
      final sku = node['variant']?['sku']?.toString() ?? 'UNKNOWN SKU';
      final title = node['title']?.toString() ?? 'Unknown Product';
      parts.add("SKU $sku ($title)");
    }
    return parts.join(", ");
  }

  // ===================== CREATE ORDER =====================
  Future<void> ordercreate(var order) async {
    print("🟥 ordercreate() for order: ${order['name']}");

    try {
      final token = await gettokenFromPrefs();

      // ======================================================
      // 🔥 ADD SHIPPING CHARGE IF TOTAL < 500
      // ======================================================
      double totalAmount = double.parse(
        order['totalPriceSet']?['shopMoney']?['amount'] ?? "0",
      );

      double shippingCharge = 0;

      if (totalAmount < 500) {
        shippingCharge = 60;
        totalAmount = totalAmount + shippingCharge;
      }

      print(
          "💰 Final Amount: $totalAmount (Shipping Charge = $shippingCharge)");

      // ======================================================
      // 🔥 CREATE ORDER API CALL
      // ======================================================
      var response = await http.post(
        Uri.parse('$api/api/order/create/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'manage_staff': 17,
          "company": 5,
          "customer": customerId,
          'billing_address': addressId,
          'order_date': DateTime.now().toIso8601String(),
          "family": 3,
          "state": shippingstateId,

          // 🔥 Payment Status Mapping
          'payment_status': mapPaymentStatus(order['displayFinancialStatus']),

          // 🔥 Total after shipping charge
          'total_amount': totalAmount.toString(),

          // 🔥 send shipping charge in order
          'shipping_charge': shippingCharge.toString(),

          'bank': 8,
          'payment_method': order['paymentGatewayNames'][0],
          'warehouses': 1,
          'status': 'Invoice Created',
          "shopify_order_id": order["id"],
        }),
      );

      // print("Order Create API status: ${response.statusCode}");
      // print("Order Create API body: ${response.body}");

      // ======================================================
      // ✅ SUCCESS BLOCK
      // ======================================================
      if (response.statusCode == 201) {
        print("✅ ORDER CREATED successfully");

        final responseData = jsonDecode(response.body);
        final orderId = responseData['data']['id'];

        setState(() {
          successorders.add(order['name']);
        });

        await updatingamount(order, orderId);

        await deletecartitem();

        return; // MOST IMPORTANT
      }

      // ======================================================
      // ❌ FAILURE BLOCK
      // ======================================================
      print("❌ ordercreate() FAILED for order: ${order['name']}");

      if (response.body.contains("Not enough available stock")) {
        print("🟥 STOCK FAILURE DETECTED");

        for (var item in order['lineItems']['edges']) {
          final sku = item['node']['variant']['sku'];
          final title = item['node']['title'];
          final qty = item['node']['quantity'];

          print("🟥 Failed Product → SKU: $sku | Title: $title | Qty: $qty");

          failedStockProducts.add(
              "[${order['name']}] SKU $sku – $title (Qty $qty) → STOCK NOT AVAILABLE");
        }
      }

      setState(() {
        failedOrders.add(
          "${order['name']} → Order Create Failed: ${extractApiError(response)}",
        );
      });

      await deletecartitem();
    } catch (e) {
      print("❌ Exception in ordercreate(): $e");
      failedOrders.add(order['name']);
      await deletecartitem();
    }
  }

  // ===================== UPDATE AMOUNT & CLEAN CART =====================
  Future<void> updatingamount(Map<String, dynamic> order, int id) async {
    print("\n🟪 updatingamount() for order: ${order['name']}, orderId=$id");
    try {
      final token = await gettokenFromPrefs();

      final totalAmount =
          order['totalPriceSet']?['shopMoney']?['amount'] ?? "0";

      Map<String, dynamic> body = {
        'total_amount': totalAmount,
      };

      print("🔼 PUT → /api/shipping/$id/order/");
      print("Body: ${jsonEncode(body)}");

      var response = await http.put(
        Uri.parse('$api/api/shipping/$id/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("Update Amount API status: ${response.statusCode}");
      print("Update Amount API body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("❌ updatingamount() exception: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      print("🧹 updatingamount() finally → calling deletecartitem()");
      await deletecartitem();
    }
  }

  // ===================== DELETE CART =====================
  Future<void> deletecartitem() async {
    print("\n🗑 deletecartitem() called");
    final token = await gettokenFromPrefs();

    try {
      print("🔽 DELETE → /api/cart/delete/all/");
      final response = await http.delete(
        Uri.parse('$api/api/cart/delete/all/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Delete Cart API status: ${response.statusCode}");
      print("Delete Cart API body: ${response.body}");

      if (!mounted) return;

      // ACCEPT 200 OR 204 AS SUCCESS
      if (response.statusCode == 200 || response.statusCode == 204) {
        print("🟩 CART CLEARED SUCCESSFULLY");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // ANY OTHER STATUS → FAIL
      print("❌ Failed to delete cart items, status: ${response.statusCode}");
      throw Exception('Failed to delete cart');
    } catch (error) {
      print("❌ deletecartitem() exception: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===================== UI =====================
// ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          'Order Bulk Upload',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF02347C),
                        Color(0xFF00B94D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Shopify Order Import',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fetch latest orders, create customers, add address, cart items and backend orders automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            'Fetch Orders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF057A33),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  print("\n============================");
                                  print("🟢 FETCH ORDERS BUTTON PRESSED");
                                  print("============================\n");

                                  setState(() {
                                    isLoading = true;
                                    loadingText =
                                        "Fetching & processing latest orders...";
                                    failedOrders.clear();
                                    successorders.clear();
                                    successCustomers.clear();
                                    failedcustomer.clear();
                                    failedStockProducts.clear();
                                    missingSkuProducts.clear();
                                  });

                                  await getcustomer();

                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }

                                  print("\n🏁 BULK PROCESS FINISHED");
                                  print("✔ successorders: $successorders");
                                  print("❌ failedOrders: $failedOrders");
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildCountCard(
                        title: "Success",
                        count: successorders.length,
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF00A651),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCountCard(
                        title: "Customers",
                        count: successCustomers.length,
                        icon: Icons.person_add_alt_1_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCountCard(
                        title: "Failed",
                        count: failedOrders.length,
                        icon: Icons.error_rounded,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (successorders.isEmpty &&
                    successCustomers.isEmpty &&
                    failedOrders.isEmpty &&
                    failedStockProducts.isEmpty &&
                    missingSkuProducts.isEmpty)
                  _buildEmptyState(),
                if (successorders.isNotEmpty)
                  _buildResultCard(
                    title: "Success Orders",
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF00A651),
                    items: successorders,
                  ),
                if (successCustomers.isNotEmpty)
                  _buildResultCard(
                    title: "Customers Created",
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF1565C0),
                    items: successCustomers,
                  ),
                if (failedOrders.isNotEmpty)
                  _buildResultCard(
                    title: "Failed Orders",
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE53935),
                    items: failedOrders,
                    isFailed: true,
                  ),
                if (failedStockProducts.isNotEmpty)
                  _buildResultCard(
                    title: "Products with Stock Issues",
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFFD32F2F),
                    items: failedStockProducts,
                    isFailed: true,
                  ),
                if (missingSkuProducts.isNotEmpty)
                  _buildResultCard(
                    title: "Products with Missing SKU",
                    icon: Icons.qr_code_2_rounded,
                    color: const Color(0xFF8E24AA),
                    items: missingSkuProducts,
                    isFailed: true,
                  ),
              ],
            ),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            "No orders processed yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap Fetch Orders to start importing latest Shopify orders.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    bool isFailed = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${items.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: items.map((msg) {
                Color itemColor = isFailed ? color : Colors.black87;

                if (msg.contains("Already Created")) {
                  itemColor = Colors.orange.shade800;
                } else if (msg.contains("VOIDED")) {
                  itemColor = Colors.grey.shade700;
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: itemColor.withOpacity(0.13),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isFailed
                            ? Icons.info_outline_rounded
                            : Icons.done_rounded,
                        size: 18,
                        color: itemColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: itemColor,
                            fontWeight: msg.contains("Already Created")
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.58),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: Color(0xFF00A651),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Please wait",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loadingText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
