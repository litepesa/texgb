import 'package:flutter/material.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/widgets/settings_list_tile.dart';

class SettingsAndMedia extends StatelessWidget {
  const SettingsAndMedia({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Column(
          children: [
            SettingsListTile(
              title: 'Media',
              icon: Icons.image,
              iconContainerColor: Colors.deepPurple,
              onTap: () {
                // navigate to media screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
