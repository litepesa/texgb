import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Widget userImageWidget({
  required String imageUrl,
  required double radius,
  required Function() onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl)
          : const AssetImage(AssetsManager.userImage) as ImageProvider,
    ),
  );
}

// pick image from gallery or camera
Future<File?> pickImage({
  required bool fromCamera,
  required Function(String) onFail,
}) async {
  File? fileImage;
  if (fromCamera) {
    // get picture from camera
    try {
      final pickedFile =
          await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 80, // Compress image for better performance
          );
      if (pickedFile == null) {
        onFail('No image selected');
      } else {
        fileImage = File(pickedFile.path);
        
        // Check file size
        final fileSize = await fileImage.length();
        final fileSizeInMB = fileSize / (1024 * 1024);
        
        if (fileSizeInMB > 10) {
          onFail('Image size too large. Maximum allowed is 10MB.');
          return null;
        }
      }
    } catch (e) {
      onFail(e.toString());
    }
  } else {
    // get picture from gallery
    try {
      final pickedFile =
          await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 80, // Compress image for better performance
          );
      if (pickedFile == null) {
        onFail('No image selected');
      } else {
        fileImage = File(pickedFile.path);
        
        // Check file size
        final fileSize = await fileImage.length();
        final fileSizeInMB = fileSize / (1024 * 1024);
        
        if (fileSizeInMB > 10) {
          onFail('Image size too large. Maximum allowed is 10MB.');
          return null;
        }
      }
    } catch (e) {
      onFail(e.toString());
    }
  }

  return fileImage;
}

// pick video from gallery with duration limit and size check
Future<File?> pickVideo({
  required Function(String) onFail,
  Duration? maxDuration,
}) async {
  File? fileVideo;
  try {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration ?? const Duration(seconds: 90), // Default to 90 seconds
    );
    
    if (pickedFile == null) {
      onFail('No video selected');
    } else {
      fileVideo = File(pickedFile.path);
      
      // Check file size
      final fileSize = await fileVideo.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Limit file size to 50MB
      if (fileSizeInMB > 50) {
        onFail('Video size too large. Maximum allowed is 50MB.');
        return null;
      }
    }
  } catch (e) {
    onFail('Error picking video: $e');
  }

  return fileVideo;
}

// Pick video from camera
Future<File?> pickVideoFromCamera({
  required Function(String) onFail,
  Duration? maxDuration,
}) async {
  File? fileVideo;
  try {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration ?? const Duration(seconds: 90), // Default to 90 seconds
    );
    
    if (pickedFile == null) {
      onFail('No video recorded');
    } else {
      fileVideo = File(pickedFile.path);
      
      // Check file size
      final fileSize = await fileVideo.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Limit file size to 50MB
      if (fileSizeInMB > 50) {
        onFail('Video size too large. Maximum allowed is 50MB.');
        return null;
      }
    }
  } catch (e) {
    onFail('Error recording video: $e');
  }

  return fileVideo;
}

Center buildDateTime(groupedByValue) {
  return Center(
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          formatDate(groupedByValue.timeSent, [dd, ' ', M, ', ', yyyy]),
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Widget messageToShow({required MessageEnum type, required String message}) {
  switch (type) {
    case MessageEnum.text:
      return Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    case MessageEnum.image:
      return const Row(
        children: [
          Icon(Icons.image_outlined),
          SizedBox(width: 10),
          Text(
            'Image',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    case MessageEnum.video:
      return const Row(
        children: [
          Icon(Icons.video_library_outlined),
          SizedBox(width: 10),
          Text(
            'Video',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    case MessageEnum.audio:
      return const Row(
        children: [
          Icon(Icons.audiotrack_outlined),
          SizedBox(width: 10),
          Text(
            'Audio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    default:
      return Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
  }
}

// Store file to Firebase Storage and return download URL
Future<String> storeFileToStorage({
  required File file,
  required String reference,
}) async {
  // Create upload task
  UploadTask uploadTask =
      FirebaseStorage.instance.ref().child(reference).putFile(file);
  
  // Set metadata for videos if needed
  if (reference.contains('video') || file.path.toLowerCase().endsWith('.mp4')) {
    uploadTask = FirebaseStorage.instance.ref().child(reference).putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );
  }
  
  // Monitor upload progress - could be connected to a progress indicator
  uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
    final progress = snapshot.bytesTransferred / snapshot.totalBytes;
    debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
  });
  
  // Wait for upload to complete
  TaskSnapshot taskSnapshot = await uploadTask;
  String fileUrl = await taskSnapshot.ref.getDownloadURL();
  return fileUrl;
}

// Format file size for display
String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Format duration for display
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

// animated dialog
void showMyAnimatedDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String textAction,
  required Function(bool) onActionTap,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation1, animation2) {
      return Container();
    },
    transitionBuilder: (context, animation1, animation2, child) {
      return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation1),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.5, end: 1.0).animate(animation1),
            child: AlertDialog(
              title: Text(
                title,
                textAlign: TextAlign.center,
              ),
              content: Text(
                content,
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onActionTap(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onActionTap(true);
                  },
                  child: Text(textAction),
                ),
              ],
            ),
          ));
    },
  );
}