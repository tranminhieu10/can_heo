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
      final debtSummary = _calculateDebtSummary(filteredImports, transactions);

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
    List<TransactionEntity> transactions,
  ) {
    // Tổng nợ phát sinh = Tổng tiền nhập - Tiền đã thanh toán lúc nhập
    double totalDebt = 0;
    for (final inv in imports) {
      final debt = inv.finalAmount - inv.paidAmount;
      if (debt > 0) {
        totalDebt += debt;
      }
    }

    // Đã thanh toán (type = 1 = Chi, note chứa "thanh toán")
    double totalPaid = 0;
    double totalDebtPaid = 0;

    for (final t in transactions) {
      if (t.type == 1) {
        // Chi
        final note = t.note?.toLowerCase() ?? '';
        if (note.contains('trả nợ')) {
          totalDebtPaid += t.amount;
        } else if (note.contains('thanh toán')) {
          totalPaid += t.amount;
        }
      }
    }

    final remaining = totalDebt - totalDebtPaid;

    return DebtSummary(
      totalDebt: totalDebt,
      totalPaid: totalPaid,
      totalDebtPaid: totalDebtPaid,
      remaining: remaining > 0 ? remaining : 0,
    );
  }
}
