import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget buildRankInfoButton(BuildContext context) {
  Color getIconColor(String rank) {
    switch (rank) {
      case 'Gold':
        return Colors.amber[700]!;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  Widget rankRow(String rank, String description) {
    return Row(
      children: [
        Icon(
          FontAwesomeIcons.crown,
          color: getIconColor(rank),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$rank: $description',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rank Explanation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                rankRow('Gold', '20 or more observations'),
                const SizedBox(height: 6),
                rankRow('Silver', '15–19 observations'),
                const SizedBox(height: 6),
                rankRow('Bronze', '10–14 observations'),
                const SizedBox(height: 6),
                rankRow('Newbie', 'Less than 10 observations'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 15),
      child: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    ),
  );
}
