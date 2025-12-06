import 'package:flutter_bloc/flutter_bloc.dart';

// Import Interface Repository
import '../../../../domain/repositories/i_partner_repository.dart';

// Import 2 file Event và State cùng thư mục
import 'partner_event.dart';
import 'partner_state.dart';

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final IPartnerRepository _repository;

  PartnerBloc(this._repository) : super(const PartnerState()) {
    on<LoadPartners>(_onLoadPartners);
    on<AddPartner>(_onAddPartner);
    on<UpdatePartnerInfo>(_onUpdatePartner);
  }

  Future<void> _onLoadPartners(LoadPartners event, Emitter<PartnerState> emit) async {
    // 1. Emit trạng thái đang tải và lưu lại bộ lọc hiện tại (Khách hay Trại)
    emit(state.copyWith(
      status: PartnerStatus.loading, 
      isSupplierFilter: event.isSupplier
    ));

    // 2. Lắng nghe Stream dữ liệu từ Database
    await emit.forEach(
      _repository.watchPartners(event.isSupplier),
      onData: (partners) => state.copyWith(
        status: PartnerStatus.success,
        partners: partners,
      ),
      onError: (error, stackTrace) => state.copyWith(
        status: PartnerStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onAddPartner(AddPartner event, Emitter<PartnerState> emit) async {
    try {
      await _repository.addPartner(event.partner);
      // Không cần emit Success vì Stream ở trên (_onLoadPartners) sẽ tự động nhận thấy thay đổi
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
}