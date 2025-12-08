import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/i_partner_repository.dart';
import 'partner_event.dart';
import 'partner_state.dart';

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final IPartnerRepository _repository;

  PartnerBloc(this._repository) : super(const PartnerState()) {
    on<LoadPartners>(_onLoadPartners);
    on<AddPartner>(_onAddPartner);
    on<UpdatePartnerInfo>(_onUpdatePartner);
    on<DeletePartner>(_onDeletePartner);
  }

  Future<void> _onLoadPartners(LoadPartners event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: PartnerStatus.loading, isSupplierFilter: event.isSupplier));
    await emit.forEach(
      _repository.watchPartners(event.isSupplier),
      onData: (partners) => state.copyWith(
        status: PartnerStatus.success,
        partners: partners,
        isSupplierFilter: event.isSupplier,
      ),
      onError: (error, stackTrace) => state.copyWith(
        status: PartnerStatus.failure,
        errorMessage: error.toString(),
        isSupplierFilter: event.isSupplier,
      ),
    );
  }

  Future<void> _onAddPartner(AddPartner event, Emitter<PartnerState> emit) async {
    try {
      await _repository.addPartner(event.partner);
    } catch (e) {
      emit(state.copyWith(status: PartnerStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdatePartner(UpdatePartnerInfo event, Emitter<PartnerState> emit) async {
    try {
      await _repository.updatePartner(event.partner);
    } catch (e) {
      emit(state.copyWith(status: PartnerStatus.failure, errorMessage: e.toString()));
    }
  }

  // Xử lý logic xóa
  Future<void> _onDeletePartner(DeletePartner event, Emitter<PartnerState> emit) async {
    try {
      await _repository.deletePartner(event.id);
      // Stream sẽ tự động cập nhật danh sách mới
    } catch (e) {
      emit(state.copyWith(status: PartnerStatus.failure, errorMessage: e.toString()));
    }
  }
}