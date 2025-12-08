import '../entities/partner.dart';

abstract class IPartnerRepository
{
  Stream<List<PartnerEntity>> watchPartners(bool isSupplier);
  
  Future<void> addPartner(PartnerEntity partner);
  
  Future<void> updatePartner(PartnerEntity partner);
  
  Future<void> updateDebt(String partnerId, double amount);
  
  // Mới
  Future<void> deletePartner(String id);
}