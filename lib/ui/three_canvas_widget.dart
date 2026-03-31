import 'package:flutter/widgets.dart';

import '../game/three_js/three_bridge.dart';

/// Widget that initializes the three.js scene on the #three-canvas
/// in the DOM (placed in index.html behind Flutter's rendering layer).
///
/// This widget is transparent — the 3D scene shows through behind
/// Flutter's transparent overlay widgets (HUD, menus, etc.).
class ThreeCanvasWidget extends StatefulWidget {
  final VoidCallback? onReady;

  const ThreeCanvasWidget({super.key, this.onReady});

  @override
  State<ThreeCanvasWidget> createState() => _ThreeCanvasWidgetState();
}

class _ThreeCanvasWidgetState extends State<ThreeCanvasWidget> {
  bool _bridgeReady = false;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Wait one frame for layout, then init the bridge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBridge();
    });
  }

  void _initBridge() {
    if (_bridgeReady || !mounted) return;

    final size = MediaQuery.of(context).size;
    final width = size.width.toInt();
    final height = size.height.toInt();

    if (width <= 0 || height <= 0) {
      // Retry next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _initBridge());
      return;
    }

    ThreeBridge.instance.initWithDomCanvas(width, height);
    ThreeBridge.instance.renderFrame();

    _bridgeReady = true;
    _lastSize = size;
    setState(() {});
    widget.onReady?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bridgeReady) return;
    final size = MediaQuery.of(context).size;
    if (size != _lastSize && size.width > 0 && size.height > 0) {
      _lastSize = size;
      ThreeBridge.instance.resize(size.width.toInt(), size.height.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent container — the three.js canvas is behind in the DOM
    return const SizedBox.expand();
  }
}
