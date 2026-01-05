import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/excel_export_service.dart';
import '../../../injection_container.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_partner_repository.dart';
import 'bloc/invoice_history_bloc.dart';
import 'bloc/invoice_history_event.dart';
import 'bloc/invoice_history_state.dart';
import 'invoice_detail_screen.dart';

/// Theme class cho Invoice History Screen
class _HistoryTheme {
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tab colors
  static const tabColors = [
    Color(0xFF11998e), // Nhập kho - green
    Color(0xFFf5576c), // Xuất kho - red
    Color(0xFF667eea), // Xuất chợ - purple
    Color(0xFF4facfe), // Nhập chợ - blue
  ];

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: const Color(0xFF667eea))
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Colors.grey.shade600),
    );
  }
}

class InvoiceHistoryScreen extends StatelessWidget {
  final int invoiceType;

  const InvoiceHistoryScreen({super.key, required this.invoiceType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvoiceHistoryBloc>()..add(LoadInvoices(invoiceType)),
      child: const _InvoiceHistoryView(),
    );
  }
}

class _InvoiceHistoryView extends StatefulWidget {
  const _InvoiceHistoryView();

  @override
  State<_InvoiceHistoryView> createState() => _InvoiceHistoryViewState();
}

class _InvoiceHistoryViewState extends State<_InvoiceHistoryView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _pigTypeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _customerController = TextEditingController();
  final _minWeightController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  int? _daysFilter; // null = tất cả
  Timer? _debounce;
  bool _showAdvancedFilters = false;
  int _selectedType = 2; // Mặc định Xuất chợ

  // Animation
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Data lists for suggestions
  List<PigTypeEntity> _pigTypes = [];
  List<PartnerEntity> _partners = [];
  Set<String> _batchNumbers = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
    _loadSuggestionData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pigTypeController.dispose();
    _batchNumberController.dispose();
    _customerController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _debounce?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  /// Load data for autocomplete suggestions
  Future<void> _loadSuggestionData() async {
    // Load pig types
    sl<IPigTypeRepository>().watchPigTypes().listen((types) {
      if (mounted) {
        setState(() => _pigTypes = types);
      }
    });

    // Load partners (both suppliers and customers)
    sl<IPartnerRepository>().watchPartners(false).listen((customers) {
      if (mounted) {
        setState(() => _partners = customers);
      }
    });

    // Load batch numbers from existing invoices
    _loadBatchNumbers();
  }

  Future<void> _loadBatchNumbers() async {
    final repo = sl<IInvoiceRepository>();
    final batches = <String>{};

    for (int type = 0; type <= 3; type++) {
      final invoices = await repo.watchInvoices(type: type).first;
      for (final inv in invoices) {
        for (final detail in inv.details) {
          if (detail.batchNumber != null && detail.batchNumber!.isNotEmpty) {
            batches.add(detail.batchNumber!);
          }
        }
        // Also parse from note
        final noteLines = (inv.note ?? '').split('|');
        for (final line in noteLines) {
          if (line.trim().startsWith('Số lô:')) {
            final batch = line.trim().substring(6).trim();
            if (batch.isNotEmpty) batches.add(batch);
          }
        }
      }
    }

    if (mounted) {
      setState(() => _batchNumbers = batches);
    }
  }

  // Áp dụng bộ lọc ngay lập tức (không debounce)
  void _applyFilter() {
    context.read<InvoiceHistoryBloc>().add(
          FilterInvoices(
            keyword: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            daysFilter: _daysFilter,
            pigType: _pigTypeController.text.trim().isEmpty
                ? null
                : _pigTypeController.text.trim(),
            batchNumber: _batchNumberController.text.trim().isEmpty
                ? null
                : _batchNumberController.text.trim(),
            minWeight: _minWeightController.text.trim().isEmpty
                ? null
                : double.tryParse(_minWeightController.text.trim()),
            maxWeight: _maxWeightController.text.trim().isEmpty
                ? null
                : double.tryParse(_maxWeightController.text.trim()),
            minAmount: _minAmountController.text.trim().isEmpty
                ? null
                : double.tryParse(_minAmountController.text.trim()),
            maxAmount: _maxAmountController.text.trim().isEmpty
                ? null
                : double.tryParse(_maxAmountController.text.trim()),
          ),
        );
  }

  // Gửi event lọc xuống Bloc với debounce (tự động)
  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilter();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _pigTypeController.clear();
      _batchNumberController.clear();
      _customerController.clear();
      _minWeightController.clear();
      _maxWeightController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _daysFilter = null;
    });
    _applyFilter(); // Áp dụng ngay sau khi xóa
  }

  Future<void> _exportExcel(BuildContext context) async {
    final state = context.read<InvoiceHistoryBloc>().state;

    if (state.invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất')),
      );
      return;
    }

    try {
      await ExcelExportService.exportInvoicesToExcel(state.invoices);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xuất Excel')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(context),
          // Tabs chọn loại phiếu
          _buildModernTabs(),
          // Filter section
          _buildModernFilterSection(context),
          if (_showAdvancedFilters) _buildModernAdvancedFilters(context),
          // Content
          Expanded(
            child: _fadeAnimation != null
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _buildContent(context),
                  )
                : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<InvoiceHistoryBloc, InvoiceHistoryState>(
      builder: (context, state) {
        if (state.status == HistoryStatus.loading) {
          return _buildLoadingState();
        }
        if (state.status == HistoryStatus.failure) {
          return _buildErrorState(state.errorMessage);
        }
        if (state.invoices.isEmpty) {
          return _buildEmptyState();
        }
        return _buildModernList(context, state.invoices);
      },
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        gradient: _HistoryTheme.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch sử phiếu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Quản lý và tra cứu phiếu nhập xuất',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            _buildHeaderButton(
              icon: Icons.filter_alt,
              tooltip: 'Bộ lọc nâng cao',
              isActive: _showAdvancedFilters,
              onPressed: () {
                setState(() => _showAdvancedFilters = !_showAdvancedFilters);
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.clear_all,
              tooltip: 'Xóa bộ lọc',
              onPressed: _clearAllFilters,
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.download,
              tooltip: 'Xuất Excel',
              onPressed: () => _exportExcel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildModernTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModernTab(0, 'Nhập kho', Icons.input),
          _buildModernTab(1, 'Xuất kho', Icons.outbox),
          _buildModernTab(2, 'Xuất chợ', Icons.storefront),
          _buildModernTab(3, 'Nhập chợ', Icons.shopping_basket),
        ],
      ),
    );
  }

  Widget _buildModernTab(int type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final color = _HistoryTheme.tabColors[type];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedType = type);
          context.read<InvoiceHistoryBloc>().add(LoadInvoices(type));
          _animationController?.reset();
          _animationController?.forward();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _HistoryTheme.cardDecoration,
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: _HistoryTheme.inputDecoration(
                labelText: 'Tìm kiếm',
                hintText: 'Nhập mã phiếu hoặc tên khách hàng...',
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onFilterChanged();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _onFilterChanged(),
            ),
          ),
          const SizedBox(width: 16),
          // Time filter
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _daysFilter,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600),
                  hint: Text('Thời gian',
                      style: TextStyle(color: Colors.grey.shade600)),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive,
                              size: 18, color: Color(0xFF667eea)),
                          SizedBox(width: 8),
                          Text('Tất cả'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.today, size: 18, color: Color(0xFF667eea)),
                          SizedBox(width: 8),
                          Text('Hôm nay'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 7,
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              size: 18, color: Color(0xFF667eea)),
                          SizedBox(width: 8),
                          Text('7 ngày qua'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month,
                              size: 18, color: Color(0xFF667eea)),
                          SizedBox(width: 8),
                          Text('30 ngày qua'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _daysFilter = value);
                    _onFilterChanged();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Active filters count
          if (_hasActiveFilters())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list,
                      size: 16, color: Color(0xFF667eea)),
                  const SizedBox(width: 4),
                  Text(
                    '${_countActiveFilters()} bộ lọc',
                    style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _daysFilter != null ||
        _pigTypeController.text.isNotEmpty ||
        _batchNumberController.text.isNotEmpty ||
        _customerController.text.isNotEmpty ||
        _minWeightController.text.isNotEmpty ||
        _maxWeightController.text.isNotEmpty ||
        _minAmountController.text.isNotEmpty ||
        _maxAmountController.text.isNotEmpty;
  }

  int _countActiveFilters() {
    int count = 0;
    if (_searchController.text.isNotEmpty) {
      count++;
    }
    if (_daysFilter != null) {
      count++;
    }
    if (_pigTypeController.text.isNotEmpty) {
      count++;
    }
    if (_batchNumberController.text.isNotEmpty) {
      count++;
    }
    if (_customerController.text.isNotEmpty) {
      count++;
    }
    if (_minWeightController.text.isNotEmpty ||
        _maxWeightController.text.isNotEmpty) {
      count++;
    }
    if (_minAmountController.text.isNotEmpty ||
        _maxAmountController.text.isNotEmpty) {
      count++;
    }
    return count;
  }

  Widget _buildModernAdvancedFilters(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.05),
            const Color(0xFF764ba2).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  size: 20,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bộ lọc nâng cao',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF667eea),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Đặt lại'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 1: Loại heo + Số lô + Khách hàng
          Row(
            children: [
              Expanded(child: _buildPigTypeAutocomplete()),
              const SizedBox(width: 12),
              Expanded(child: _buildBatchNumberAutocomplete()),
              const SizedBox(width: 12),
              Expanded(child: _buildCustomerAutocomplete()),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Khối lượng + Giá trị
          Row(
            children: [
              Expanded(
                child: _buildRangeFilter(
                  label: 'Khối lượng (kg)',
                  icon: Icons.scale,
                  minController: _minWeightController,
                  maxController: _maxWeightController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRangeFilter(
                  label: 'Giá trị (đ)',
                  icon: Icons.attach_money,
                  minController: _minAmountController,
                  maxController: _maxAmountController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAdvancedFilters = false),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Đóng'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Tìm kiếm'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Autocomplete for pig type
  Widget _buildPigTypeAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _pigTypes.map((e) => e.name);
        }
        return _pigTypes.map((e) => e.name).where((name) =>
            name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _pigTypeController.text = selection;
        _onFilterChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our controller
        if (_pigTypeController.text.isNotEmpty &&
            controller.text != _pigTypeController.text) {
          controller.text = _pigTypeController.text;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _HistoryTheme.inputDecoration(
            labelText: 'Loại heo',
            hintText: 'VD: Nái, Thịt...',
            prefixIcon: Icons.pets,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      _pigTypeController.clear();
                      _onFilterChanged();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _pigTypeController.text = value;
            _onFilterChanged();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions(options, onSelected, Icons.pets);
      },
    );
  }

  /// Autocomplete for batch number
  Widget _buildBatchNumberAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _batchNumbers.take(10);
        }
        return _batchNumbers.where((batch) =>
            batch.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _batchNumberController.text = selection;
        _onFilterChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (_batchNumberController.text.isNotEmpty &&
            controller.text != _batchNumberController.text) {
          controller.text = _batchNumberController.text;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _HistoryTheme.inputDecoration(
            labelText: 'Số lô',
            hintText: 'VD: LOT001...',
            prefixIcon: Icons.qr_code,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      _batchNumberController.clear();
                      _onFilterChanged();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _batchNumberController.text = value;
            _onFilterChanged();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions(options, onSelected, Icons.qr_code);
      },
    );
  }

  /// Autocomplete for customer name
  Widget _buildCustomerAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final names = _partners.map((e) => e.name);
        if (textEditingValue.text.isEmpty) {
          return names.take(10);
        }
        return names.where((name) =>
            name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _customerController.text = selection;
        _searchController.text = selection;
        _onFilterChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (_customerController.text.isNotEmpty &&
            controller.text != _customerController.text) {
          controller.text = _customerController.text;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _HistoryTheme.inputDecoration(
            labelText: 'Khách hàng',
            hintText: 'Tên khách hàng...',
            prefixIcon: Icons.person,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      _customerController.clear();
                      _onFilterChanged();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _customerController.text = value;
            _onFilterChanged();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions(options, onSelected, Icons.person);
      },
    );
  }

  Widget _buildAutocompleteOptions(
    Iterable<String> options,
    void Function(String) onSelected,
    IconData icon,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                dense: true,
                leading: Icon(icon, size: 20, color: const Color(0xFF667eea)),
                title: Text(option),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hoverColor: const Color(0xFF667eea).withValues(alpha: 0.1),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRangeFilter({
    required String label,
    required IconData icon,
    required TextEditingController minController,
    required TextEditingController maxController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF667eea)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Từ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => _onFilterChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
            ),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Đến',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => _onFilterChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Loading, Error, Empty states
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Không xác định',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<InvoiceHistoryBloc>()
                  .add(LoadInvoices(_selectedType));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Không tìm thấy phiếu nào',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tạo phiếu mới',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Xóa bộ lọc'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF667eea),
                side: const BorderSide(color: Color(0xFF667eea)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernList(BuildContext context, List<InvoiceEntity> invoices) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: _HistoryTheme.cardDecoration,
      child: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${invoices.length} phiếu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                _buildSummaryChip(
                  'Tổng KL',
                  '${_formatNumber(invoices.fold<double>(0, (sum, inv) => sum + inv.details.fold<double>(0, (s, d) => s + d.weight)))} kg',
                  Icons.scale,
                  const Color(0xFF11998e),
                ),
                const SizedBox(width: 12),
                _buildSummaryChip(
                  'Tổng tiền',
                  currencyFormat.format(invoices.fold<double>(
                      0, (sum, inv) => sum + inv.finalAmount)),
                  Icons.attach_money,
                  const Color(0xFFf5576c),
                ),
              ],
            ),
          ),
          // Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.grey.shade200,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 52,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 72,
                  headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF667eea).withValues(alpha: 0.05)),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF667eea),
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                  columns: const [
                    DataColumn(label: Text('Mã phiếu')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Ngày tạo')),
                    DataColumn(label: Text('Loại heo')),
                    DataColumn(label: Text('Số lô')),
                    DataColumn(label: Text('Chuồng')),
                    DataColumn(label: Text('SL'), numeric: true),
                    DataColumn(label: Text('KL (kg)'), numeric: true),
                    DataColumn(label: Text('Đơn giá'), numeric: true),
                    DataColumn(label: Text('Thành tiền'), numeric: true),
                    DataColumn(label: Text('Ghi chú')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: invoices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final invoice = entry.value;
                    final isEven = index % 2 == 0;

                    // Extract details from first detail item or aggregate
                    final firstDetail = invoice.details.isNotEmpty
                        ? invoice.details.first
                        : null;

                    final totalQuantity = invoice.details
                        .fold<int>(0, (sum, item) => sum + item.quantity);
                    final totalWeight = invoice.details
                        .fold<double>(0, (sum, item) => sum + item.weight);

                    // Extract cage and batch from note
                    String cage = '';
                    String batch = '';
                    String note = invoice.note ?? '';

                    // Parse note for Chuồng and Số lô
                    final noteLines = note.split('|');
                    for (final line in noteLines) {
                      final trimmed = line.trim();
                      if (trimmed.startsWith('Chuồng:')) {
                        cage = trimmed.substring(7).trim();
                      } else if (trimmed.startsWith('Số lô:')) {
                        batch = trimmed.substring(6).trim();
                      }
                    }

                    // If batch not in note, try from detail
                    if (batch.isEmpty && firstDetail?.batchNumber != null) {
                      batch = firstDetail!.batchNumber!;
                    }

                    // Clean note (remove parsed fields)
                    String cleanNote = noteLines
                        .where((line) =>
                            !line.trim().startsWith('Chuồng:') &&
                            !line.trim().startsWith('Số lô:') &&
                            !line.trim().startsWith('Trại:') &&
                            !line.trim().startsWith('Lý do:'))
                        .join(' | ')
                        .trim();

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return const Color(0xFF667eea)
                                .withValues(alpha: 0.05);
                          }
                          return isEven
                              ? Colors.white
                              : const Color(0xFFFAFAFA);
                        },
                      ),
                      cells: [
                        // Mã phiếu
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _HistoryTheme.tabColors[_selectedType]
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'INV${invoice.id.toString().padLeft(5, '0')}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _HistoryTheme.tabColors[_selectedType],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        // Khách hàng
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF667eea)
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  (invoice.partnerName ?? 'K')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  invoice.partnerName ?? 'Khách lẻ',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Ngày tạo
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(invoice.createdDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                DateFormat('HH:mm').format(invoice.createdDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Loại heo
                        DataCell(
                          firstDetail?.pigType != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Text(
                                    firstDetail!.pigType!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                )
                              : Text('-',
                                  style:
                                      TextStyle(color: Colors.grey.shade400)),
                        ),
                        // Số lô
                        DataCell(
                          batch.isNotEmpty
                              ? Text(batch,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))
                              : Text('-',
                                  style:
                                      TextStyle(color: Colors.grey.shade400)),
                        ),
                        // Chuồng
                        DataCell(
                          cage.isNotEmpty
                              ? Text(cage)
                              : Text('-',
                                  style:
                                      TextStyle(color: Colors.grey.shade400)),
                        ),
                        // Số lượng
                        DataCell(
                          Text(
                            totalQuantity.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Khối lượng
                        DataCell(
                          Text(
                            totalWeight.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Đơn giá
                        DataCell(
                          Text(
                            invoice.pricePerKg > 0
                                ? currencyFormat.format(invoice.pricePerKg)
                                : '-',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        // Thành tiền
                        DataCell(
                          Text(
                            currencyFormat.format(invoice.finalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        // Ghi chú
                        DataCell(
                          Tooltip(
                            message: cleanNote.isNotEmpty
                                ? cleanNote
                                : 'Không có ghi chú',
                            child: SizedBox(
                              width: 100,
                              child: Text(
                                cleanNote.isNotEmpty ? cleanNote : '-',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Thao tác
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionButton(
                                icon: Icons.visibility,
                                tooltip: 'Chi tiết',
                                color: const Color(0xFF667eea),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceDetailScreen(
                                        invoiceId: invoice.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                icon: Icons.delete_outline,
                                tooltip: 'Xóa',
                                color: Colors.red.shade400,
                                onPressed: () =>
                                    _confirmAndDelete(context, invoice),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, InvoiceEntity invoice) async {
    // If it's an import invoice (type 0), check if deletion would cause negative inventory
    if (invoice.type == 0) {
      final canDelete = await _canDeleteImportInvoice(invoice);
      if (!canDelete) {
        if (context.mounted) {
          String pigTypes =
              invoice.details.map((d) => d.pigType ?? 'N/A').toSet().join(', ');
          _showModernSnackBar(
            context,
            message:
                'Không thể xóa phiếu! Loại heo "$pigTypes" sẽ bị âm tồn kho nếu xóa phiếu này.',
            isError: true,
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline,
                  color: Colors.red.shade400, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa phiếu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xóa phiếu này?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      'Khách hàng', invoice.partnerName ?? 'Khách lẻ'),
                  _buildInfoRow(
                      'Ngày tạo',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(invoice.createdDate)),
                  _buildInfoRow('Mã phiếu',
                      'INV${invoice.id.toString().padLeft(5, '0')}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (result == true) {
      await sl<IInvoiceRepository>().deleteInvoice(invoice.id);
      if (context.mounted) {
        _showModernSnackBar(context, message: 'Đã xóa phiếu thành công');
        // Reload data
        context.read<InvoiceHistoryBloc>().add(LoadInvoices(_selectedType));
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showModernSnackBar(BuildContext context,
      {required String message, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade500 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Check if deleting an import invoice would cause negative inventory
  Future<bool> _canDeleteImportInvoice(InvoiceEntity invoice) async {
    try {
      final repo = sl<IInvoiceRepository>();
      final importInvoices = await repo.watchInvoices(type: 0).first;
      final exportInvoices = await repo.watchInvoices(type: 2).first;

      // Get pig types and quantities from this invoice
      Map<String, int> invoicePigTypes = {};
      for (final item in invoice.details) {
        final pigType = (item.pigType ?? '').trim();
        if (pigType.isNotEmpty) {
          invoicePigTypes[pigType] =
              (invoicePigTypes[pigType] ?? 0) + item.quantity;
        }
      }

      // Calculate current inventory for each pig type
      for (final pigType in invoicePigTypes.keys) {
        int imported = 0;
        int exported = 0;

        for (final inv in importInvoices) {
          // Skip the invoice we're trying to delete
          if (inv.id == invoice.id) continue;
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType) {
              imported += item.quantity;
            }
          }
        }

        for (final inv in exportInvoices) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType) {
              exported += item.quantity;
            }
          }
        }

        // If deleting this invoice would make inventory negative
        final remainingInventory = imported - exported;
        if (remainingInventory < 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
