import 'package:flutter/material.dart';

import '../model/sport_session.dart';
import '../widget/history_card.dart';
import 'detail.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<SportSession>>(
          valueListenable: SessionStore.sessions,
          builder: (context, sessions, _) {
            if (sessions.isEmpty) {
              return const Center(
                child: Text('No activity history yet.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];

                return HistoryCard(
                  session: session,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPage(session: session),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}