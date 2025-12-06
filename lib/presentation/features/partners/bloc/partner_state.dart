import 'package:equatable/equatable.dart';
import '../../../../domain/entities/partner.dart';

enum PartnerStatus { initial, loading, success, failure }

class PartnerState extends Equatable {
  final PartnerStatus status;
  final List<PartnerEntity> partners;
  final String? errorMessage;
  final bool isSupplierFilter;

  const PartnerState({
    this.status = PartnerStatus.initial,
    this.partners = const [],
    this.errorMessage,
    this.isSupplierFilter = false,
  });

  PartnerState copyWith({
    PartnerStatus? status,
    List<PartnerEntity>? partners,
    String? errorMessage,
    bool? isSupplierFilter,
  }) {
    return PartnerState(
      status: status ?? this.status,
      partners: partners ?? this.partners,
      errorMessage: errorMessage,
      isSupplierFilter: isSupplierFilter ?? this.isSupplierFilter,
    );
  }

  @override
  List<Object?> get props => [status, partners, errorMessage, isSupplierFilter];
}