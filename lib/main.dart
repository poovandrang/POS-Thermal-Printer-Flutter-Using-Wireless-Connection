import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:image/image.dart' as img; // Alias for the 'image' package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS PRINTER',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _printImage() async {
    if (_ipController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter the printer IP address.');
      return;
    }

    if (_image == null && _textController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Please select an image or enter text to print.');
      return;
    }

    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final connect = await printer.connect(_ipController.text, port: 9100);
    if (connect == PosPrintResult.success) {
      if (_textController.text.isNotEmpty) {
        printer.text(
          _textController.text,
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
          linesAfter: 1,
        );
      }

      if (_image != null) {
        final img.Image? image = img.decodeImage(_image!.readAsBytesSync());
        if (image != null) {
          printer.imageRaster(image);
        } else {
          Fluttertoast.showToast(msg: 'Failed to decode image.');
        }
      }

      printer.cut();
      printer.disconnect();
      Fluttertoast.showToast(msg: 'Print successful.');
    } else {
      Fluttertoast.showToast(msg: 'Failed to connect to the printer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POS PRINTER'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(labelText: 'Printer IP Address'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Text to Print'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),
            _image != null ? Image.file(_image!) : Container(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printImage,
              child: Text('Print Image and Text'),
            ),
          ],
        ),
      ),
    );
  }
}
