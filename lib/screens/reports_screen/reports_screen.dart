import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/reports_provider.dart';
import '../../models/store_model.dart';
import 'package:intl/intl.dart';

// Global RouteObserver in main.dart
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reportsProvider.notifier).loadStores());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.read(reportsProvider.notifier).loadStores();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(reportsProvider.notifier);
    final state = ref.watch(reportsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(notifier),
              const Divider(),
              _filters(state, notifier),
              const Divider(),
              _tableSection(state, notifier),
              if (state.filteredStores.length > state.rowsPerPage)
                _pagination(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ReportsNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr("reports.title"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF295D6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => notifier.exportCSV(context),
          child: Text(tr("reports.export_csv")),
        ),
      ],
    );
  }

  Widget _filters(ReportsState state, ReportsNotifier notifier) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) notifier.pickDate(picked);
              },
              child: Text(
                "${tr("reports.date")}: ${DateFormat('dd-MM-yyyy').format(state.selectedDate)}",
              ),
            ),
            Text(
              "${tr("reports.paid")}: ${state.filteredStores.where((s) => notifier.getStatusForSelectedDate(s) == 'paid').length} | ${tr("reports.total")}: ${state.filteredStores.length}",
            ),
          ],
        ),
        Row(
          children: [
            Text("${tr("reports.group")}: "),
            DropdownButton<String>(
              value: state.selectedGroup,
              items: notifier
                  .getGroups()
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) {
                if (val != null) notifier.changeGroup(val);
              },
              underline: const SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tableSection(ReportsState state, ReportsNotifier notifier) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _table(state, notifier);
  }

  Widget _table(ReportsState state, ReportsNotifier notifier) {
    return Column(
      children: state.visibleStores.map((store) {
        return InkWell(
          onTap: () => _showStoreDetail(state, notifier, store),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: Text(store.id.toString())),
                  Expanded(flex: 4, child: Text(store.name)),
                  Expanded(flex: 2, child: Text(store.group ?? '-')),
                  Expanded(
                    flex: 2,
                    child: Text(
                      notifier.getStatusForSelectedDate(store).toUpperCase(),
                      style: TextStyle(
                        color:
                            notifier.getStatusForSelectedDate(store) == "paid"
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "${tr("reports.owner")}: ${store.owner}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(flex: 2, child: SizedBox()),
                ],
              ),
              const Divider(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _pagination(ReportsState state, ReportsNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state.currentPage > 0 ? notifier.prevPage : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          "${tr("reports.page")} ${state.currentPage + 1} ${tr("reports.of")} ${(state.filteredStores.length / state.rowsPerPage).ceil()}",
        ),
        IconButton(
          onPressed:
              (state.currentPage + 1) * state.rowsPerPage <
                  state.filteredStores.length
              ? notifier.nextPage
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showStoreDetail(
    ReportsState state,
    ReportsNotifier notifier,
    Store store,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat("dd-MM-yyyy").format(state.selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "\$${store.defaultAmount} | ${notifier.getStatusForSelectedDate(store).toUpperCase()}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: notifier.getStatusForSelectedDate(store) == 'paid'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(),
              _detailRow(tr("reports.store_id"), store.id.toString()),
              _detailRow(tr("reports.store_name"), store.name),
              _detailRow(tr("reports.owner"), store.owner),
              _detailRow(tr("reports.group"), store.group ?? "-"),
              _detailRow(tr("reports.amount"), store.defaultAmount.toString()),
              _detailRow(
                tr("reports.transaction_id"),
                store.latestPayment?.transactionId ?? "-",
              ),
              _detailRow(
                tr("reports.timestamp"),
                store.latestPayment?.createdAt ?? "-",
              ),
              _detailRow(tr("reports.note"), store.latestPayment?.note ?? "-"),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
        const Divider(),
      ],
    );
  }
}
