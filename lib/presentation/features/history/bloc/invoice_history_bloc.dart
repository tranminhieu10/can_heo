import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'invoice_history_event.dart';
import 'invoice_history_state.dart';

class InvoiceHistoryBloc extends Bloc<InvoiceHistoryEvent, InvoiceHistoryState> {
  final IInvoiceRepository _repository;

  InvoiceHistoryBloc(this._repository) : super(const InvoiceHistoryState()) {
    on<LoadInvoices>(_onLoadInvoices);
  }

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<InvoiceHistoryState> emit) async {
    // 1. Báo trạng thái đang tải
    emit(state.copyWith(status: HistoryStatus.loading));

    // 2. Tự động lắng nghe Stream từ Database
    // Khi Database thay đổi -> onData sẽ chạy -> Cập nhật State mới
    await emit.forEach(
      _repository.watchInvoices(event.type),
      onData: (invoices) => state.copyWith(
        status: HistoryStatus.success,
        invoices: invoices,
      ),
      onError: (error, stackTrace) => state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}