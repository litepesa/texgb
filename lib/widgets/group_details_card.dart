import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/group_status_widget.dart';
import 'package:textgb/widgets/profile_status_widget.dart';
import 'package:textgb/widgets/profile_widgets.dart';

class InfoDetailsCard extends StatelessWidget {
  const InfoDetailsCard({
    super.key,
    this.groupProvider,
    this.isAdmin,
    this.userModel,
  });

  final GroupProvider? groupProvider;
  final bool? isAdmin;
  final UserModel? userModel;

  @override
  Widget build(BuildContext context) {
    // get current user
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    // get profile image
    final profileImage = userModel != null
        ? userModel!.image
        : groupProvider!.groupModel.groupImage;
    // get profile name
    final profileName = userModel != null
        ? userModel!.name
        : groupProvider!.groupModel.groupName;

    // get group description
    final aboutMe = userModel != null
        ? userModel!.aboutMe
        : groupProvider!.groupModel.groupDescription;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                userImageWidget(
                    imageUrl: profileImage, radius: 50, onTap: () {}),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      profileName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // display phone number
                    userModel != null && currentUser.uid == userModel!.uid
                        ? Text(
                            currentUser.phoneNumber,
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 5),
                    userModel != null
                        ? ProfileStatusWidget(
                            userModel: userModel!,
                            currentUser: currentUser,
                          )
                        : GroupStatusWidget(
                            isAdmin: isAdmin!,
                            groupProvider: groupProvider!,
                          ),

                    const SizedBox(height: 10),
                  ],
                )
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            Text(userModel != null ? 'About Me' : 'Group Description',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            Text(
              aboutMe,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
