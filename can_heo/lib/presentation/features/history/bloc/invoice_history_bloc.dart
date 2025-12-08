import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'invoice_history_event.dart';
import 'invoice_history_state.dart';

class InvoiceHistoryBloc extends Bloc<InvoiceHistoryEvent, InvoiceHistoryState> {
  final IInvoiceRepository _repository;
  StreamSubscription? _invoicesSubscription;
  
  int _currentType = 2; 
  String? _currentKeyword;
  int? _currentDaysFilter;

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

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<InvoiceHistoryState> emit) async {
    _currentType = event.type;
    _currentKeyword = null;
    _currentDaysFilter = null;
    _subscribeToInvoices(emit);
  }

  Future<void> _onFilterInvoices(FilterInvoices event, Emitter<InvoiceHistoryState> emit) async {
    // Logic: Nếu event có truyền tham số thì cập nhật, không thì giữ nguyên
    // Nhưng với UI dropdown, ta cần phân biệt "Chọn tất cả" (null) và "Không thay đổi"
    // Ở đây ta quy ước: UI luôn gửi giá trị mới nhất của cả 2 trường để đơn giản.
    
    _currentKeyword = event.keyword;
    _currentDaysFilter = event.daysFilter;
    
    _subscribeToInvoices(emit);
  }

  void _subscribeToInvoices(Emitter<InvoiceHistoryState> emit) {
    emit(state.copyWith(status: HistoryStatus.loading));
    
    _invoicesSubscription?.cancel();
    _invoicesSubscription = _repository.watchInvoices(
      type: _currentType,
      keyword: _currentKeyword,
      daysAgo: _currentDaysFilter,
    ).listen(
      (invoices) => add(InvoicesUpdated(invoices)),
      onError: (error) => add(InvoicesError(error.toString())),
    );
  }

  void _onInvoicesUpdated(InvoicesUpdated event, Emitter<InvoiceHistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.success,
      invoices: event.invoices,
    ));
  }

  void _onInvoicesError(InvoicesError event, Emitter<InvoiceHistoryState> emit) {
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