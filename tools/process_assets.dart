import 'dart:io';
import 'package:image/image.dart' as img;

/// Kenney asset processor for Guesgger
/// Reads downloaded Kenney packs, processes them, and outputs
/// game-ready assets in the correct format and directory structure.

const kenneyDir = 'C:/Users/bette/AppData/Local/Temp/kenney_assets';
const outputDir = 'C:/Users/bette/Documents/GitHub/guesgger/assets/images';

void main() async {
  print('=== Kenney Asset Processor for Guesgger ===\n');

  // Create output directories
  for (final dir in [
    '$outputDir/obstacles',
    '$outputDir/player',
    '$outputDir/npcs',
    '$outputDir/ui',
  ]) {
    Directory(dir).createSync(recursive: true);
  }

  processObstacles();
  processPlayer();
  processNpcs();
  processUi();

  print('\n=== Done! ===');
}

// ---- OBSTACLES ----

void processObstacles() {
  print('--- Processing Obstacles ---');

  // Car: pixel-vehicle-pack sedan (side view, 29x13)
  _processObstacle(
    'car',
    '$kenneyDir/pixel-vehicle-pack/PNG/Cars/sedan.png',
    targetW: 256,
    targetH: 256,
    scale: 8,
  );

  // Shopping cart: game-icons (100x100)
  _processObstacle(
    'shopping_cart',
    '$kenneyDir/game-icons/PNG/White/2x/shoppingCart.png',
    targetW: 192,
    targetH: 192,
    scale: 0,
    useNearestNeighbor: false,
  );

  // Barricade: racing-pack barrier_red (210x62)
  _processObstacle(
    'barricade',
    '$kenneyDir/racing-pack/PNG/Objects/barrier_red.png',
    targetW: 256,
    targetH: 256,
    scale: 0,
    useNearestNeighbor: false,
  );

  // Speed bump: racing-pack arrow_yellow as a stand-in
  _processSpeedBump();

  // Bench: racing-pack tribune
  _processObstacle(
    'bench',
    '$kenneyDir/racing-pack/PNG/Objects/tribune_empty.png',
    targetW: 384,
    targetH: 128,
    scale: 0,
    useNearestNeighbor: false,
  );

  // Rope line: racing-pack barrier_white_race (striped barrier)
  _processObstacle(
    'rope_line',
    '$kenneyDir/racing-pack/PNG/Objects/barrier_white_race.png',
    targetW: 384,
    targetH: 192,
    scale: 0,
    useNearestNeighbor: false,
  );

  // Turnstile: gray L-shaped barrier arm
  _processFromRoguelikeTile('turnstile', tileIndex: 522, targetW: 192, targetH: 256, scale: 12);

  // Food cart: from roguelike-modern-city tiles (orange van/cart shape)
  _processFromRoguelikeTile('food_cart', tileIndex: 549, targetW: 256, targetH: 256, scale: 10);

  // Merchandise rack: roguelike-modern-city shelf tile
  _processFromRoguelikeTile('merchandise_rack', tileIndex: 446, targetW: 256, targetH: 256, scale: 10);

  // Metal detector: archway/doorframe tile
  _processFromRoguelikeTile('metal_detector', tileIndex: 583, targetW: 256, targetH: 320, scale: 12);

  // Security gate: doorframe gate tile
  _processFromRoguelikeTile('security_gate', tileIndex: 621, targetW: 256, targetH: 320, scale: 12);

  // Security gate blocked: solid wall/door
  _processFromRoguelikeTile('security_gate_blocked', tileIndex: 157, targetW: 256, targetH: 320, scale: 12);

  // Bag check station: table/counter tile
  _processFromRoguelikeTile('bag_check_station', tileIndex: 412, targetW: 256, targetH: 256, scale: 10);

  // Ticket kiosk: green machine with screen
  _processFromRoguelikeTile('ticket_kiosk', tileIndex: 734, targetW: 256, targetH: 320, scale: 12);
}

