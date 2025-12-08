import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';

// -------- STATES --------

abstract class InvoiceDetailState extends Equatable {
  const InvoiceDetailState();

  @override
  List<Object?> get props => [];
}

class InvoiceDetailInitial extends InvoiceDetailState {}

class InvoiceDetailLoading extends InvoiceDetailState {}

class InvoiceDetailLoaded extends InvoiceDetailState {
  final InvoiceEntity invoice;

  const InvoiceDetailLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoiceDetailDeleted extends InvoiceDetailState {}

class InvoiceDetailError extends InvoiceDetailState {
  final String message;

  const InvoiceDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// -------- CUBIT --------

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final IInvoiceRepository _repository;

  InvoiceDetailCubit(this._repository) : super(InvoiceDetailInitial());

  Future<void> loadInvoice(String id) async {
    emit(InvoiceDetailLoading());
    try {
      final invoice = await _repository.getInvoiceDetail(id);
      if (invoice != null) {
        emit(InvoiceDetailLoaded(invoice));
      } else {
        emit(const InvoiceDetailError('Không tìm thấy phiếu này'));
      }
    } catch (e) {
      emit(InvoiceDetailError(e.toString()));
    }
  }

  Future<void> deleteInvoice(String id) async {
    emit(InvoiceDetailLoading());
    try {
      await _repository.deleteInvoice(id);
      emit(InvoiceDetailDeleted());
    } catch (e) {
      emit(InvoiceDetailError(e.toString()));
    }
  }
}
