import 'dart:ui';

enum ObstacleType {
  // Parking lot
  car,
  shoppingCart,
  speedBump,
  // Security
  barricade,
  metalDetector,
  bagCheckStation,
  securityGate,
  // Shops
  merchandiseRack,
  foodCart,
  bench,
  // Ticket booths
  ropeLine,
  turnstile,
  ticketKiosk,
}

class ObstacleData {
  final ObstacleType type;
  final String label;
  final double width;
  final double height;
  final Color color;
  final Color accentColor;
  final bool requiresJump; // must jump to avoid (e.g., speed bumps)
  final bool spansAllLanes; // blocks all lanes (jump-only)
  final bool blocksJump; // can't jump over — must go through opening
  final String spriteAssetName; // filename (without .png) in assets/images/obstacles/

  const ObstacleData({
    required this.type,
    required this.label,
    required this.width,
    required this.height,
    required this.color,
    this.accentColor = const Color(0xFF000000),
    this.requiresJump = false,
    this.spansAllLanes = false,
    this.blocksJump = false,
    this.spriteAssetName = '',
  });

  // Parking lot obstacles
  static const car = ObstacleData(
    type: ObstacleType.car,
    label: 'CAR',
    width: 2.2,
    height: 1.8,
    color: Color(0xFFD32F2F),
    accentColor: Color(0xFF212121),
    spriteAssetName: 'car',
  );

  static const shoppingCart = ObstacleData(
    type: ObstacleType.shoppingCart,
    label: 'CART',
    width: 1.2,
    height: 1.4,
    color: Color(0xFFBDBDBD),
    accentColor: Color(0xFF757575),
    spriteAssetName: 'shopping_cart',
  );

  static const speedBump = ObstacleData(
    type: ObstacleType.speedBump,
    label: 'BUMP',
    width: 2.8,
    height: 0.4,
    color: Color(0xFFFFEB3B),
    accentColor: Color(0xFF212121),
    requiresJump: true,
    spansAllLanes: true,
    spriteAssetName: 'speed_bump',
  );

  // Security obstacles
  static const barricade = ObstacleData(
    type: ObstacleType.barricade,
    label: 'STOP',
    width: 2.0,
    height: 1.5,
    color: Color(0xFFFF6F00),
    accentColor: Color(0xFFFFFFFF),
    spriteAssetName: 'barricade',
  );

  static const metalDetector = ObstacleData(
    type: ObstacleType.metalDetector,
    label: 'SCAN',
    width: 2.4,
    height: 2.5,
    color: Color(0xFF607D8B),
    accentColor: Color(0xFF4CAF50),
    spriteAssetName: 'metal_detector',
  );

  static const bagCheckStation = ObstacleData(
    type: ObstacleType.bagCheckStation,
    label: 'CHECK',
    width: 2.5,
    height: 1.6,
    color: Color(0xFF78909C),
    accentColor: Color(0xFF90A4AE),
    spriteAssetName: 'bag_check_station',
  );

  static const securityGate = ObstacleData(
    type: ObstacleType.securityGate,
    label: 'GATE',
    width: 2.8,
    height: 3.0,
    color: Color(0xFF607D8B),
    accentColor: Color(0xFF4CAF50),
    spansAllLanes: true,
    blocksJump: true,
    spriteAssetName: 'security_gate',
  );

  // Shop obstacles
  static const merchandiseRack = ObstacleData(
    type: ObstacleType.merchandiseRack,
    label: 'MERCH',
    width: 2.0,
    height: 2.2,
    color: Color(0xFF7B1FA2),
    accentColor: Color(0xFFE1BEE7),
    spriteAssetName: 'merchandise_rack',
  );

  static const foodCart = ObstacleData(
    type: ObstacleType.foodCart,
    label: 'FOOD',
    width: 1.8,
    height: 1.6,
    color: Color(0xFFE65100),
    accentColor: Color(0xFFFFCC80),
    spriteAssetName: 'food_cart',
  );

  static const bench = ObstacleData(
    type: ObstacleType.bench,
    label: 'SEAT',
    width: 2.5,
    height: 0.5,
    color: Color(0xFF8D6E63),
    accentColor: Color(0xFFA1887F),
    requiresJump: true,
    spansAllLanes: true,
    spriteAssetName: 'bench',
  );

  // Ticket booth obstacles
  static const ropeLine = ObstacleData(
    type: ObstacleType.ropeLine,
    label: 'ROPE',
    width: 2.8,
    height: 0.6,
    color: Color(0xFFC62828),
    accentColor: Color(0xFFFFD54F),
    requiresJump: true,
    spansAllLanes: true,
    spriteAssetName: 'rope_line',
  );

  static const turnstile = ObstacleData(
    type: ObstacleType.turnstile,
    label: 'GATE',
    width: 1.5,
    height: 1.8,
    color: Color(0xFFB0BEC5),
    accentColor: Color(0xFFCFD8DC),
    spriteAssetName: 'turnstile',
  );

  static const ticketKiosk = ObstacleData(
    type: ObstacleType.ticketKiosk,
    label: 'TICKETS',
    width: 2.0,
    height: 2.4,
    color: Color(0xFF42A5F5),
    accentColor: Color(0xFF90CAF9),
    spriteAssetName: 'ticket_kiosk',
  );
}
