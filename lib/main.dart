import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DashboardHome(),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  dynamic _outputs;
  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  classifyImage(File? image) async {
    if (image != null) {
      var output = await Tflite.runModelOnImage(
          path: image.path,
          imageMean: 0.0,
          imageStd: 255.0,
          numResults: 2,
          threshold: 0.2,
          asynch: true);
      setState(() {
        _loading = false;
        _outputs = output;
      });
    }
  }

  void pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(_image);
  }

  @override
  void initState() {
    super.initState();
    _loading = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadModel().then((value) {
      debugPrint('selesai');
      setState(() {
        _loading = false;
      });
    }).onError((error, stackTrace) {
      debugPrint('onError: $error');
    }).catchError((message) {
      debugPrint('catchError: $message');
    });
  }

  Future<void> loadModel() async => await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      numThreads: 1, // defaults to 1
      isAsset:
          true, // defaults to true, set to false to load resources outside assets
      useGpuDelegate:
          false // defaults to false, set to true to use GPU delegate
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Tensorflow Lite",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _loading
                  ? const SizedBox()
                  : Container(
                      margin: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _image == null ? Container() : Image.file(_image!),
                          const SizedBox(height: 20),
                          _image == null
                              ? Container()
                              : _outputs != null
                                  ? Text(
                                      _outputs[0]["label"],
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 20),
                                    )
                                  : const Text("")
                        ],
                      ),
                    ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              FloatingActionButton(
                tooltip: 'Pick Image',
                onPressed: pickImage,
                child: const Icon(
                  Icons.add_a_photo,
                  size: 20,
                  color: Colors.white,
                ),
                backgroundColor: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
