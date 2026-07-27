
import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MainCategoryManagementPage extends StatefulWidget {
  const MainCategoryManagementPage({super.key});

  @override
  State<MainCategoryManagementPage> createState() =>
      _MainCategoryManagementPageState();
}

class _MainCategoryManagementPageState
    extends State<MainCategoryManagementPage> {
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _backgroundColor = Color(0xFFF5F7FB);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _formSectionKey = GlobalKey();

  List<MainCategoryItem> _categories = <MainCategoryItem>[];
  List<MainCategoryItem> _filteredCategories = <MainCategoryItem>[];

  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isSubmitting = false;

  int? _editingCategoryId;
  String _searchQuery = '';

  Timer? _searchDebounce;

  bool get _isEditing => _editingCategoryId != null;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    return preferences.getString('token');
  }

  Map<String, String> _jsonHeaders(String token) {
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  String _buildApiUrl(String path) {
    final String normalizedBase =
        api.endsWith('/') ? api.substring(0, api.length - 1) : api;

    final String normalizedPath =
        path.startsWith('/') ? path.substring(1) : path;

    return '$normalizedBase/$normalizedPath';
  }

  Future<void> _fetchCategories({
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      if (_isRefreshing) return;

      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isInitialLoading = true;
      });
    }

    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        _showMessage(
          'Authentication token is missing. Please log in again.',
          isError: true,
        );
        return;
      }

      final Uri uri = Uri.parse(
        _buildApiUrl('api/main/categories/add/'),
      );

      final http.Response response = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(
            response,
            fallback: 'Unable to load categories',
          ),
          statusCode: response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      final List<dynamic> rawItems = _extractCategoryList(decoded);

      final List<MainCategoryItem> parsedCategories = rawItems
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                MainCategoryItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (MainCategoryItem item) =>
                item.id != null && item.name.trim().isNotEmpty,
          )
          .toList()
        ..sort(
          (MainCategoryItem a, MainCategoryItem b) =>
              a.name.toLowerCase().compareTo(
                    b.name.toLowerCase(),
                  ),
        );

      if (!mounted) return;

      setState(() {
        _categories = parsedCategories;
        _applySearchFilter();
      });
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } on FormatException {
      _showMessage(
        'The server returned an invalid response.',
        isError: true,
      );
    } catch (error) {
      debugPrint('FETCH MAIN CATEGORIES ERROR: $error');

      _showMessage(
        'Something went wrong while loading categories.',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isInitialLoading = false;
        _isRefreshing = false;
      });
    }
  }

  List<dynamic> _extractCategoryList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is! Map) {
      return <dynamic>[];
    }

    final dynamic results = decoded['results'];
    final dynamic data = decoded['data'];
    final dynamic categories = decoded['categories'];

    if (results is List) {
      return results;
    }

    if (results is Map) {
      final dynamic nestedResults =
          results['results'] ?? results['data'] ?? results['categories'];

      if (nestedResults is List) {
        return nestedResults;
      }
    }

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final dynamic nestedData =
          data['results'] ?? data['data'] ?? data['categories'];

      if (nestedData is List) {
        return nestedData;
      }
    }

    if (categories is List) {
      return categories;
    }

    return <dynamic>[];
  }

  Future<void> _submitCategory() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    final FormState? formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final String normalizedName = _normalizeCategoryName(
      _nameController.text,
    );

    final bool duplicateExists = _categories.any(
      (MainCategoryItem category) =>
          category.name.trim().toLowerCase() ==
              normalizedName.toLowerCase() &&
          category.id != _editingCategoryId,
    );

    if (duplicateExists) {
      _showMessage(
        'A category with this name already exists.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        _showMessage(
          'Authentication token is missing. Please log in again.',
          isError: true,
        );
        return;
      }

      final Map<String, dynamic> requestBody = <String, dynamic>{
        'name': normalizedName,
      };

      late final http.Response response;

      if (_isEditing) {
        final int categoryId = _editingCategoryId!;

        response = await http.put(
          Uri.parse(
            _buildApiUrl(
              'api/main/categories/edit/$categoryId/',
            ),
          ),
          headers: _jsonHeaders(token),
          body: jsonEncode(requestBody),
        );
      } else {
        response = await http.post(
          Uri.parse(
            _buildApiUrl('api/main/categories/add/'),
          ),
          headers: _jsonHeaders(token),
          body: jsonEncode(requestBody),
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(
            response,
            fallback: _isEditing
                ? 'Unable to update category'
                : 'Unable to create category',
          ),
          statusCode: response.statusCode,
        );
      }

      final bool wasEditing = _isEditing;

      _resetForm();

      await _fetchCategories();

      _showMessage(
        wasEditing
            ? 'Category updated successfully'
            : 'Category created successfully',
      );
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } on FormatException {
      _showMessage(
        'The server returned an invalid response.',
        isError: true,
      );
    } catch (error) {
      debugPrint('SUBMIT MAIN CATEGORY ERROR: $error');

      _showMessage(
        _isEditing
            ? 'Something went wrong while updating the category.'
            : 'Something went wrong while creating the category.',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _normalizeCategoryName(String input) {
    return input
        .trim()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  void _startEditing(MainCategoryItem category) {
    setState(() {
      _editingCategoryId = category.id;
      _nameController.text = category.name;
    });

    _nameController.selection = TextSelection.fromPosition(
      TextPosition(
        offset: _nameController.text.length,
      ),
    );

    _nameFocusNode.requestFocus();

    final BuildContext? formSectionContext =
        _formSectionKey.currentContext;

    if (formSectionContext != null) {
      Scrollable.ensureVisible(
        formSectionContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();

    setState(() {
      _editingCategoryId = null;
      _nameController.clear();
    });

    _formKey.currentState?.reset();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () {
        if (!mounted) return;

        setState(() {
          _searchQuery = value.trim().toLowerCase();
          _applySearchFilter();
        });
      },
    );
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCategories =
          List<MainCategoryItem>.from(_categories);
      return;
    }

    _filteredCategories = _categories.where(
      (MainCategoryItem category) {
        return category.name.toLowerCase().contains(
              _searchQuery,
            );
      },
    ).toList();
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _applySearchFilter();
    });
  }

  String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final dynamic directMessage =
            decoded['message'] ??
            decoded['detail'] ??
            decoded['error'] ??
            decoded['non_field_errors'];

        final String? message = _stringifyApiError(
          directMessage,
        );

        if (message != null && message.trim().isNotEmpty) {
          return message;
        }

        final List<String> fieldErrors = <String>[];

        for (final MapEntry<dynamic, dynamic> entry
            in decoded.entries) {
          final String? value = _stringifyApiError(
            entry.value,
          );

          if (value != null && value.trim().isNotEmpty) {
            fieldErrors.add('${entry.key}: $value');
          }
        }

        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join('\n');
        }
      }

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.join(', ');
      }
    } catch (_) {
      final String body = response.body.trim();

      if (body.isNotEmpty && body.length <= 300) {
        return body;
      }
    }

    return '$fallback (${response.statusCode})';
  }

  String? _stringifyApiError(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return value;
    }

    if (value is List) {
      return value.map((dynamic item) => item.toString()).join(', ');
    }

    if (value is Map) {
      return value.entries
          .map(
            (MapEntry<dynamic, dynamic> entry) =>
                '${entry.key}: ${entry.value}',
          )
          .join(', ');
    }

    return value.toString();
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Main Categories',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryColor,
          onRefresh: () => _fetchCategories(isRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  14,
                ),
                // sliver: SliverToBoxAdapter(
                //   child: _buildHeroCard(),
                // ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildCategoryForm(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchAndSummary(),
                ),
              ),
              if (_isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _primaryColor,
                    ),
                  ),
                )
              else if (_filteredCategories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _filteredCategories.length,
                    separatorBuilder:
                        (BuildContext context, int index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder:
                        (BuildContext context, int index) {
                      final MainCategoryItem category =
                          _filteredCategories[index];

                      return _buildCategoryCard(
                        category,
                        index,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Create and update main categories from one place.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_categories.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryForm() {
    return Container(
      key: _formSectionKey,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isEditing
              ? _primaryColor.withOpacity(0.40)
              : _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.add_rounded,
                    color: _isEditing
                        ? const Color(0xFFF97316)
                        : _primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing
                            ? 'Edit Category'
                            : 'Add New Category',
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEditing
                            ? 'Update the selected category name.'
                            : 'Enter a unique main category name.',
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Cancel editing',
                    onPressed:
                        _isSubmitting ? null : _resetForm,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _mutedTextColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              enabled: !_isSubmitting,
              maxLength: 120,
              onFieldSubmitted: (_) => _submitCategory(),
              validator: (String? value) {
                final String normalized =
                    _normalizeCategoryName(value ?? '');

                if (normalized.isEmpty) {
                  return 'Category name is required';
                }

                if (normalized.length < 2) {
                  return 'Category name must contain at least 2 characters';
                }

                if (normalized.length > 120) {
                  return 'Category name cannot exceed 120 characters';
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: 'Category name',
                hintText: 'Example: Electronics',
                counterText: '',
                prefixIcon: const Icon(
                  Icons.label_outline_rounded,
                ),
                suffixIcon: _nameController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                _nameController.clear();
                                setState(() {});
                              },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSubmitting ? null : _resetForm,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(50),
                        foregroundColor: _mutedTextColor,
                        side: const BorderSide(
                          color: _borderColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSubmitting ? null : _submitCategory,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isEditing
                                ? Icons.save_rounded
                                : Icons.add_rounded,
                          ),
                    label: Text(
                      _isSubmitting
                          ? (_isEditing
                              ? 'Updating...'
                              : 'Creating...')
                          : (_isEditing
                              ? 'Update Category'
                              : 'Create Category'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(50),
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _primaryColor.withOpacity(0.55),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search categories',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip(
                icon: Icons.category_outlined,
                label: 'Total',
                value: _categories.length,
                background: const Color(0xFFEFF6FF),
                foreground: _primaryColor,
              ),
              const SizedBox(width: 10),
              _buildSummaryChip(
                icon: Icons.filter_list_rounded,
                label: 'Showing',
                value: _filteredCategories.length,
                background: const Color(0xFFECFDF5),
                foreground: const Color(0xFF059669),
              ),
              const Spacer(),
              if (_isRefreshing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required int value,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    MainCategoryItem category,
    int index,
  ) {
    final bool isCurrentEditing =
        _editingCategoryId == category.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () => _startEditing(category),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isCurrentEditing
                ? const Color(0xFFEFF6FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrentEditing
                  ? _primaryColor
                  : _borderColor,
              width: isCurrentEditing ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCurrentEditing
                      ? _primaryColor
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    category.name.trim().isNotEmpty
                        ? category.name
                            .trim()
                            .substring(0, 1)
                            .toUpperCase()
                        : '${index + 1}',
                    style: TextStyle(
                      color: isCurrentEditing
                          ? Colors.white
                          : _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category ID: ${category.id}',
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Edit category',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _startEditing(category),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFF97316),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        30,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 46,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.category_outlined
                    : Icons.search_off_rounded,
                color: _mutedTextColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No categories available'
                  : 'No matching categories',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first main category using the form above.'
                  : 'Try another search term or clear the current search.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(
                    color: _primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MainCategoryItem {
  const MainCategoryItem({
    required this.id,
    required this.name,
  });

  final int? id;
  final String name;

  factory MainCategoryItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawId = json['id'];

    return MainCategoryItem(
      id: rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? ''),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
  });

  final String message;
  final int statusCode;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message)';
  }
}
