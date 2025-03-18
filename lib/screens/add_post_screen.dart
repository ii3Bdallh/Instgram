import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/providers/user_provider.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:provider/provider.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  _selectImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ImageSelectionDialog(onImageSelected: (file) {
        setState(() {
          _file = file;
        });
      }),
    );
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    try {
      String res = await FireStoreMethods().uploadPost(
        _descriptionController.text,
        _file!,
        uid,
        username,
        profImage,
      );
      if (res == "success") {
        setState(() {
          isLoading = false;
          _file = null;
        });
        if (context.mounted) {
          showSnackBar(context, 'Posted!');
        }
        clearImage();
      } else {
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
        _file = null;
      });
      showSnackBar(context, err.toString());
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return _file == null
        ? Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, size: 28),
              label: const Text("Upload Image"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _selectImage(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: clearImage,
              ),
              title: const Text('Post to'),
              actions: [
                TextButton(
                  onPressed: () => postImage(
                    userProvider.getUser.uid,
                    userProvider.getUser.username,
                    userProvider.getUser.photoUrl,
                  ),
                  child: const Text(
                    "Post",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
            body: PostForm(
              file: _file!,
              isLoading: isLoading,
              descriptionController: _descriptionController,
              userProvider: userProvider,
            ),
          );
  }
}

class PostForm extends StatelessWidget {
  final Uint8List file;
  final bool isLoading;
  final TextEditingController descriptionController;
  final UserProvider userProvider;

  const PostForm({
    required this.file,
    required this.isLoading,
    required this.descriptionController,
    required this.userProvider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) const LinearProgressIndicator(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(file,
                width: double.infinity, height: 250, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              hintText: "Write a caption...",
              border: InputBorder.none,
            ),
            maxLines: 10,
          ),
        ],
      ),
    );
  }
}

class ImageSelectionDialog extends StatelessWidget {
  final Function(Uint8List) onImageSelected;
  const ImageSelectionDialog({required this.onImageSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
            title: const Text('Take a Photo'),
            onTap: () async {
              Navigator.pop(context);
              Uint8List file = await pickImage(ImageSource.camera);
              onImageSelected(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.green),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              Uint8List file = await pickImage(ImageSource.gallery);
              onImageSelected(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text("Cancel"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
