import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/store_model.dart';
import '../../services/api_service.dart';
import '../../providers/collector_provider.dart';

class CollectorScreen extends ConsumerStatefulWidget {
  const CollectorScreen({super.key});

  @override
  ConsumerState<CollectorScreen> createState() => _CollectorScreenState();
}

class _CollectorScreenState extends ConsumerState<CollectorScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(collectorProvider).loadStores());
  }

  void showSnackBar(String message) {
    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(collectorProvider);
    final notifier = ref.read(collectorProvider);

    return Scaffold(
      key: scaffoldMessengerKey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Box 1: Scan to Pay
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Store dropdown
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.store,
                                  color: Color(0xFF295D6B),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: DropdownButtonFormField<Store?>(
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    icon: const SizedBox.shrink(),
                                    value: provider.selectedStore,
                                    hint: Text(
                                      tr("collector.select_store"),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF295D6B),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          tr("collector.all"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      ...provider.filteredStores.map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: notifier.setSelectedStore,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // QR + expand
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFF295D6B),
                                  size: 30,
                                ),
                                onPressed: () async {
                                  if (provider.selectedStore == null) {
                                    if (!mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(
                                          tr("collector.select_store_first"),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(tr("common.ok")),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Center(
                                          child: Text(
                                            "${tr("collector.qr_for")} ${provider.selectedStore!.name}",
                                          ),
                                        ),
                                        content: QrImageView(
                                          data:
                                              'http://192.168.1.114:8000/pay?store_id=${provider.selectedStore!.id}&amount=${provider.selectedStore!.defaultAmount}&date=${provider.selectedDate!.toIso8601String()}',
                                          version: QrVersions.auto,
                                          size: 200,
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.center,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(tr("common.close")),
                                          ),
                                        ],
                                      ),
                                    );
                                    await notifier.refreshStores();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  provider.isExpanded
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: const Color(0xFF295D6B),
                                  size: 30,
                                ),
                                onPressed: notifier.toggleExpanded,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (provider.isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF295D6B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextField(
                                        readOnly: true,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              "${provider.selectedDate!.year}-${provider.selectedDate!.month.toString().padLeft(2, '0')}-${provider.selectedDate!.day.toString().padLeft(2, '0')}",
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF295D6B),
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: provider.selectedDate!,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            notifier.setSelectedDate(picked);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: provider.selectedGroup,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.group,
                                  color: Color(0xFF295D6B),
                                  size: 30,
                                ),
                                items: provider.getGroups().map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: notifier.setSelectedGroup,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Box 2: Store list with loading indicator
              SizedBox(
                height: 500,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFF6F6F6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr("collector.todays_status"),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${tr("collector.stores")}: ${provider.filteredStores.length}",
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${tr("collector.paid")}: ${provider.filteredStores.where((s) => provider.getStatusForSelectedDate(s) == 'paid').length}",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: provider.isListLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  itemCount: provider.selectedStore != null
                                      ? 1
                                      : provider.filteredStores.length,
                                  itemBuilder: (context, index) {
                                    final store =
                                        provider.selectedStore ??
                                        provider.filteredStores[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        title: Text(store.name),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${tr("collector.owner")}: ${store.owner}",
                                            ),
                                            Text(
                                              "${tr("collector.amount")}: ${store.defaultAmount}\$",
                                            ),
                                            if (store.latestPayment?.note !=
                                                    null &&
                                                store
                                                    .latestPayment!
                                                    .note!
                                                    .isNotEmpty)
                                              Text(
                                                "${tr("collector.note")}: ${store.latestPayment!.note!}",
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              provider
                                                  .getStatusForSelectedDate(
                                                    store,
                                                  )
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color:
                                                    provider.getStatusForSelectedDate(
                                                          store,
                                                        ) ==
                                                        "paid"
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.note_add,
                                                color: Color(0xFF295D6B),
                                              ),
                                              onPressed: () async {
                                                final controller =
                                                    TextEditingController(
                                                      text:
                                                          store
                                                              .latestPayment
                                                              ?.note ??
                                                          "",
                                                    );
                                                final result = await showDialog<String>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(
                                                      "${tr("collector.add_note_for")} ${store.name}",
                                                    ),
                                                    content: TextField(
                                                      controller: controller,
                                                      decoration: InputDecoration(
                                                        hintText: tr(
                                                          "collector.enter_note",
                                                        ),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: Text(
                                                          tr("common.cancel"),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              controller.text,
                                                            ),
                                                        child: Text(
                                                          tr("common.save"),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (result != null &&
                                                    store.latestPayment !=
                                                        null) {
                                                  try {
                                                    await ApiService.saveNote(
                                                      store.latestPayment!.id,
                                                      result,
                                                    );
                                                    store.latestPayment!.note =
                                                        result;
                                                    await notifier
                                                        .refreshStores();
                                                    showSnackBar(
                                                      tr(
                                                        "collector.note_saved",
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    showSnackBar(
                                                      tr(
                                                        "collector.note_failed",
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF295D6B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => notifier.exportCSV(context),
                            child: Text(tr("collector.export_csv")),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