void _processObstacle(
  String name,
  String sourcePath, {
  required int targetW,
  required int targetH,
  int scale = 0,
  bool useNearestNeighbor = true,
}) {
  final file = File(sourcePath);
  if (!file.existsSync()) {
    print('  SKIP $name: source not found ($sourcePath)');
    return;
  }

  var src = img.decodePng(file.readAsBytesSync());
  if (src == null) {
    print('  SKIP $name: failed to decode');
    return;
  }

  img.Image result;

  if (scale > 0) {
    final scaledW = src.width * scale;
    final scaledH = src.height * scale;
    final scaled = img.copyResize(
      src,
      width: scaledW,
      height: scaledH,
      interpolation: useNearestNeighbor
          ? img.Interpolation.nearest
          : img.Interpolation.linear,
    );

    result = img.Image(width: targetW, height: targetH, numChannels: 4);
    img.compositeImage(
      result,
      scaled,
      dstX: (targetW - scaledW) ~/ 2,
      dstY: (targetH - scaledH) ~/ 2,
    );
  } else {
    final scaleX = targetW / src.width;
    final scaleY = targetH / src.height;
    final fitScale = scaleX < scaleY ? scaleX : scaleY;
    final newW = (src.width * fitScale * 0.85).round();
    final newH = (src.height * fitScale * 0.85).round();

    final scaled = img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: useNearestNeighbor
          ? img.Interpolation.nearest
          : img.Interpolation.linear,
    );

    result = img.Image(width: targetW, height: targetH, numChannels: 4);
    img.compositeImage(
      result,
      scaled,
      dstX: (targetW - newW) ~/ 2,
      dstY: (targetH - newH) ~/ 2,
    );
  }

  _savePng(result, '$outputDir/obstacles/$name.png');
  print('  OK $name (${targetW}x$targetH)');
}

void _processSpeedBump() {
  final file = File('$kenneyDir/racing-pack/PNG/Objects/arrow_yellow.png');
  if (!file.existsSync()) {
    print('  SKIP speed_bump: source not found');
    return;
  }
  var src = img.decodePng(file.readAsBytesSync());
  if (src == null) return;

  final scaled = img.copyResize(src, width: 340, height: 80, interpolation: img.Interpolation.linear);
  final result = img.Image(width: 384, height: 128, numChannels: 4);
  img.compositeImage(result, scaled, dstX: 22, dstY: 24);

  _savePng(result, '$outputDir/obstacles/speed_bump.png');
  print('  OK speed_bump (384x128)');
}

void _processFromRoguelikeTile(
  String name, {
  required int tileIndex,
  required int targetW,
  required int targetH,
  int scale = 10,
}) {
  final tilePath = '$kenneyDir/roguelike-modern-city/Tiles/tile_${tileIndex.toString().padLeft(4, '0')}.png';
  final file = File(tilePath);
  if (!file.existsSync()) {
    print('  SKIP $name: tile $tileIndex not found');
    return;
  }

  var src = img.decodePng(file.readAsBytesSync());
  if (src == null) {
    print('  SKIP $name: failed to decode tile');
    return;
  }

  final scaledW = src.width * scale;
  final scaledH = src.height * scale;
  final scaled = img.copyResize(
    src,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.nearest,
  );

  final result = img.Image(width: targetW, height: targetH, numChannels: 4);
  img.compositeImage(
    result,
    scaled,
    dstX: (targetW - scaledW) ~/ 2,
    dstY: (targetH - scaledH) ~/ 2,
  );

  _savePng(result, '$outputDir/obstacles/$name.png');
  print('  OK $name (${targetW}x$targetH) from tile $tileIndex');
}

// ---- PLAYER ----

