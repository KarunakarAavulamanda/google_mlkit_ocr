import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr/widgets/picker_option_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Variable that will store the text extracted from the image
  String _extractedText = '';

  /// Pick an image from a source
  _pickerImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Allow crop a image file
  _cropImage({required File imageFile}) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  /// Create a TextRecognizer instance and extract text from the image
  _recognizeTextFromImage({required String imgPath}) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final image = InputImage.fromFile(File(imgPath));
    final recognized = await textRecognizer.processImage(image);
    return recognized.text;
  }

  /// Process the image for text recognition
  _processImageExtractText({required ImageSource imageSource}) async {
    final imageFile = await _pickerImage(source: imageSource);
    if (imageFile == null) return;

    final croppedImage = await _cropImage(imageFile: imageFile);
    if (croppedImage == null) return;

    final recognizedText =
        await _recognizeTextFromImage(imgPath: croppedImage.path);
    if (recognizedText.trim().isEmpty || recognizedText.length < 5) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Text Found'),
            content: const Text(
                'This image does not contain any recognizable text or is too blurry.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() => _extractedText = recognizedText);
    }
  }

  /// Copy the extracted text to the clipboard
  void _copyToClipBoard() {
    Clipboard.setData(ClipboardData(text: _extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to Clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter OCR')),
      body: Column(
        children: [
          const Text(
            'Select an Option below for Gallery or Camera ',
            style: TextStyle(fontSize: 22.0),
          ),
          const SizedBox(height: 100.0),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PickerOptionWidget(
                  label: 'From Gallery',
                  color: Colors.blueAccent,
                  icon: Icons.image_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.gallery,
                  ),
                ),
                const SizedBox(width: 10.0),
                PickerOptionWidget(
                  label: 'From Camera',
                  color: Colors.redAccent,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.camera,
                  ),
                ),
              ],
            ),
          ),
          if (_extractedText.isNotEmpty) ...{
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Results', style: TextStyle(fontSize: 22.0)),
                  IconButton(
                    onPressed: _copyToClipBoard,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extracted Text:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_extractedText),
                      ],
                    ),
                  ),
                ),
              ),
            )
          },
        ],
      ),
    );
  }
}
