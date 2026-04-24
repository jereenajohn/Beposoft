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
    // print("🔹 gettokenFromPrefs() → token present: ${t != null}");
    return t;
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('department');
    // print("🔹 getdepFromPrefs() → department: $d");
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
    // print("📞 cleanPhone(): '$original' → '$phone'");
    return phone;
  }

  /// Reset per-order context so each order starts clean
  void resetOrderContext() {
    customerId = null;
    addressId = null;
    shippingstateId = null;
    allAdded = true;
    // print(
    //     "🔄 resetOrderContext() → customerId=null, addressId=null, shippingstateId=null, allAdded=true");
  }

  // ===================== FETCH STATES =====================
  Future<void> getstate() async {
    // print("\n🌍 getstate() → Fetching /api/states/");
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("🌍 /api/states/ → status: ${response.statusCode}");
      if (response.statusCode != 200) {
        // print("🌍 /api/states/ body: ${response.body}");
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
        // print("🌍 States loaded: ${stat.length}");
      }
    } catch (error) {
      // print("❌ getstate() error: $error");
    }
  }

  // ===================== FETCH CUSTOMERS (LOCAL) =====================
  Future<void> getcustomer() async {
    // print("\n👥 getcustomer() → Fetching /api/customers/");
    try {
      final dep = await getdepFromPrefs();
      final token = await gettokenFromPrefs();

      if (token == null) {
        // print("❌ getcustomer(): token is null");
        return;
      }

      final jwt = JWT.decode(token);
      var name = jwt.payload['name'];
      // print("👥 Decoded JWT name: $name, department: $dep");

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("👥 /api/customers/ → status: ${response.statusCode}");
      if (response.statusCode != 200) {
        // print("👥 /api/customers/ body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
            'phone': productData['phone'],
            'email': productData['email'],
          });
        }

        if (!mounted) return;
        setState(() {
          customer = managerlist;
        });

        // print("👥 Local customers loaded: ${customer.length}");
        // After loading customers, fetch Shopify orders and process
        await fetchLatest300Orders();
      }
    } catch (error) {
      // print("❌ getcustomer() error: $error");
      if (!mounted) return;
    }
  }

  Future<int?> orderAlreadyExists(Map<String, dynamic> shopOrder) async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final List orders = data["data"];

      final shopifyId = shopOrder["id"];

      for (var ord in orders) {
        if (ord["shopify_order_id"] != null &&
            ord["shopify_order_id"].toString() == shopifyId.toString()) {
          return ord["id"]; // 🔥 return LOCAL ORDER ID
        }
      }

      return null;
    } catch (e) {
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
            'first': 10,
          },
        }),
      );

      // print("🛒 Shopify orders status: ${response.statusCode}");
      if (response.statusCode != 200) {
        // print("🛒 Shopify error body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null ||
            data['data'] == null ||
            data['data']['orders'] == null) {
          // print("❌ Shopify invalid response: $data");
          throw Exception("Invalid response format from Shopify API");
        }

        final orders = data['data']['orders'];
        final edgesList = orders['edges'] as List<dynamic>;
        // print("🛒 Shopify orders fetched: ${edgesList.length}");

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
      // print("❌ fetchLatest300Orders() error: $e");
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

  Future<void> compareCustomers(List<Map<String, dynamic>> customers,
      List<Map<String, dynamic>> allOrders) async {
    // Build phone → customerId map
    final Map<String, int> customerPhoneToId = {};
    for (var c in customers) {
      final phoneRaw = c['phone'];
      if (phoneRaw != null) {
        final normalized = cleanPhone(phoneRaw.toString());
        if (normalized.isNotEmpty) {
          customerPhoneToId[normalized] = c['id'] as int;
        }
      }
    }

    for (var order in allOrders) {
      resetOrderContext();

      // 0️⃣ Skip VOIDED orders
      if (order['displayFinancialStatus'] == "VOIDED") {
        failedOrders.add("${order['name']} → VOIDED");
        continue;
      }

      final existingOrderId = await orderAlreadyExists(order);

      if (existingOrderId != null) {
        failedOrders.add(
            "${order['name']} → Already Created (Order ID: $existingOrderId)");
        continue;
      }

      // 2️⃣ Normalize phone from shipping or billing
      String? orderPhone = order['shippingAddress']?['phone']?.toString() ??
          order['billingAddress']?['phone']?.toString();

      if (orderPhone == null || orderPhone.trim().isEmpty) {
        failedOrders.add("${order['name']} → No Phone");
        continue;
      }

      final normalizedOrderPhone = cleanPhone(orderPhone);

      // 3️⃣ Address fallback
      Map<String, dynamic>? shippingAddress = order['shippingAddress'];
      Map<String, dynamic>? billingAddress = order['billingAddress'];
      final usedAddress = shippingAddress ?? billingAddress;

      if (usedAddress == null) {
        failedOrders.add("${order['name']} → No Address");
        continue;
      }

      // 4️⃣ Check if customer already exists (but DO NOT skip)
      final existingCustomerId = customerPhoneToId[normalizedOrderPhone];

      try {
        // ===============================================
        // 🚀 EXISTING CUSTOMER — create only order
        // ===============================================
      if (existingCustomerId != null) {
  customerId = existingCustomerId;

  // Create address for this order
  await addaddress(
    stat: stat,
    order: order,
    name: "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}".trim(),
    phone: usedAddress['phone']?.toString() ?? normalizedOrderPhone,
    email: order['customer']?['email']?.toString() ?? '',
    address: "${usedAddress['address1'] ?? ''}, ${usedAddress['address2'] ?? ''}",
    city: usedAddress['city']?.toString() ?? '',
    state: usedAddress['province']?.toString() ?? '',
    zipcode: usedAddress['zip']?.toString() ?? '',
    country: usedAddress['country']?.toString() ?? '',
  );

  // 🚀 PROCEED FOR ORDER CREATION
  continue;   // NO — REMOVE THIS
}


        // ===============================================
        // 🆕 NEW CUSTOMER — create customer then order
        // ===============================================
        await addCustomer(
          stat: stat,
          order: order,
          shipping: shippingAddress,
          name:
              "${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}"
                  .trim(),
          phone: billingAddress?['phone']?.toString() ?? normalizedOrderPhone,
          email: order['customer']?['email']?.toString() ?? '',
          address:
              "${billingAddress?['address1'] ?? ''}, ${billingAddress?['address2'] ?? ''}",
          city: billingAddress?['city']?.toString() ?? '',
          state: billingAddress?['province']?.toString() ?? '',
          zipcode: billingAddress?['zip']?.toString() ?? '',
          country: billingAddress?['country']?.toString() ?? '',
        );
      } catch (e) {
        failedOrders.add("${order['name']} → Failed due to exception");
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
    // print("\n🟦 addCustomer() for order: ${order['name']}");
    // print("Name: $name");
    // print("Phone(raw): $phone");
    // print("Email: $email");
    // print("Address: $address, $city, $state, $zipcode, $country");

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
      // print("State '$state' mapped to ID: $stateId");

      final body = {
        "name": name.isNotEmpty ? name : "Unknown Customer",
        "manager": 17,
        "state": stateId,
        "phone": cleanPhone(phone),
        "alt_phone": "",
        "email": email.isNotEmpty ? email : "no-email@example.com",
        "address": address,
        "zip_code": zipcode,
        "city": city,
        "comment": "Auto-created from order",
      };

      // print("🔼 POST → /api/add/customer/");
      // print("Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/add/customer/'),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      // print("Customer API status: ${response.statusCode}");
      // print("Customer API body: ${response.body}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        customerId = responseData['data']['id'];

        // print("✅ CUSTOMER CREATED → customerId=$customerId");

        if (shipping != null) {
          if (mounted) {
            setState(() {
              successCustomers.add(
                  "${name.isNotEmpty ? name : 'Unknown Customer'} - ${cleanPhone(phone)}");
            });
          }

          // print("➡ Now calling addaddress() for shipping address");
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
        } else {
          // print(
          //     "ℹ SHIPPING is null, skipping addaddress(), directly using billing");
        }
      } else {
        // print("❌ Customer creation FAILED for order: ${order['name']}");
        failedOrders.add(order['name'] ?? 'Unknown Order');
      }
    } catch (e) {
      // print("❌ addCustomer() exception: $e");
      failedOrders.add(order['name'] ?? 'Unknown Order');
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
    // print("\n🟧 addaddress() for order: ${order['name']}");
    // print("CustomerId: $customerId");
    // print("Address: $address, $city, $state, $zipcode, $country");
    // print("Phone(raw): $phone");

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
      // print("Shipping state '$state' mapped to ID: $shippingstateId");

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

      // print("🔼 POST → /api/add/customer/address/$customerId/");
      // print("Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/add/customer/address/$customerId/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // print("Address API status: ${response.statusCode}");
      // print("Address API body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        addressId = responseData["data"]["id"];
        // print("✅ ADDRESS CREATED → addressId=$addressId");
        // print("➡ Now calling addtocart() for order: ${order['name']}");
        await addtocart(order);
      } else {
        // print("❌ Address creation FAILED for order: ${order['name']}");
        failedOrders.add(order['name'] ?? 'Unknown Order');
      }
    } catch (e) {
      // print("❌ addaddress() exception: $e");
      failedOrders.add(order['name'] ?? 'Unknown Order');
    }
  }

  // ===================== ADD TO CART =====================
  Future<void> addtocart(Map<String, dynamic> order) async {
    // print("\n🟨 addtocart() for order: ${order['name']}");
    final token = await gettokenFromPrefs();
    allAdded = true; // reset per order
    // print("allAdded reset to true");

    try {
      if (order.isEmpty) {
        // print("⚠ order is empty in addtocart()");
        return;
      }

      var lineItems = order['lineItems'];
      if (lineItems == null || lineItems['edges'] == null) {
        // print("⚠ No lineItems/edges found for this order");
        return;
      }

      var itemsList = lineItems['edges'];
      if (itemsList is! List) {
        // print("⚠ itemsList is not a List");
        return;
      }

      // print("🛒 Items to add to cart: ${itemsList.length}");

      for (var item in itemsList) {
        if (item['node'] == null || item['node']['variant'] == null) {
          // print("⚠ Invalid item format (no node/variant): $item");
          continue;
        }

        final productSku = item['node']['variant']['sku'];
        final quantity = item['node']['quantity'];
        final productTitle = item['node']['title']?.toString() ?? '';

        // print("➡ Item: SKU=$productSku, QTY=$quantity, TITLE=$productTitle");

        if (productSku == null || quantity == null) {
          // print("⚠ Missing productSku or quantity in item: $item");
          continue;
        }

        final body = {
          'product': productSku,
          'quantity': quantity,
        };

        // print("🔼 POST → /api/cart/product/");
        // print("Body: ${jsonEncode(body)}");

        final response = await http.post(
          Uri.parse('$api/api/cart/product/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        // print("Cart API status: ${response.statusCode}");
        // print("Cart API body: ${response.body}");

        if (response.statusCode != 201) {
          // print(
          //     "❌ CART ADD FAILED for SKU=$productSku in order: ${order['name']}, clearing cart");
          await deletecartitem();
          allAdded = false;

          // Add a detailed failed message for this product
          final msg =
              "${order['name']} → Failed to add SKU $productSku ($productTitle) to cart";
          failedOrders.add(msg);
          break;
        }
      }

      // print("✅ addtocart() finished, allAdded=$allAdded");
      if (allAdded) {
        // print("➡ Proceed to ordercreate() for order: ${order['name']}");
        await ordercreate(order);
      } else {
        // print("⏭ Skipping ordercreate() because allAdded=false");
      }
    } catch (e) {
      // print("❌ addtocart() exception: $e");
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
    // print("🟥 ordercreate() for order: ${order['name']}");

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

      // print(
      //     "💰 Final Amount: $totalAmount (Shipping Charge = $shippingCharge)");

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
        // print("✅ ORDER CREATED successfully");

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
      // print("❌ ordercreate() FAILED for order: ${order['name']}");

      if (response.body.contains("Not enough available stock")) {
        // print("🟥 STOCK FAILURE DETECTED");

        for (var item in order['lineItems']['edges']) {
          final sku = item['node']['variant']['sku'];
          final title = item['node']['title'];
          final qty = item['node']['quantity'];

          // print("🟥 Failed Product → SKU: $sku | Title: $title | Qty: $qty");

          failedStockProducts.add(
              "[${order['name']}] SKU $sku – $title (Qty $qty) → STOCK NOT AVAILABLE");
        }
      }

      setState(() {
        failedOrders.add(order['name']);
      });

      await deletecartitem();
    } catch (e) {
      // print("❌ Exception in ordercreate(): $e");
      failedOrders.add(order['name']);
      await deletecartitem();
    }
  }

  // ===================== UPDATE AMOUNT & CLEAN CART =====================
  Future<void> updatingamount(Map<String, dynamic> order, int id) async {
    // print("\n🟪 updatingamount() for order: ${order['name']}, orderId=$id");
    try {
      final token = await gettokenFromPrefs();

      final totalAmount =
          order['totalPriceSet']?['shopMoney']?['amount'] ?? "0";

      Map<String, dynamic> body = {
        'total_amount': totalAmount,
      };

      // print("🔼 PUT → /api/shipping/$id/order/");
      // print("Body: ${jsonEncode(body)}");

      var response = await http.put(
        Uri.parse('$api/api/shipping/$id/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // print("Update Amount API status: ${response.statusCode}");
      // print("Update Amount API body: ${response.body}");

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
      // print("❌ updatingamount() exception: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      // print("🧹 updatingamount() finally → calling deletecartitem()");
      await deletecartitem();
    }
  }

  // ===================== DELETE CART =====================
  Future<void> deletecartitem() async {
    // print("\n🗑 deletecartitem() called");
    final token = await gettokenFromPrefs();

    try {
      // print("🔽 DELETE → /api/cart/delete/all/");
      final response = await http.delete(
        Uri.parse('$api/api/cart/delete/all/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // print("Delete Cart API status: ${response.statusCode}");
      // print("Delete Cart API body: ${response.body}");

      if (!mounted) return;

      // ACCEPT 200 OR 204 AS SUCCESS
      if (response.statusCode == 200 || response.statusCode == 204) {
        // print("🟩 CART CLEARED SUCCESSFULLY");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // ANY OTHER STATUS → FAIL
      // print("❌ Failed to delete cart items, status: ${response.statusCode}");
      throw Exception('Failed to delete cart');
    } catch (error) {
      // print("❌ deletecartitem() exception: $error");
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Bulk Upload',
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 4,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 80,
                    color: Color.fromARGB(255, 15, 175, 0),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Fetch the Latest 100 Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'Fetch Orders',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 185, 13),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      // print("\n============================");
                      // print("🟢 FETCH ORDERS BUTTON PRESSED");
                      // print("============================\n");

                      setState(() {
                        isLoading = true;
                        loadingText = "Fetching & processing latest orders...";
                        failedOrders.clear();
                        successorders.clear();
                        successCustomers.clear();
                        failedcustomer.clear();
                      });
                      await getcustomer();
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }

                      // print("\n🏁 BULK PROCESS FINISHED");
                      // print("✔ successorders: $successorders");
                      // print("❌ failedOrders: $failedOrders");
                    },
                  ),
                  const SizedBox(height: 30),

                  // Success Orders
                  if (successorders.isNotEmpty) ...[
                    const Text(
                      "Success Orders:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 150, 0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 73, 244, 54)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: successorders
                            .map((orderName) => Text("- $orderName"))
                            .toList(),
                      ),
                    ),
                  ],

                  // Customers Created
                  if (successCustomers.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "Customers Created:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: successCustomers
                            .map((customerInfo) => Text("- $customerInfo"))
                            .toList(),
                      ),
                    ),
                  ],

                  // Failed Orders (includes stock error details for each order)
                  if (failedOrders.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "Failed Orders (including stock issues):",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: failedOrders.map((msg) {
                          Color textColor = Colors.red;

                          if (msg.contains("Already Created")) {
                            textColor =
                                Colors.orange; // Highlight Already Created
                          } else if (msg.contains("VOIDED")) {
                            textColor = Colors.grey; // Show Voided in grey
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              "- $msg",
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: msg.contains("Already Created")
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  if (failedStockProducts.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "Products with Stock Issues:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: failedStockProducts
                            .map((info) => Text("- $info"))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      loadingText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
