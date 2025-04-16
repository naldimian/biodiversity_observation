/*import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final String title;
  final String subTitle;
  const MyListTile({super.key, required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 20.0, right: 20, bottom: 10
      ),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),

        ),
        child: ListTile(
          title: Text(title),
          subtitle: Text(
            subTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final String subTitle;
  final String? title;
  final Widget? titleWidget;

  const MyListTile({
    super.key,
    this.title,
    this.titleWidget,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20,
        bottom: 10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: titleWidget ?? Text(
            title ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
