import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatAppBar extends ConsumerWidget {
  const ChatAppBar({super.key, required this.contactUID});

  final String contactUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = ref.watch(authenticationProvider.notifier).userStream(userID: contactUID);

    return StreamBuilder<DocumentSnapshot>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userModel = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

        return Row(
          children: [
            userImageWidget(
              imageUrl: userModel.image,
              radius: 20,
              onTap: () {
                Navigator.pushNamed(context, Constants.contactProfileScreen,
                    arguments: userModel.uid);
              },
            ),
            const SizedBox(width: 10),
            Text(
              userModel.name,
              style: GoogleFonts.openSans(
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}