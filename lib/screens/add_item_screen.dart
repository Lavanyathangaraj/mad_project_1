// add_item_screen.dart
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  io.File? _imageFile;
  Uint8List? _webImage; // for web
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (kIsWeb) {
      // Web: store bytes
      final bytes = await image.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      // Mobile/Desktop: store file
      setState(() => _imageFile = io.File(image.path));
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (kIsWeb && _webImage != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}-${_nameController.text}.jpg';
        final storageRef =
            FirebaseStorage.instance.ref().child('item_images').child(fileName);
        await storageRef.putData(_webImage!);
        imageUrl = await storageRef.getDownloadURL();
      } else if (!kIsWeb && _imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}-${_nameController.text}.jpg';
        final storageRef =
            FirebaseStorage.instance.ref().child('item_images').child(fileName);
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final newItem = Item(
        name: _nameController.text,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: imageUrl,
      );

      // Get current logged-in user ID
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Save to Firestore
      await FirebaseFirestore.instance.collection('items').add({
        ...newItem.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'sellerId': currentUserId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newItem.name} added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter price';
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    if (kIsWeb && _webImage != null)
                      Image.memory(_webImage!, height: 150, fit: BoxFit.cover)
                    else if (!kIsWeb && _imageFile != null)
                      Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
                    else
                      const Text('No image selected.'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
