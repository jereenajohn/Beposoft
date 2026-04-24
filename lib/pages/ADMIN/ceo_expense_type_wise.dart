import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/update_Expense.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class expence_list_type extends StatefulWidget {
  final String type;
  final String fromDate;
  final String toDate;

  const expence_list_type({
    super.key,
    required this.type,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<expence_list_type> createState() => _expence_list_typeState();
}

class _expence_list_typeState extends State<expence_list_type> {
  List<Map<String, dynamic>> expensedata = [];
  List<Map<String, dynamic>> originalExpensedata = [];
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> purposesofpay = [];
  List<Map<String, dynamic>> company = [];
  List<Map<String, dynamic>> sta = [];

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedpurpose;
  bool isLoading = true;
  double totalExp = 0.0;

  final NumberFormat currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();

    try {
      if (widget.fromDate.isNotEmpty) {
        startDate = DateTime.tryParse(widget.fromDate);
      }
      if (widget.toDate.isNotEmpty) {
        endDate = DateTime.tryParse(widget.toDate);
      }
    } catch (_) {}

    getexpenselist();
    getbank();
    getcompany();
    getstaff();
    getpurpose();
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getpurpose() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/apis/add/purpose/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> purposelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          purposelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          purposesofpay = purposelist;
        });
      }
    } catch (error) {}
  }

  Future<void> getbank() async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch'],
          });
        }

        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {}
  }

  Future<void> getcompany() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);

        for (var productData in productsData) {
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}
  }

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();
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

        for (var productData in productsData) {
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'allocated_states': productData['allocated_states'],
          });
        }

        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  Future<void> getexpenselist() async {
    try {
      final token = await gettokenFromPrefs();

      setState(() {
        isLoading = true;
      });

      final uri = Uri.parse('$api/api/expense/get/data/filter/').replace(
        queryParameters: {
          'expense_type': widget.type,
          'start_date': _getEffectiveStartDate(),
          'end_date': _getEffectiveEndDate(),
          'ordering': '-id',
        },
      );

      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> expenselist = [];
      double totalExpense = 0.0;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'] ?? [];
        final summary = parsed['summary'] ?? {};

        for (var productData in results) {
          final double amount =
              double.tryParse(productData['amount'].toString()) ?? 0.0;

          expenselist.add({
            'id': productData['id'],
            'purpose_of_payment': productData['purpose_of_payment'],
            'purpose_of_pay': productData['purpose_of_pay'],
            'bank': productData['bank']?['id'],
            'bank_name': productData['bank']?['name'],
            'amount': amount,
            'company': productData['company']?['id'],
            'company_name': productData['company']?['name'],
            'payed_by': productData['payed_by']?['id'],
            'payed_by_name': productData['payed_by']?['name'],
            'transaction_id': productData['transaction_id'],
            'expense_date': productData['expense_date'],
            'added_by': productData['added_by'],
            'asset_types': productData['asset_types'],
            'name': productData['name'],
            'loanname': productData['loanname'],
            'expense_type': productData['expense_type'],
            'categoryname': productData['categoryname'],
            'description': productData['description'],
            'purpose_id': productData['purpose_id'],
            'company_id': productData['company_id'],
            'bank_id': productData['bank_id'],
            'category_id': productData['category_id'],
          });
        }

        totalExpense =
            double.tryParse(summary['total_amount']?.toString() ?? '0') ?? 0.0;

        setState(() {
          expensedata = expenselist;
          originalExpensedata = List.from(expenselist);
          totalExp = totalExpense;
          isLoading = false;
        });
      } else {
        setState(() {
          expensedata = [];
          originalExpensedata = [];
          totalExp = 0.0;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        expensedata = [];
        originalExpensedata = [];
        totalExp = 0.0;
        isLoading = false;
      });
    }
  }

  String _getEffectiveStartDate() {
    if (startDate != null) {
      return DateFormat('yyyy-MM-dd').format(startDate!);
    }
    return widget.fromDate;
  }

  String _getEffectiveEndDate() {
    if (endDate != null) {
      return DateFormat('yyyy-MM-dd').format(endDate!);
    }
    return widget.toDate;
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (e) {
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (e) {
        throw FormatException('Invalid date format: $dateString');
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _filterOrdersBySingleDate() {
    if (selectedDate != null) {
      setState(() {
        expensedata = originalExpensedata.where((order) {
          final orderDate = _parseDate(order['expense_date']);
          final normalizedOrderDate = _normalizeDate(orderDate);
          final normalizedSelectedDate = _normalizeDate(selectedDate!);

          return normalizedOrderDate == normalizedSelectedDate;
        }).toList();

        totalExp = expensedata.fold<double>(0.0, (sum, order) {
          final amount = double.tryParse(order['amount'].toString()) ?? 0.0;
          return sum + amount;
        });
      });
    }
  }

  Future<void> _filterOrdersByDateRange() async {
    if (startDate != null && endDate != null) {
      try {
        final token = await gettokenFromPrefs();

        setState(() {
          isLoading = true;
        });

        final String start = DateFormat('yyyy-MM-dd').format(startDate!);
        final String end = DateFormat('yyyy-MM-dd').format(endDate!);

        final uri = Uri.parse('$api/api/expense/get/data/filter/').replace(
          queryParameters: {
            'expense_type': widget.type,
            'start_date': start,
            'end_date': end,
            'ordering': '-id',
          },
        );

        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        List<Map<String, dynamic>> expenselist = [];
        double totalExpense = 0.0;

        if (response.statusCode == 200) {
          final parsed = jsonDecode(response.body);
          final results = parsed['results'] ?? [];
          final summary = parsed['summary'] ?? {};

          for (var productData in results) {
            final double amount =
                double.tryParse(productData['amount'].toString()) ?? 0.0;

            expenselist.add({
              'id': productData['id'],
              'purpose_of_payment': productData['purpose_of_payment'],
              'purpose_of_pay': productData['purpose_of_pay'],
              'bank': productData['bank']?['id'],
              'bank_name': productData['bank']?['name'],
              'amount': amount,
              'company': productData['company']?['id'],
              'company_name': productData['company']?['name'],
              'payed_by': productData['payed_by']?['id'],
              'payed_by_name': productData['payed_by']?['name'],
              'transaction_id': productData['transaction_id'],
              'expense_date': productData['expense_date'],
              'added_by': productData['added_by'],
              'asset_types': productData['asset_types'],
              'name': productData['name'],
              'loanname': productData['loanname'],
              'expense_type': productData['expense_type'],
              'categoryname': productData['categoryname'],
              'description': productData['description'],
              'purpose_id': productData['purpose_id'],
              'company_id': productData['company_id'],
              'bank_id': productData['bank_id'],
              'category_id': productData['category_id'],
            });
          }

          totalExpense =
              double.tryParse(summary['total_amount']?.toString() ?? '0') ??
                  0.0;

          setState(() {
            expensedata = expenselist;
            originalExpensedata = List.from(expenselist);
            totalExp = totalExpense;
            isLoading = false;
          });
        } else {
          setState(() {
            expensedata = [];
            originalExpensedata = [];
            totalExp = 0.0;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          expensedata = [];
          originalExpensedata = [];
          totalExp = 0.0;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSingleDate(BuildContext context) async {
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
        selectedDate = null;
      });
      await _filterOrdersByDateRange();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedDate = null;
      startDate = DateTime.tryParse(widget.fromDate);
      endDate = DateTime.tryParse(widget.toDate);
    });
    getexpenselist();
  }

  Future<void> _navigateBack() async {
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
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
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
  }

  String _formatDateDisplay(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _formatRangeText() {
    final from = _getEffectiveStartDate();
    final to = _getEffectiveEndDate();

    if (from.isEmpty || to.isEmpty) return "All Dates";

    try {
      final fromDate = DateTime.parse(from);
      final toDate = DateTime.parse(to);
      return "${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}";
    } catch (_) {
      return "$from - $to";
    }
  }

  Widget _buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF2E86DE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Text(
          //   "Expense Overview",
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 17,
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
          const SizedBox(height: 6),
          Text(
            widget.type.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 14),
          
          Row(
            children: [
              Expanded(
                child: _summaryMiniCard(
                  // icon: Icons.calendar_month_rounded,
                  title: "Date Range",
                  value: _formatRangeText(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMiniCard(
                  // icon: Icons.account_balance_wallet_rounded,
                  title: "Grand Total",
                  value: currencyFormat.format(totalExp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMiniCard({
    // required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _actionChip(
            icon: Icons.date_range_rounded,
            label: "Date Range",
            onTap: () => _selectDateRange(context),
          ),
          _actionChip(
            icon: Icons.today_rounded,
            label: "Single Date",
            onTap: () => _selectSingleDate(context),
          ),
          _actionChip(
            icon: Icons.refresh_rounded,
            label: "Reset",
            onTap: _clearFilters,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              "${expensedata.length} Records",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F4C81)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F4C81),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;

    final String purpose = (expense['purpose_of_pay'] ?? '-').toString();
    final String loanOrName =
        (expense['loanname']?.toString().isNotEmpty == true
                ? expense['loanname']
                : (expense['name'] ?? '-'))
            .toString();
    final String category = (expense['expense_type'] ?? '-').toString();
    final String date = _formatDateDisplay(expense['expense_date']?.toString());
    final String companyName = (expense['company_name'] ?? '-').toString();
    final String paidBy = (expense['payed_by_name'] ?? '-').toString();
    final String bankName = (expense['bank_name'] ?? '-').toString();
    final String description = (expense['description'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: const Color(0xFF0F4C81),
        collapsedIconColor: const Color(0xFF0F4C81),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Colors.blue.shade800,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purpose,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loanOrName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _smallBadge(
                icon: Icons.category_rounded,
                text: category,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              if (bankName != "-")
                Expanded(
                  child: _smallBadge(
                    icon: Icons.account_balance_rounded,
                    text: bankName,
                    color: Colors.indigo,
                  ),
                ),
            ],
          ),
        ),
        children: [
          const Divider(height: 16),
          _detailRow("Company", companyName),
          _detailRow("Paid By", paidBy),
          _detailRow("Bank", bankName),
          _detailRow("Expense Type", category),
          _detailRow("Date", date),
          _detailRow("Amount", currencyFormat.format(amount)),
          if (description.isNotEmpty) _detailRow("Description", description),
        ],
      ),
    );
  }

  Widget _smallBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ":  ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              "No expenses found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try changing the selected date range or reset filters.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F4C81)),
            onPressed: () async {
              await _navigateBack();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Expense Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.today_rounded, color: Color(0xFF0F4C81)),
              onPressed: () => _selectSingleDate(context),
            ),
            IconButton(
              icon: const Icon(Icons.date_range_rounded,
                  color: Color(0xFF0F4C81)),
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: getexpenselist,
                  child: ListView(
                    children: [
                      _buildTopSummaryCard(),
                      // _buildActionBar(),

                      if (expensedata.isEmpty)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        )
                      else
                        ...expensedata
                            .map((e) => _buildExpenseCard(e))
                            .toList(),

                      const SizedBox(height: 80), // bottom spacing
                    ],
                  ),
                ),
        ),
        // bottomNavigationBar: Container(
        //   height: 66,
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     border: Border(
        //       top: BorderSide(color: Colors.grey.shade300),
        //     ),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.04),
        //         blurRadius: 10,
        //         offset: const Offset(0, -2),
        //       ),
        //     ],
        //   ),
        //   // child: Row(
        //   //   children: [
        //   //     Container(
        //   //       height: 42,
        //   //       width: 42,
        //   //       decoration: BoxDecoration(
        //   //         color: Colors.green.withOpacity(0.08),
        //   //         borderRadius: BorderRadius.circular(12),
        //   //       ),
        //   //       child: const Icon(
        //   //         Icons.account_balance_wallet_rounded,
        //   //         color: Colors.green,
        //   //         size: 22,
        //   //       ),
        //   //     ),
        //   //     const SizedBox(width: 12),
        //   //     // const Expanded(
        //   //     //   child: Text(
        //   //     //     "Grand Total",
        //   //     //     style: TextStyle(
        //   //     //       fontWeight: FontWeight.w700,
        //   //     //       fontSize: 14,
        //   //     //       color: Color(0xFF1A1A1A),
        //   //     //     ),
        //   //     //   ),
        //   //     // ),
        //   //     // Text(
        //   //     //   currencyFormat.format(totalExp),
        //   //     //   style: const TextStyle(
        //   //     //     fontWeight: FontWeight.w800,
        //   //     //     fontSize: 16,
        //   //     //     color: Colors.green,
        //   //     //   ),
        //   //     // ),
        //   //   ],
        //   // ),
        // ),
      ),
    );
  }

  String getNameById(List<Map<String, dynamic>> dataList, dynamic id) {
    if (id == null || dataList.isEmpty) return 'Unknown';

    if (id is Map<String, dynamic>) {
      return id['name'] ?? 'Unknown';
    }

    final item = dataList.firstWhere(
      (element) => element['id'] == id,
      orElse: () => {},
    );
    return item.isNotEmpty ? item['name'] : 'Unknown';
  }
}
