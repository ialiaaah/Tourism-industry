import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/models.dart';

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({Key? key}) : super(key: key);

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionsControllers = List.generate(4, (_) => TextEditingController());
  
  int _correctOptionIndex = 0;
  String _imagePath = '';
  XFile? _pickedFile;
  Uint8List? _webImageBytes;

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _pickedFile = image;
        _imagePath = image.path;
      });

      // For web, read bytes for preview
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _webImageBytes = bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected: ${image.name}')),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    if (_pickedFile == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No image selected', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb && _webImageBytes != null
          ? Image.memory(_webImageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(_pickedFile!.path), height: 150, width: double.infinity, fit: BoxFit.cover),
    );
  }

  void _saveStop() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop name required')));
      return;
    }

    QuizQuestion? quiz;
    if (_questionController.text.isNotEmpty) {
      final options = _optionsControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();
      if (options.length >= 2) {
        quiz = QuizQuestion(
          question: _questionController.text,
          options: options,
          correctOptionIndex: _correctOptionIndex >= options.length ? 0 : _correctOptionIndex,
        );
      }
    }

    final newStop = Stop(
      id: 'stop_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      description: _descController.text,
      imagePath: _imagePath.isNotEmpty ? _imagePath : 'assets/placeholder.jpg',
      quiz: quiz,
    );

    Navigator.pop(context, newStop);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Stop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Stop Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildImagePreview(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: Text(_pickedFile != null ? 'Change Image' : 'Upload Image from Device'),
            ),
            const Divider(height: 48, thickness: 2),
            const Text('Quiz Question (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctOptionIndex,
                      onChanged: (val) {
                        setState(() {
                          _correctOptionIndex = val!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionsControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveStop,
              child: const Text('Save Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
