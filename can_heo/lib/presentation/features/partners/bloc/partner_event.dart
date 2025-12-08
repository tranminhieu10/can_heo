import 'package:equatable/equatable.dart';
import '../../../../domain/entities/partner.dart';

abstract class PartnerEvent extends Equatable {
  const PartnerEvent();
  @override
  List<Object> get props => [];
}

class LoadPartners extends PartnerEvent {
  final bool isSupplier; 
  const LoadPartners(this.isSupplier);

  @override
  List<Object> get props => [isSupplier];
}

class AddPartner extends PartnerEvent {
  final PartnerEntity partner;
  const AddPartner(this.partner);

  @override
  List<Object> get props => [partner];
}

class UpdatePartnerInfo extends PartnerEvent {
  final PartnerEntity partner;
  const UpdatePartnerInfo(this.partner);

  @override
  List<Object> get props => [partner];
}

// Mới: Sự kiện xóa đối tác
class DeletePartner extends PartnerEvent {
  final String id;
  const DeletePartner(this.id);

  @override
  List<Object> get props => [id];
}