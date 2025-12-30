import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:udp/udp.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: CameraSender(camera: cameras.first)));
}

class CameraSender extends StatefulWidget {
  final CameraDescription camera;
  const CameraSender({super.key, required this.camera});

  @override
  State<CameraSender> createState() => _CameraSenderState();
}

class _CameraSenderState extends State<CameraSender> {
  late CameraController _controller;
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.5"); // اكتب هنا الـ IP الظاهر في شاشة الكمبيوتر

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.low, enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  // هذه الدالة هي التي ترسل الصور للكمبيوتر
  void _startStreaming() async {
    var sender = await UDP.bind(Endpoint.any());
    
    _controller.startImageStream((CameraImage image) async {
      // تحويل الصورة لـ JPG مضغوط لإرسالها بسرعة
      final img.Image capturedImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.planes[0].bytes.buffer,
      );
      
      List<int> jpg = img.encodeJpg(capturedImage, quality: 50);
      
      // الإرسال للكمبيوتر على Port 5000
      await sender.send(jpg, Endpoint.unicast(InternetAddress(_ipController.text), port: const Port(5000)));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return Container();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "PC IP Address", labelStyle: TextStyle(color: Colors.cyan)),
            ),
          ),
          ElevatedButton(
            onPressed: _startStreaming,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text("START BROADCAST"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}