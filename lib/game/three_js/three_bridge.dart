import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Dart interop bridge to the three.js scene manager (web/three_bridge.js).
///
/// All rendering commands flow through this class. The JS bridge exposes
/// methods on `window.ThreeBridge` that we call via `dart:js_interop`.
class ThreeBridge {
  ThreeBridge._();
  static final instance = ThreeBridge._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the three.js scene using the #three-canvas in the DOM.
  void initWithDomCanvas(int width, int height) {
    // Pass null as canvas — JS side will find #three-canvas
    _callMethod('init', [0.toJS, width.toJS, height.toJS]);
    _initialized = true;
  }

  /// Resize the renderer and camera.
  void resize(int width, int height) {
    _callMethod('resize', [width.toJS, height.toJS]);
  }

  /// Load a GLB model by ID and URL.
  Future<void> loadModel(String id, String url) {
    final completer = Completer<void>();
    final result = _callMethod('loadModel', [id.toJS, url.toJS]);
    if (result != null) {
      (result as JSPromise).toDart.then((_) {
        completer.complete();
      }).catchError((e) {
        completer.completeError('Failed to load model $id: $e');
      });
    } else {
      completer.completeError('ThreeBridge not available');
    }
    return completer.future;
  }

  /// Send a batched scene update (JSON-encoded).
  void syncScene(Map<String, dynamic> update) {
    final json = jsonEncode(update);
    _callMethod('syncScene', [json.toJS]);
  }

  /// Trigger a three.js render pass.
  void renderFrame() {
    _callMethod('renderFrame', []);
  }

  /// Check if a model is loaded in the JS cache.
  bool isModelLoaded(String modelId) {
    final result = _callMethod('isModelLoaded', [modelId.toJS]);
    if (result == null) return false;
    return (result as JSBoolean).toDart;
  }

  /// Clean up all three.js resources.
  void dispose() {
    _callMethod('dispose', []);
    _initialized = false;
  }

  // --- Private: call window.ThreeBridge.method(...) ---

  JSAny? _callMethod(String method, List<JSAny?> args) {
    final bridge = (web.window as JSObject)['ThreeBridge'] as JSObject?;
    if (bridge == null) return null;

    final fn = bridge[method] as JSFunction?;
    if (fn == null) return null;

    switch (args.length) {
      case 0:
        return fn.callAsFunction(bridge);
      case 1:
        return fn.callAsFunction(bridge, args[0]);
      case 2:
        return fn.callAsFunction(bridge, args[0], args[1]);
      case 3:
        return fn.callAsFunction(bridge, args[0], args[1], args[2]);
      default:
        return fn.callAsFunction(
            bridge, args[0], args[1], args[2], args[3]);
    }
  }
}
