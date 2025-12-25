import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../injection_container.dart';
import 'bloc/market_report_bloc.dart';
import 'widgets/report_data_table.dart';

class MarketReportScreen extends StatelessWidget {
  const MarketReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MarketReportBloc>()
        ..add(const MarketReportSubscriptionRequested()),
      child: const MarketReportView(),
    );
  }
}

class MarketReportView extends StatefulWidget {
  const MarketReportView({super.key});

  @override
  State<MarketReportView> createState() => _MarketReportViewState();
}

class _MarketReportViewState extends State<MarketReportView> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set initial date range to today
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    // Dispatch event to load data for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketReportBloc>().add(
            MarketReportDateRangeChanged(
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _applyDateFilter() {
    context.read<MarketReportBloc>().add(
          MarketReportDateRangeChanged(
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Chợ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Filter Section
            _buildDateFilter(dateFormat),
            const SizedBox(height: 16),
            // Tab Bar and Tab View
            Expanded(
              child: BlocBuilder<MarketReportBloc, MarketReportState>(
                builder: (context, state) {
                  if (state.status == MarketReportStatus.loading || state.startDate == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == MarketReportStatus.failure) {
                    return const Center(child: Text('Đã có lỗi xảy ra.'));
                  }
                  
                  final filteredImports = state.marketImports.where((inv) {
                    return !inv.createdDate.isBefore(state.startDate!) &&
                           inv.createdDate.isBefore(state.endDate!);
                  }).toList();

                  final filteredExports = state.marketExports.where((inv) {
                    return !inv.createdDate.isBefore(state.startDate!) &&
                           inv.createdDate.isBefore(state.endDate!);
                  }).toList();

                  return DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Nhập'),
                            Tab(text: 'Bán'),
                            Tab(text: 'Còn lại'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Nhập Tab
                              ReportDataTable(invoices: filteredImports, type: 'Nhập'),
                              // Bán Tab
                              ReportDataTable(invoices: filteredExports, type: 'Bán'),
                              // Còn lại Tab
                              const Center(child: Text('Báo cáo tồn kho')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _selectDate(context, true),
              icon: const Icon(Icons.calendar_today),
              label: Text('Từ: ${dateFormat.format(_startDate)}'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context, false),
              icon: const Icon(Icons.calendar_today),
              label: Text('Đến: ${dateFormat.format(_endDate)}'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _applyDateFilter,
              icon: const Icon(Icons.filter_list),
              label: const Text('Lọc'),
            ),
          ],
        ),
      ),
    );
  }
}