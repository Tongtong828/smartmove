import 'package:flutter/material.dart';

import '../model/sport_type.dart';

class SelectListSheet extends StatelessWidget {
  final ValueChanged<SportType> onSelected;

  const SelectListSheet({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sports = SportType.values;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...sports.map(
              (sport) => Card(
                child: ListTile(
                  leading: Icon(sport.icon),
                  title: Text(sport.label),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(sport);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}