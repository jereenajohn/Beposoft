import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class codsalereport_datewise_view extends StatefulWidget {
  final String date;
  final String? family;
  final String? staff;
  final String? state;

  const codsalereport_datewise_view({
    super.key,
    required this.date,
    this.family,
    this.staff,
    this.state,
  });

  @override
  State<codsalereport_datewise_view> createState() =>
      _codsalereport_datewise_viewState();
}

class _codsalereport_datewise_viewState
    extends State<codsalereport_datewise_view> {
  List<Map<String, dynamic>> codsalesreport = [];
  bool isLoading = true;

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getcoddatewisedetails();
  }

  Future<void> getcoddatewisedetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await gettokenFromPrefs();

      final uri = Uri.parse('$api/api/COD/sales/').replace(
        queryParameters: {
          'start_date': widget.date,
          'end_date': widget.date,
          if (widget.family != null && widget.family!.isNotEmpty)
            'family': widget.family!,
          if (widget.staff != null && widget.staff!.isNotEmpty)
            'staff': widget.staff!,
          if (widget.state != null && widget.state!.isNotEmpty)
            'state': widget.state!,
        },
      );

      debugPrint('COD BREAKUP URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('COD BREAKUP STATUS: ${response.statusCode}');
      debugPrint('COD BREAKUP BODY: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? [];

        List<Map<String, dynamic>> codsaleslist = [];

        if (data.isNotEmpty) {
          final orders = data[0]['orders'] ?? [];

          for (var order in orders) {
            codsaleslist.add({
              'id': order['id'],
              'invoice': order['invoice'],
              'order_date': order['order_date'],
              'payment_status': order['payment_status'],
              'status': order['status'],
              'staff_name': order['staff_name'] ?? 'Unknown',
              'customer_name': order['customer_name'] ?? 'Unknown',
              'customer': order['customer'],
              'total_paid': order['total_paid_amount'] ?? 0.0,
              'balance_amount': order['balance_amount'] ?? 0.0,
              'total_amount': order['total_amount'] ?? 0.0,
            });
          }
        }

        setState(() {
          codsalesreport = codsaleslist;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch breakup (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      debugPrint('COD BREAKUP ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching COD breakup')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _amount(dynamic value) {
    final parsed = double.tryParse(value.toString()) ?? 0.0;
    return parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "COD Breakup - ${widget.date}",
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 32, 43, 61),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 32, 43, 61),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 12, 80, 163),
              ),
            )
          : codsalesreport.isEmpty
              ? const Center(
                  child: Text(
                    'No breakup data found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: codsalesreport.length,
                  itemBuilder: (context, index) {
                    final salesData = codsalesreport[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice: ${salesData['invoice'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color.fromARGB(255, 12, 80, 163),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(color: Colors.grey.shade300),
                            _infoRow('Order Date', salesData['order_date']),
                            _infoRow(
                                'Payment Status', salesData['payment_status']),
                            _infoRow('Status', salesData['status']),
                            _infoRow('Customer', salesData['customer_name']),
                            _infoRow('Staff', salesData['staff_name']),
                            _infoRow(
                              'Total Amount',
                              '₹${_amount(salesData['total_amount'])}',
                            ),
                            _infoRow(
                              'Paid Amount',
                              '₹${_amount(salesData['total_paid'])}',
                            ),
                            _infoRow(
                              'Balance',
                              '₹${_amount(salesData['balance_amount'])}',
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderReview(
                                        id: salesData['id'],
                                        customer: salesData['customer'],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 17),
                                label: const Text('View'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(255, 12, 80, 163),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(
                color: Color.fromARGB(255, 32, 43, 61),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}