void processPlayer() {
  print('\n--- Processing Player ---');

  final charDir = '$kenneyDir/pixel-vehicle-pack/PNG/Characters';

  final stand = _loadPng('$charDir/man.png');
  final walk1 = _loadPng('$charDir/man_walk1.png');
  final walk2 = _loadPng('$charDir/man_walk2.png');
  final fall = _loadPng('$charDir/man_fall.png');
  final down = _loadPng('$charDir/man_down.png');
  final point = _loadPng('$charDir/man_point.png');

  if (stand == null || walk1 == null || walk2 == null) {
    print('  SKIP player: missing character sprites');
    return;
  }

  const frameSize = 128;
  const pixelScale = 7;

  // run.png: 6 frames
  final runFrames = [stand, walk1, stand, walk2, walk1, walk2];
  final runSheet = _buildSpriteSheet(runFrames, frameSize, pixelScale);
  _savePng(runSheet, '$outputDir/player/run.png');
  print('  OK player/run.png (${runSheet.width}x${runSheet.height}, 6 frames)');

  // jump.png: 4 frames
  final jumpFrames = [point ?? stand, stand, fall ?? stand, stand];
  final jumpSheet = _buildSpriteSheet(jumpFrames, frameSize, pixelScale);
  _savePng(jumpSheet, '$outputDir/player/jump.png');
  print('  OK player/jump.png (${jumpSheet.width}x${jumpSheet.height}, 4 frames)');

  // idle.png: single frame
  final idleFrame = _scaleAndCenter(stand, frameSize, frameSize, pixelScale);
  _savePng(idleFrame, '$outputDir/player/idle.png');
  print('  OK player/idle.png (${frameSize}x$frameSize)');

  // hit.png: single frame
  final hitSrc = down ?? fall ?? stand;
  final hitFrame = _scaleAndCenter(hitSrc, frameSize, frameSize, pixelScale);
  _savePng(hitFrame, '$outputDir/player/hit.png');
  print('  OK player/hit.png (${frameSize}x$frameSize)');
}

// ---- NPCs ----

void processNpcs() {
  print('\n--- Processing NPCs ---');

  final charDir = '$kenneyDir/pixel-vehicle-pack/PNG/Characters';

  final stand = _loadPng('$charDir/woman.png');
  final walk1 = _loadPng('$charDir/woman_walk1.png');
  final walk2 = _loadPng('$charDir/woman_walk2.png');

  if (stand == null || walk1 == null || walk2 == null) {
    print('  SKIP walker: missing sprites');
    return;
  }

  const npcFrame = 96;
  const npcScale = 5;

  // All walk frames, no standing - keeps the animation visibly moving
  final walkerFrames = [walk1, walk2, walk1, walk2];
  final walkerSheet = _buildSpriteSheet(walkerFrames, npcFrame, npcScale);
  _savePng(walkerSheet, '$outputDir/npcs/walker.png');
  print('  OK npcs/walker.png (${walkerSheet.width}x${walkerSheet.height}, 4 frames)');

  final manPoint = _loadPng('$charDir/man_point.png');
  final secSrc = manPoint ?? _loadPng('$charDir/man.png');
  if (secSrc != null) {
    final secFrame = _scaleAndCenter(secSrc, npcFrame, npcFrame, npcScale);
    _savePng(secFrame, '$outputDir/npcs/security.png');
    print('  OK npcs/security.png (${npcFrame}x$npcFrame)');
  }
}

// ---- UI ----

void processUi() {
  print('\n--- Processing UI ---');

  // Button background
  final buttonSrc = _loadPng(
    '$kenneyDir/ui-pack/PNG/Blue/Double/button_rectangle_depth_flat.png',
  );
  if (buttonSrc != null) {
    final button = img.copyResize(buttonSrc, width: 256, height: 96, interpolation: img.Interpolation.linear);
    _savePng(button, '$outputDir/ui/button_bg.png');
    print('  OK ui/button_bg.png (256x96)');
  }

  // Hearts from 1-bit pack
  _extractHearts();
}

