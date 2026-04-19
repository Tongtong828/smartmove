import 'package:flutter/material.dart';

import '../model/tag.dart';
import '../store/store.dart';
import '../widget/history_card.dart';
import 'detail.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CheckInStore.instance,
      builder: (context, _) {
        final records = CheckInStore.instance.filteredByTag(_selectedFilter);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Places'),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 62,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                        top: 12,
                        bottom: 12,
                      ),
                      child: ChoiceChip(
                        selected: _selectedFilter == 'all',
                        label: const Text('All'),
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                      ),
                    ),
                    ...availableTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                          top: 12,
                          bottom: 12,
                        ),
                        child: ChoiceChip(
                          selected: _selectedFilter == tag.key,
                          label: Text(tag.label),
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = tag.key;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          'No places saved yet.\nStart by adding your first memory.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return HistoryCard(
                            record: record,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPage(record: record),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}