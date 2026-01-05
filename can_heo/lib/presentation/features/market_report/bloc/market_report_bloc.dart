import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:drift/drift.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../data/local/database.dart';

part 'market_report_event.dart';
part 'market_report_state.dart';

class MarketReportBloc extends Bloc<MarketReportEvent, MarketReportState> {
  final IInvoiceRepository _invoiceRepository;
  final AppDatabase _db;

  MarketReportBloc({
    required IInvoiceRepository invoiceRepository,
    required AppDatabase db,
  })  : _invoiceRepository = invoiceRepository,
        _db = db,
        super(const MarketReportState()) {
    on<MarketReportSubscriptionRequested>(_onSubscriptionRequested);
    on<MarketReportDateRangeChanged>(_onDateRangeChanged);
    on<MarketReportRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onSubscriptionRequested(
    MarketReportSubscriptionRequested event,
    Emitter<MarketReportState> emit,
  ) async {
    emit(state.copyWith(status: MarketReportStatus.loading));

    await emit.forEach<List<InvoiceEntity>>(
      Rx.combineLatest2(
        _invoiceRepository.watchInvoices(type: 3), // Market Import
        _invoiceRepository.watchInvoices(type: 2), // Market Export
        (List<InvoiceEntity> imports, List<InvoiceEntity> exports) {
          return [...imports, ...exports];
        },
      ),
      onData: (invoices) {
        final imports = invoices.where((inv) => inv.type == 3).toList();
        final exports = invoices.where((inv) => inv.type == 2).toList();

        // Tính toán summaries
        final overviewSummary = _calculateOverviewSummary(imports, exports);

        return state.copyWith(
          status: MarketReportStatus.success,
          marketImports: imports,
          marketExports: exports,
          overviewSummary: overviewSummary,
        );
      },
      onError: (_, __) => state.copyWith(status: MarketReportStatus.failure),
    );
  }

  Future<void> _onDateRangeChanged(
    MarketReportDateRangeChanged event,
    Emitter<MarketReportState> emit,
  ) async {
    emit(state.copyWith(
      status: MarketReportStatus.loading,
      startDate: event.startDate,
      endDate: event.endDate,
    ));

    try {
      // Load transactions trong khoảng thời gian
      final transactions =
          await _loadTransactions(event.startDate, event.endDate);

      // Filter invoices theo date range
      final filteredImports = state.marketImports.where((inv) {
        return !inv.createdDate.isBefore(event.startDate) &&
            inv.createdDate.isBefore(event.endDate);
      }).toList();

      final filteredExports = state.marketExports.where((inv) {
        return !inv.createdDate.isBefore(event.startDate) &&
            inv.createdDate.isBefore(event.endDate);
      }).toList();

      // Tính toán các summary
      final overviewSummary =
          _calculateOverviewSummary(filteredImports, filteredExports);
      final costSummary = _calculateCostSummary(filteredImports, transactions);
      final debtSummary = _calculateDebtSummary(filteredImports, filteredExports, transactions);

      emit(state.copyWith(
        status: MarketReportStatus.success,
        transactions: transactions,
        overviewSummary: overviewSummary,
        costSummary: costSummary,
        debtSummary: debtSummary,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MarketReportStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    MarketReportRefreshRequested event,
    Emitter<MarketReportState> emit,
  ) async {
    if (state.startDate != null && state.endDate != null) {
      add(MarketReportDateRangeChanged(
        startDate: state.startDate!,
        endDate: state.endDate!,
      ));
    }
  }

  Future<List<TransactionEntity>> _loadTransactions(
      DateTime start, DateTime end) async {
    final transactionsList = await (_db.select(_db.transactions)
          ..where((t) => t.transactionDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();

    // Load partner names
    final List<TransactionEntity> result = [];
    for (final t in transactionsList) {
      String? partnerName;
      final partner = await _db.partnersDao.getPartnerById(t.partnerId);
      if (partner != null) {
        partnerName = partner.name;
      }

      result.add(TransactionEntity(
        id: t.id,
        partnerId: t.partnerId,
        partnerName: partnerName,
        amount: t.amount,
        type: t.type,
        paymentMethod: t.paymentMethod,
        date: t.transactionDate,
        note: t.note,
      ));
    }
    return result;
  }

  OverviewSummary _calculateOverviewSummary(
    List<InvoiceEntity> imports,
    List<InvoiceEntity> exports,
  ) {
    // Nhập hàng
    final importCount = imports.length;
    final importWeight =
        imports.fold<double>(0, (sum, inv) => sum + inv.totalWeight);
    final importAmount =
        imports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);

    // Bán hàng
    final exportCount = exports.length;
    final exportWeight =
        exports.fold<double>(0, (sum, inv) => sum + inv.totalWeight);
    final exportAmount =
        exports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);

    // Còn lại
    final remainingWeight = importWeight - exportWeight;
    final remainingAmount = importAmount - exportAmount;

    // Lợi nhuận = Tiền bán - Tiền nhập
    final profit = exportAmount - importAmount;

    return OverviewSummary(
      importCount: importCount,
      importWeight: importWeight,
      importAmount: importAmount,
      exportCount: exportCount,
      exportWeight: exportWeight,
      exportAmount: exportAmount,
      remainingWeight: remainingWeight,
      remainingAmount: remainingAmount,
      profit: profit,
    );
  }

  CostSummary _calculateCostSummary(
    List<InvoiceEntity> imports,
    List<TransactionEntity> transactions,
  ) {
    // Tính chi phí từ transactions có note chứa các keyword
    double otherCost = 0;
    double transportFee = 0;
    double rejectAmount = 0;
    String? otherCostNote;
    String? rejectNote;

    for (final t in transactions) {
      final note = t.note?.toLowerCase() ?? '';
      if (note.contains('cước') || note.contains('xe')) {
        transportFee += t.amount;
      } else if (note.contains('thải') ||
          note.contains('loại') ||
          note.contains('chết') ||
          note.contains('hôi')) {
        rejectAmount += t.amount;
        rejectNote = t.note;
      } else if (note.contains('chi phí') || note.contains('khác')) {
        otherCost += t.amount;
        otherCostNote = t.note;
      }
    }

    // Tính từ invoice notes nếu có thông tin chi phí trong ghi chú
    // (Hiện tại InvoiceEntity chưa có trường transportCost riêng)

    return CostSummary(
      otherCost: otherCost,
      transportFee: transportFee,
      rejectAmount: rejectAmount,
      otherCostNote: otherCostNote,
      rejectNote: rejectNote,
    );
  }

  DebtSummary _calculateDebtSummary(
    List<InvoiceEntity> imports,
    List<InvoiceEntity> exports,
    List<TransactionEntity> transactions,
  ) {
    // ========== CÔNG NỢ NCC (ta nợ NCC) - từ Nhập Chợ ==========
    final Map<String, CustomerDebt> supplierDebtMap = {};
    
    // Lấy danh sách partnerId của NCC từ imports
    final Set<String> supplierIds = {};
    for (final inv in imports) {
      if (inv.partnerId != null) supplierIds.add(inv.partnerId!);
    }

    for (final inv in imports) {
      final partnerId = inv.partnerId ?? 'unknown';
      final partnerName = inv.partnerName ?? 'Không xác định';
      final debtFromInvoice = inv.finalAmount - inv.paidAmount;

      if (supplierDebtMap.containsKey(partnerId)) {
        final existing = supplierDebtMap[partnerId]!;
        supplierDebtMap[partnerId] = CustomerDebt(
          partnerId: partnerId,
          partnerName: partnerName,
          debtType: 0, // NCC
          totalAmount: existing.totalAmount + inv.finalAmount,
          totalPaid: existing.totalPaid + inv.paidAmount,
          debtAmount: existing.debtAmount + (debtFromInvoice > 0 ? debtFromInvoice : 0),
          debtPaid: existing.debtPaid,
          remaining: existing.remaining + (debtFromInvoice > 0 ? debtFromInvoice : 0),
          invoiceCount: existing.invoiceCount + 1,
          lastTransaction: inv.createdDate.isAfter(existing.lastTransaction ?? DateTime(1970))
              ? inv.createdDate
              : existing.lastTransaction,
        );
      } else {
        supplierDebtMap[partnerId] = CustomerDebt(
          partnerId: partnerId,
          partnerName: partnerName,
          debtType: 0, // NCC
          totalAmount: inv.finalAmount,
          totalPaid: inv.paidAmount,
          debtAmount: debtFromInvoice > 0 ? debtFromInvoice : 0,
          debtPaid: 0,
          remaining: debtFromInvoice > 0 ? debtFromInvoice : 0,
          invoiceCount: 1,
          lastTransaction: inv.createdDate,
        );
      }
    }

    // ========== CÔNG NỢ KHÁCH HÀNG (khách nợ ta) - từ Xuất Chợ ==========
    final Map<String, CustomerDebt> customerDebtMap = {};
    
    // Lấy danh sách partnerId của khách hàng từ exports
    final Set<String> customerIds = {};
    for (final inv in exports) {
      if (inv.partnerId != null) customerIds.add(inv.partnerId!);
    }

    for (final inv in exports) {
      final partnerId = inv.partnerId ?? 'unknown';
      final partnerName = inv.partnerName ?? 'Không xác định';
      final debtFromInvoice = inv.finalAmount - inv.paidAmount;

      if (customerDebtMap.containsKey(partnerId)) {
        final existing = customerDebtMap[partnerId]!;
        customerDebtMap[partnerId] = CustomerDebt(
          partnerId: partnerId,
          partnerName: partnerName,
          debtType: 1, // Khách hàng
          totalAmount: existing.totalAmount + inv.finalAmount,
          totalPaid: existing.totalPaid + inv.paidAmount,
          debtAmount: existing.debtAmount + (debtFromInvoice > 0 ? debtFromInvoice : 0),
          debtPaid: existing.debtPaid,
          remaining: existing.remaining + (debtFromInvoice > 0 ? debtFromInvoice : 0),
          invoiceCount: existing.invoiceCount + 1,
          lastTransaction: inv.createdDate.isAfter(existing.lastTransaction ?? DateTime(1970))
              ? inv.createdDate
              : existing.lastTransaction,
        );
      } else {
        customerDebtMap[partnerId] = CustomerDebt(
          partnerId: partnerId,
          partnerName: partnerName,
          debtType: 1, // Khách hàng
          totalAmount: inv.finalAmount,
          totalPaid: inv.paidAmount,
          debtAmount: debtFromInvoice > 0 ? debtFromInvoice : 0,
          debtPaid: 0,
          remaining: debtFromInvoice > 0 ? debtFromInvoice : 0,
          invoiceCount: 1,
          lastTransaction: inv.createdDate,
        );
      }
    }

    // Duyệt qua transactions để tính tiền đã trả nợ
    for (final t in transactions) {
      final partnerId = t.partnerId;
      if (partnerId == null) continue;

      // Type = 1 (Chi): Ta chi tiền cho NCC (thanh toán hoặc trả nợ NCC)
      if (t.type == 1 && supplierIds.contains(partnerId)) {
        if (supplierDebtMap.containsKey(partnerId)) {
          final existing = supplierDebtMap[partnerId]!;
          supplierDebtMap[partnerId] = CustomerDebt(
            partnerId: existing.partnerId,
            partnerName: existing.partnerName,
            debtType: 0,
            totalAmount: existing.totalAmount,
            totalPaid: existing.totalPaid,
            debtAmount: existing.debtAmount,
            debtPaid: existing.debtPaid + t.amount,
            remaining: (existing.remaining - t.amount) > 0 
                ? existing.remaining - t.amount 
                : 0,
            invoiceCount: existing.invoiceCount,
            lastTransaction: t.date.isAfter(existing.lastTransaction ?? DateTime(1970))
                ? t.date
                : existing.lastTransaction,
          );
        }
      }
      
      // Type = 0 (Thu): Khách trả tiền cho ta (thanh toán hoặc trả nợ khách)
      if (t.type == 0 && customerIds.contains(partnerId)) {
        if (customerDebtMap.containsKey(partnerId)) {
          final existing = customerDebtMap[partnerId]!;
          customerDebtMap[partnerId] = CustomerDebt(
            partnerId: existing.partnerId,
            partnerName: existing.partnerName,
            debtType: 1,
            totalAmount: existing.totalAmount,
            totalPaid: existing.totalPaid,
            debtAmount: existing.debtAmount,
            debtPaid: existing.debtPaid + t.amount,
            remaining: (existing.remaining - t.amount) > 0 
                ? existing.remaining - t.amount 
                : 0,
            invoiceCount: existing.invoiceCount,
            lastTransaction: t.date.isAfter(existing.lastTransaction ?? DateTime(1970))
                ? t.date
                : existing.lastTransaction,
          );
        }
      }
    }

    // Tổng hợp NCC - nợ phát sinh từ invoices
    double totalSupplierDebt = 0;
    for (final inv in imports) {
      final debt = inv.finalAmount - inv.paidAmount;
      if (debt > 0) totalSupplierDebt += debt;
    }
    
    // Tổng tiền đã trả NCC từ transactions (Chi cho NCC)
    double totalSupplierPaid = 0;
    for (final t in transactions) {
      if (t.type == 1 && t.partnerId != null && supplierIds.contains(t.partnerId)) {
        totalSupplierPaid += t.amount;
      }
    }
    final supplierRemaining = totalSupplierDebt - totalSupplierPaid;

    // Tổng hợp Khách hàng - nợ phát sinh từ invoices
    double totalCustomerDebt = 0;
    for (final inv in exports) {
      final debt = inv.finalAmount - inv.paidAmount;
      if (debt > 0) totalCustomerDebt += debt;
    }
    
    // Tổng tiền khách đã trả từ transactions (Thu từ khách)
    double totalCustomerPaid = 0;
    for (final t in transactions) {
      if (t.type == 0 && t.partnerId != null && customerIds.contains(t.partnerId)) {
        totalCustomerPaid += t.amount;
      }
    }
    final customerRemaining = totalCustomerDebt - totalCustomerPaid;

    // Sắp xếp theo số tiền còn nợ giảm dần
    final supplierDebts = supplierDebtMap.values.toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));
    final customerDebts = customerDebtMap.values.toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));

    return DebtSummary(
      totalSupplierDebt: totalSupplierDebt,
      totalSupplierPaid: totalSupplierPaid,
      supplierRemaining: supplierRemaining > 0 ? supplierRemaining : 0,
      totalCustomerDebt: totalCustomerDebt,
      totalCustomerPaid: totalCustomerPaid,
      customerRemaining: customerRemaining > 0 ? customerRemaining : 0,
      // Legacy
      totalDebt: totalSupplierDebt,
      totalPaid: totalSupplierPaid,
      totalDebtPaid: totalSupplierPaid,
      remaining: supplierRemaining > 0 ? supplierRemaining : 0,
      supplierDebts: supplierDebts,
      customerDebts: customerDebts,
    );
  }
}
