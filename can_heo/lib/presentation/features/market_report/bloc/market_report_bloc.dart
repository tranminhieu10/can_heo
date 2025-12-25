import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';

part 'market_report_event.dart';
part 'market_report_state.dart';

class MarketReportBloc extends Bloc<MarketReportEvent, MarketReportState> {
  final IInvoiceRepository _invoiceRepository;

  MarketReportBloc({required IInvoiceRepository invoiceRepository})
      : _invoiceRepository = invoiceRepository,
        super(const MarketReportState()) {
    on<MarketReportSubscriptionRequested>(_onSubscriptionRequested);
    on<MarketReportDateRangeChanged>(_onDateRangeChanged);
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
          // A better repo method would be to filter by date range
          return [...imports, ...exports];
        },
      ),
      onData: (invoices) {
        final imports = invoices.where((inv) => inv.type == 3).toList();
        final exports = invoices.where((inv) => inv.type == 2).toList();
        return state.copyWith(
          status: MarketReportStatus.success,
          marketImports: imports,
          marketExports: exports,
        );
      },
      onError: (_, __) => state.copyWith(status: MarketReportStatus.failure),
    );
  }

  void _onDateRangeChanged(
    MarketReportDateRangeChanged event,
    Emitter<MarketReportState> emit,
  ) {
    emit(state.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
    ));
  }
}
