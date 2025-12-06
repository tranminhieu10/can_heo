import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'weighing_event.dart';
import 'weighing_state.dart';

class WeighingBloc extends Bloc<WeighingEvent, WeighingState> {
  final IInvoiceRepository invoiceRepository;
  final _uuid = const Uuid();

  // Biến tạm để nhớ giá và cước xe hiện tại (Giúp tính toán khi thêm cân mới)
  double _lastPrice = 0;
  double _lastTruckCost = 0;

  WeighingBloc({required this.invoiceRepository}) : super(const WeighingState()) {
    on<WeighingStarted>(_onStarted);
    on<WeighingItemAdded>(_onItemAdded);
    on<WeighingInvoiceUpdated>(_onInvoiceUpdated);
    on<WeighingSaved>(_onSaved);
  }

  void _onStarted(WeighingStarted event, Emitter<WeighingState> emit) {
    // Reset lại giá tạm khi bắt đầu phiếu mới
    _lastPrice = 0;
    _lastTruckCost = 0;

    final newInvoice = InvoiceEntity(
      id: _uuid.v4(),
      type: event.invoiceType,
      createdDate: DateTime.now(),
      totalWeight: 0,
      totalQuantity: 0,
      finalAmount: 0,
      details: [],
    );
    
    emit(state.copyWith(
      status: WeighingStatus.initial,
      currentInvoice: newInvoice,
      items: [],
      errorMessage: null, // Xóa lỗi cũ nếu có
    ));
  }

  void _onItemAdded(WeighingItemAdded event, Emitter<WeighingState> emit) {
    if (state.currentInvoice == null) return;

    // 1. Tạo mã cân mới
    final newItem = WeighingItemEntity(
      id: _uuid.v4(),
      sequence: state.items.length + 1,
      weight: event.weight,
      quantity: event.quantity,
      time: DateTime.now(),
    );

    // 2. Thêm vào đầu danh sách
    final updatedItems = [newItem, ...state.items];

    // 3. Tính lại tổng trọng lượng & số lượng
    double totalWeight = 0;
    int totalQty = 0;
    for (var item in updatedItems) {
      totalWeight += item.weight;
      totalQty += item.quantity;
    }

    // 4. Tính lại tiền dựa trên giá đã nhập trước đó (nếu có)
    final newFinalAmount = (totalWeight * _lastPrice) + _lastTruckCost;

    final updatedInvoice = state.currentInvoice!.copyWith(
      totalWeight: totalWeight,
      totalQuantity: totalQty,
      finalAmount: newFinalAmount,
    );

    emit(state.copyWith(items: updatedItems, currentInvoice: updatedInvoice));
  }

  void _onInvoiceUpdated(WeighingInvoiceUpdated event, Emitter<WeighingState> emit) {
    if (state.currentInvoice == null) return;

    // Cập nhật biến nhớ nếu có thay đổi
    if (event.pricePerKg != null) _lastPrice = event.pricePerKg!;
    if (event.truckCost != null) _lastTruckCost = event.truckCost!;

    // Tính lại Thành tiền = (Tổng cân * Đơn giá) + Cước xe
    final currentWeight = state.currentInvoice!.totalWeight;
    final finalAmount = (currentWeight * _lastPrice) + _lastTruckCost;

    final updatedInvoice = state.currentInvoice!.copyWith(
      partnerId: event.partnerId ?? state.currentInvoice!.partnerId,
      finalAmount: finalAmount,
    );

    emit(state.copyWith(currentInvoice: updatedInvoice));
  }

  Future<void> _onSaved(WeighingSaved event, Emitter<WeighingState> emit) async {
    if (state.currentInvoice == null) return;
    emit(state.copyWith(status: WeighingStatus.loading));

    try {
      // 1. Lưu Header phiếu
      await invoiceRepository.createInvoice(state.currentInvoice!);
      
      // 2. Lưu từng chi tiết
      for (var item in state.items) {
        await invoiceRepository.addWeighingItem(state.currentInvoice!.id, item);
      }

      emit(state.copyWith(status: WeighingStatus.success));
    } catch (e) {
      emit(state.copyWith(status: WeighingStatus.failure, errorMessage: e.toString()));
    }
  }
}

// Extension giúp copy nhanh InvoiceEntity (tránh viết lại constructor dài dòng)
extension InvoiceEntityCopyWith on InvoiceEntity {
  InvoiceEntity copyWith({
    String? id,
    int? type,
    double? totalWeight,
    int? totalQuantity,
    double? finalAmount,
    String? partnerId,
    String? partnerName,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      createdDate: createdDate,
      totalWeight: totalWeight ?? this.totalWeight,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      finalAmount: finalAmount ?? this.finalAmount,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      details: details,
    );
  }
}