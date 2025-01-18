import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AR Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;

  // Variables for preview mode
  bool isPlacingModel = false;
  vector_math.Vector3 previewPosition = vector_math.Vector3(0.0, 0.0, -1.0);
  vector_math.Vector3 previewScale = vector_math.Vector3(0.5, 0.5, 0.5);
  double previewRotationY = 0.0;

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
          ),
          if (isPlacingModel)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    previewPosition.x += details.delta.dx * 0.001; // Adjust movement scale
                    previewPosition.y -= details.delta.dy * 0.001;
                  });
                },
                onScaleUpdate: (details) {
                  setState(() {
                    previewScale *= details.scale;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    previewRotationY += details.delta.dx * 0.5; // Adjust rotation sensitivity
                  });
                },
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: isPlacingModel
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    onPressed: _placeModel,
                    backgroundColor: Colors.green,
                    label: const Text(
                      "Place Model",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                  ),
                  FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        isPlacingModel = false;
                      });
                    },
                    backgroundColor: Colors.red,
                    label: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              )
                  : FloatingActionButton.extended(
                onPressed: _startPlacingModel,
                backgroundColor: Colors.deepPurple,
                label: const Text(
                  "Add 3D Model",
                  style: TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;

    _arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: true,
    );
    _arObjectManager?.onInitialize();
  }

  void _startPlacingModel() {
    setState(() {
      isPlacingModel = true;
    });
  }

  void _placeModel() async {
    final newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: "path/to/your/model.gltf", // Update with your model path
      scale: previewScale,
      position: previewPosition,
      rotation: vector_math.Vector4(0, 1, 0, previewRotationY), // Rotation in Y axis
    );

    bool? didAddNode = await _arObjectManager?.addNode(newNode);
    if (didAddNode != null && didAddNode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model added successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add model.")),
      );
    }

    setState(() {
      isPlacingModel = false;
    });
  }
}
