import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/scale_service.dart';
import '../../../../domain/entities/partner.dart';
import '../../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';
import '../../../../domain/entities/pig_type.dart';
import '../../../../domain/repositories/i_pigtype_repository.dart';
import '../pig_types/pig_types_screen.dart';

class ImportBarnScreen extends StatelessWidget {
  const ImportBarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(0))),
        BlocProvider(create: (_) => sl<PartnerBloc>()..add(const LoadPartners(true))),
      ],
      child: const _ImportBarnView(),
    );
  }
}

class _ImportBarnView extends StatefulWidget {
  const _ImportBarnView();

  @override
  State<_ImportBarnView> createState() => _ImportBarnViewState();
}

class _ImportBarnViewState extends State<_ImportBarnView> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _truckCostController = TextEditingController(); 
  final TextEditingController _pigTypeController = TextEditingController();
  
  final FocusNode _weightFocus = FocusNode(); 
  final FocusNode _quantityFocus = FocusNode();

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final NumberFormat _numberFormat = NumberFormat("#,##0.0", "en_US");

  PartnerEntity? _selectedPartner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weightFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _truckCostController.dispose();
    _pigTypeController.dispose();
    _weightFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () => _saveInvoice(context),
        const SingleActivator(LogicalKeyboardKey.f1): () => _addFromScaleShortcut(context),
      },
      child: Focus(
        autofocus: true,
        child: BlocListener<WeighingBloc, WeighingState>(
          listener: (context, state) {
            if (state.status == WeighingStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Đã lưu phiếu NHẬP KHO thành công!"),
                  backgroundColor: Colors.green,
                ),
              );
              _resetForm();
            } else if (state.status == WeighingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("Lỗi: ${state.errorMessage}"), backgroundColor: Colors.red),
              );
            }
          },
          child: Scaffold(
            backgroundColor: Colors.orange[50], 
            appBar: AppBar(
              title: const Text("NHẬP KHO (MUA HEO)"),
              backgroundColor: Colors.white,
              elevation: 1,
              actions: [
                IconButton(
                  tooltip: 'Quản lý Loại heo',
                  icon: const Icon(Icons.pets_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PigTypesScreen())),
                ),
                BlocBuilder<WeighingBloc, WeighingState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: FilledButton.icon(
                        onPressed: state.items.isEmpty ? null : () => _saveInvoice(context),
                        icon: const Icon(Icons.save),
                        label: const Text("LƯU (F4)"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.orange[800]),
                      ),
                    );
                  },
                )
              ],
            ),
            body: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [_buildInputPanel(context)]),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildInvoiceHeader(context),
                        const Divider(height: 1),
                        Expanded(child: _buildWeighingList()),
                        const Divider(height: 1),
                        _buildInvoiceFooter(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _weightController.clear();
    _quantityController.text = '1';
    _priceController.clear();
    _truckCostController.clear();
    setState(() {
      _selectedPartner = null;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(0));
    _weightFocus.requestFocus();
  }

  void _saveInvoice(BuildContext context) {
    if (context.read<WeighingBloc>().state.items.isNotEmpty) {
      context.read<WeighingBloc>().add(const WeighingSaved());
    }
  }

  void _addFromScaleShortcut(BuildContext context) {
    final state = context.read<WeighingBloc>().state;
    if (state.isScaleConnected && state.scaleWeight > 0) {
      _submitWeightFromScale(context, state.scaleWeight);
    }
  }

  Widget _buildInvoiceHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: BlocBuilder<WeighingBloc, WeighingState>(
        builder: (context, state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NHÀ CUNG CẤP / TRẠI:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    BlocBuilder<PartnerBloc, PartnerState>(
                      builder: (context, partnerState) {
                        return DropdownButtonFormField<PartnerEntity>(
                          value: _selectedPartner,
                          hint: const Text("Chọn Trại heo..."),
                          isExpanded: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: partnerState.partners.map((partner) {
                            return DropdownMenuItem(value: partner, child: Text(partner.name));
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _selectedPartner = newValue);
                            if (newValue != null) {
                              context.read<WeighingBloc>().add(
                                WeighingInvoiceUpdated(partnerId: newValue.id, partnerName: newValue.name),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<PigTypeEntity>>(
                      stream: sl<IPigTypeRepository>().watchPigTypes(),
                      builder: (context, snap) {
                        final types = snap.data ?? [];
                        final PigTypeEntity? selected = types.isEmpty ? null : types.firstWhere((t) => t.name == _pigTypeController.text, orElse: () => types.first);
                        return DropdownButtonFormField<PigTypeEntity?>(
                          value: selected,
                          decoration: const InputDecoration(labelText: 'Loại heo', border: OutlineInputBorder(), isDense: true),
                          items: types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) {
                            if (v != null) _pigTypeController.text = v.name;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Tổng Nhập: ${_numberFormat.format(state.currentInvoice?.totalWeight ?? 0)} kg",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                  Text("Số lượng: ${state.currentInvoice?.totalQuantity ?? 0} con"),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            BlocBuilder<WeighingBloc, WeighingState>(
              builder: (context, state) {
                if (!state.isScaleConnected) return const SizedBox.shrink();
                return Column(
                  children: [
                     Text("Cân điện tử: ${_numberFormat.format(state.scaleWeight)} kg", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 10),
                  ],
                );
              },
            ),

            const Text("CÂN NHẬP KHO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),
            
            // Hàng nhập liệu: Cân nặng + Số con
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _weightController,
                    focusNode: _weightFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitWeight(context),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Khối lượng (kg)",
                      border: OutlineInputBorder(), 
                      hintText: "0.0"
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: "Số con",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                       // Enter ô số con -> Quay lại ô cân
                       _weightFocus.requestFocus();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _submitWeight(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("GHI CÂN (Enter)", style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ),
                BlocBuilder<WeighingBloc, WeighingState>(
                  builder: (context, state) {
                    if (!state.isScaleConnected) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => _submitWeightFromScale(context, state.scaleWeight),
                          child: const Text("LẤY SỐ (F1)"),
                        ),
                      ),
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeighingList() {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const Center(child: Text("Chưa có mã cân nhập"));
        final items = state.items.reversed.toList();
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Text("${item.sequence}")),
              title: Text("${_numberFormat.format(item.weight)} kg", style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("${item.quantity} con - ${DateFormat('HH:mm').format(item.time)}"),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Giá nhập (đ/kg)", border: OutlineInputBorder()),
                  onChanged: (val) => _updateCalculations(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _truckCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Chi phí khác (đ)", border: OutlineInputBorder()),
                  onChanged: (val) => _updateCalculations(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BlocBuilder<WeighingBloc, WeighingState>(
            builder: (context, state) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TỔNG TIỀN PHẢI TRẢ:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_currencyFormat.format(state.currentInvoice?.finalAmount ?? 0),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  void _submitWeight(BuildContext context) {
    final text = _weightController.text;
    if (text.isEmpty) return;
    final weight = double.tryParse(text);
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (weight != null && weight > 0) {
      context.read<WeighingBloc>().add(WeighingItemAdded(weight: weight, quantity: quantity));
      _weightController.clear();
      _weightFocus.requestFocus();
    }
  }

  void _submitWeightFromScale(BuildContext context, double weight) {
    if (weight > 0) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      context.read<WeighingBloc>().add(WeighingItemAdded(weight: weight, quantity: quantity));
      _weightFocus.requestFocus();
    }
  }

  void _updateCalculations(BuildContext context) {
    double price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    double cost = double.tryParse(_truckCostController.text.replaceAll(',', '')) ?? 0;
    context.read<WeighingBloc>().add(WeighingInvoiceUpdated(pricePerKg: price, truckCost: cost));
  }
}