void _extractHearts() {
  // Generate pixel art hearts programmatically in the Kenney pixel art style
  // 12x12 pixel art heart, scaled to 48x48 (4x nearest neighbor)
  const size = 12;
  // Heart shape bitmap (1 = filled, 0 = empty)
  final heartShape = [
    [0,0,1,1,0,0,0,1,1,0,0,0],
    [0,1,1,1,1,0,1,1,1,1,0,0],
    [1,1,1,1,1,1,1,1,1,1,1,0],
    [1,1,1,1,1,1,1,1,1,1,1,0],
    [1,1,1,1,1,1,1,1,1,1,1,0],
    [0,1,1,1,1,1,1,1,1,1,0,0],
    [0,0,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,0,0,0,0],
    [0,0,0,0,1,1,1,0,0,0,0,0],
    [0,0,0,0,0,1,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0],
  ];

  // Heart full: red with darker red outline
  final heartFullSmall = img.Image(width: size, height: size, numChannels: 4);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (heartShape[y][x] == 1) {
        // Check if edge pixel (adjacent to empty)
        bool isEdge = false;
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nx = x + d[0], ny = y + d[1];
          if (nx < 0 || nx >= size || ny < 0 || ny >= size || heartShape[ny][nx] == 0) {
            isEdge = true;
            break;
          }
        }
        if (isEdge) {
          heartFullSmall.setPixelRgba(x, y, 180, 20, 20, 255); // dark red edge
        } else {
          // Slight highlight on top-left
          if (y <= 3 && x <= 4) {
            heartFullSmall.setPixelRgba(x, y, 255, 80, 80, 255); // lighter red
          } else {
            heartFullSmall.setPixelRgba(x, y, 230, 40, 40, 255); // main red
          }
        }
      }
    }
  }

  final heartFull = img.copyResize(heartFullSmall, width: 48, height: 48, interpolation: img.Interpolation.nearest);
  _savePng(heartFull, '$outputDir/ui/heart_full.png');
  print('  OK ui/heart_full.png (48x48, pixel art heart)');

  // Heart empty: gray outline only
  final heartEmptySmall = img.Image(width: size, height: size, numChannels: 4);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (heartShape[y][x] == 1) {
        bool isEdge = false;
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nx = x + d[0], ny = y + d[1];
          if (nx < 0 || nx >= size || ny < 0 || ny >= size || heartShape[ny][nx] == 0) {
            isEdge = true;
            break;
          }
        }
        if (isEdge) {
          heartEmptySmall.setPixelRgba(x, y, 80, 80, 80, 255); // gray outline
        } else {
          heartEmptySmall.setPixelRgba(x, y, 40, 40, 40, 180); // dark fill
        }
      }
    }
  }

  final heartEmpty = img.copyResize(heartEmptySmall, width: 48, height: 48, interpolation: img.Interpolation.nearest);
  _savePng(heartEmpty, '$outputDir/ui/heart_empty.png');
  print('  OK ui/heart_empty.png (48x48, pixel art heart)');
}

// ---- HELPERS ----

img.Image? _loadPng(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return img.decodePng(file.readAsBytesSync());
}

void _savePng(img.Image image, String path) {
  File(path).writeAsBytesSync(img.encodePng(image));
}

img.Image _scaleAndCenter(img.Image src, int targetW, int targetH, int scale) {
  final scaledW = src.width * scale;
  final scaledH = src.height * scale;
  final scaled = img.copyResize(
    src,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.nearest,
  );

  final result = img.Image(width: targetW, height: targetH, numChannels: 4);
  img.compositeImage(
    result,
    scaled,
    dstX: (targetW - scaledW) ~/ 2,
    dstY: (targetH - scaledH) ~/ 2,
  );
  return result;
}

img.Image _buildSpriteSheet(List<img.Image> frames, int frameSize, int scale) {
  final sheetWidth = frameSize * frames.length;
  final sheet = img.Image(width: sheetWidth, height: frameSize, numChannels: 4);

  for (int i = 0; i < frames.length; i++) {
    final frame = _scaleAndCenter(frames[i], frameSize, frameSize, scale);
    img.compositeImage(sheet, frame, dstX: i * frameSize, dstY: 0);
  }

  return sheet;
}

img.Image _tintImage(img.Image src, int tr, int tg, int tb) {
  final result = img.Image.from(src);
  for (int y = 0; y < result.height; y++) {
    for (int x = 0; x < result.width; x++) {
      final p = result.getPixel(x, y);
      final a = p.a.toInt();
      if (a > 0) {
        final r = ((p.r.toInt() * 0.3) + (tr * 0.7)).round().clamp(0, 255);
        final g = ((p.g.toInt() * 0.3) + (tg * 0.7)).round().clamp(0, 255);
        final b = ((p.b.toInt() * 0.3) + (tb * 0.7)).round().clamp(0, 255);
        result.setPixelRgba(x, y, r, g, b, a);
      }
    }
  }
  return result;
}

img.Image _desaturate(img.Image src) {
  final result = img.Image.from(src);
  for (int y = 0; y < result.height; y++) {
    for (int x = 0; x < result.width; x++) {
      final p = result.getPixel(x, y);
      final a = p.a.toInt();
      if (a > 0) {
        final gray = (p.r.toInt() * 0.3 + p.g.toInt() * 0.59 + p.b.toInt() * 0.11).round();
        final darkGray = (gray * 0.5).round().clamp(0, 255);
        result.setPixelRgba(x, y, darkGray, darkGray, darkGray, a);
      }
    }
  }
  return result;
}
