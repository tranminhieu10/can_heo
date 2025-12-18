import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'invoice_history_event.dart';
import 'invoice_history_state.dart';

class InvoiceHistoryBloc
    extends Bloc<InvoiceHistoryEvent, InvoiceHistoryState> {
  final IInvoiceRepository _repository;
  StreamSubscription? _invoicesSubscription;

  int _currentType = 2;
  String? _currentKeyword;
  int? _currentDaysFilter;
  String? _currentPigType;
  String? _currentBatchNumber;
  double? _currentMinWeight;
  double? _currentMaxWeight;
  double? _currentMinAmount;
  double? _currentMaxAmount;

  InvoiceHistoryBloc(this._repository) : super(const InvoiceHistoryState()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<FilterInvoices>(_onFilterInvoices);

    // Handler cho sự kiện nội bộ (cần thiết vì listen stream trả về data bất đồng bộ)
    on<InvoicesUpdated>(_onInvoicesUpdated);
    on<InvoicesError>(_onInvoicesError);
  }

  @override
  Future<void> close() {
    _invoicesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadInvoices(
      LoadInvoices event, Emitter<InvoiceHistoryState> emit) async {
    _currentType = event.type;
    _currentKeyword = null;
    _currentDaysFilter = null;
    _currentPigType = null;
    _currentBatchNumber = null;
    _currentMinWeight = null;
    _currentMaxWeight = null;
    _currentMinAmount = null;
    _currentMaxAmount = null;
    _subscribeToInvoices(emit);
  }

  Future<void> _onFilterInvoices(
      FilterInvoices event, Emitter<InvoiceHistoryState> emit) async {
    _currentKeyword = event.keyword;
    _currentDaysFilter = event.daysFilter;
    _currentPigType = event.pigType;
    _currentBatchNumber = event.batchNumber;
    _currentMinWeight = event.minWeight;
    _currentMaxWeight = event.maxWeight;
    _currentMinAmount = event.minAmount;
    _currentMaxAmount = event.maxAmount;

    _subscribeToInvoices(emit);
  }

  void _subscribeToInvoices(Emitter<InvoiceHistoryState> emit) {
    emit(state.copyWith(status: HistoryStatus.loading));

    _invoicesSubscription?.cancel();
    _invoicesSubscription = _repository
        .watchInvoices(
      type: _currentType,
      keyword: _currentKeyword,
      daysAgo: _currentDaysFilter,
    )
        .listen(
      (invoices) {
        // Lọc thêm ở client side vì database không hỗ trợ lọc theo weighing details
        final filtered = _applyClientSideFilters(invoices);
        add(InvoicesUpdated(filtered));
      },
      onError: (error) => add(InvoicesError(error.toString())),
    );
  }

  List<InvoiceEntity> _applyClientSideFilters(List<InvoiceEntity> invoices) {
    // Debug: In ra số lượng invoice ban đầu
    print('🔍 DEBUG: Tổng số phiếu từ DB: ${invoices.length}');
    print('🔍 DEBUG: Bộ lọc hiện tại:');
    print('   - Loại heo: $_currentPigType');
    print('   - Số lô: $_currentBatchNumber');
    print('   - Min weight: $_currentMinWeight');
    print('   - Max weight: $_currentMaxWeight');
    print('   - Min amount: $_currentMinAmount');
    print('   - Max amount: $_currentMaxAmount');

    final filtered = invoices.where((inv) {
      // Debug: In ra thông tin mỗi phiếu
      print('📄 Phiếu ${inv.invoiceCode}: ${inv.details.length} details');
      for (var detail in inv.details) {
        print(
            '   - Detail: PigType="${detail.pigType}", Batch="${detail.batchNumber}"');
      }

      // Lọc theo loại heo
      if (_currentPigType != null && _currentPigType!.isNotEmpty) {
        final hasMatchingPigType = inv.details.any((detail) =>
            detail.pigType
                ?.toLowerCase()
                .contains(_currentPigType!.toLowerCase()) ??
            false);
        if (!hasMatchingPigType) {
          print('   ❌ Không khớp loại heo');
          return false;
        }
      }

      // Lọc theo số lô
      if (_currentBatchNumber != null && _currentBatchNumber!.isNotEmpty) {
        final hasMatchingBatch = inv.details.any((detail) =>
            detail.batchNumber
                ?.toLowerCase()
                .contains(_currentBatchNumber!.toLowerCase()) ??
            false);
        if (!hasMatchingBatch) {
          print('   ❌ Không khớp số lô');
          return false;
        }
      }

      // Lọc theo khối lượng
      if (_currentMinWeight != null && inv.totalWeight < _currentMinWeight!) {
        print('   ❌ Khối lượng quá nhỏ');
        return false;
      }
      if (_currentMaxWeight != null && inv.totalWeight > _currentMaxWeight!) {
        print('   ❌ Khối lượng quá lớn');
        return false;
      }

      // Lọc theo giá trị
      if (_currentMinAmount != null && inv.finalAmount < _currentMinAmount!) {
        print('   ❌ Giá trị quá nhỏ');
        return false;
      }
      if (_currentMaxAmount != null && inv.finalAmount > _currentMaxAmount!) {
        print('   ❌ Giá trị quá lớn');
        return false;
      }

      print('   ✅ Phiếu hợp lệ!');
      return true;
    }).toList();

    print('🔍 DEBUG: Kết quả sau lọc: ${filtered.length} phiếu');
    return filtered;
  }

  void _onInvoicesUpdated(
      InvoicesUpdated event, Emitter<InvoiceHistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.success,
      invoices: event.invoices,
    ));
  }

  void _onInvoicesError(
      InvoicesError event, Emitter<InvoiceHistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.failure,
      errorMessage: event.message,
    ));
  }
}

// Events nội bộ
class InvoicesUpdated extends InvoiceHistoryEvent {
  final List<InvoiceEntity> invoices;
  const InvoicesUpdated(this.invoices);
}

class InvoicesError extends InvoiceHistoryEvent {
  final String message;
  const InvoicesError(this.message);
}
