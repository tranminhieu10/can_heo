import 'package:equatable/equatable.dart';
import '../../../../domain/entities/partner.dart';

abstract class PartnerEvent extends Equatable {
  const PartnerEvent();
  @override
  List<Object> get props => [];
}

// Sự kiện: Tải danh sách (có lọc theo loại)
class LoadPartners extends PartnerEvent {
  final bool isSupplier; // true = Trại, false = Khách
  const LoadPartners(this.isSupplier);

  @override
  List<Object> get props => [isSupplier];
}

// Sự kiện: Thêm đối tác mới
class AddPartner extends PartnerEvent {
  final PartnerEntity partner;
  const AddPartner(this.partner);

  @override
  List<Object> get props => [partner];
}

// Sự kiện: Cập nhật thông tin
class UpdatePartnerInfo extends PartnerEvent {
  final PartnerEntity partner;
  const UpdatePartnerInfo(this.partner);

  @override
  List<Object> get props => [partner];
}