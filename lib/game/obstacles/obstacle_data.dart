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
  });

  // Parking lot obstacles
  static const car = ObstacleData(
    type: ObstacleType.car,
    label: 'CAR',
    width: 2.2,
    height: 1.8,
    color: Color(0xFFD32F2F),
    accentColor: Color(0xFF212121),
  );

  static const shoppingCart = ObstacleData(
    type: ObstacleType.shoppingCart,
    label: 'CART',
    width: 1.2,
    height: 1.4,
    color: Color(0xFF9E9E9E),
    accentColor: Color(0xFF616161),
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
  );

  // Security obstacles
  static const barricade = ObstacleData(
    type: ObstacleType.barricade,
    label: 'STOP',
    width: 2.0,
    height: 1.5,
    color: Color(0xFFFF6F00),
    accentColor: Color(0xFFFFFFFF),
  );

  static const metalDetector = ObstacleData(
    type: ObstacleType.metalDetector,
    label: 'SCAN',
    width: 2.4,
    height: 2.5,
    color: Color(0xFF37474F),
    accentColor: Color(0xFF4CAF50),
  );

  static const bagCheckStation = ObstacleData(
    type: ObstacleType.bagCheckStation,
    label: 'CHECK',
    width: 2.5,
    height: 1.6,
    color: Color(0xFF455A64),
    accentColor: Color(0xFF90A4AE),
  );

  static const securityGate = ObstacleData(
    type: ObstacleType.securityGate,
    label: 'GATE',
    width: 2.8,
    height: 3.0,
    color: Color(0xFF37474F),
    accentColor: Color(0xFF4CAF50),
    spansAllLanes: true,
    blocksJump: true,
  );

  // Shop obstacles
  static const merchandiseRack = ObstacleData(
    type: ObstacleType.merchandiseRack,
    label: 'MERCH',
    width: 2.0,
    height: 2.2,
    color: Color(0xFF7B1FA2),
    accentColor: Color(0xFFE1BEE7),
  );

  static const foodCart = ObstacleData(
    type: ObstacleType.foodCart,
    label: 'FOOD',
    width: 1.8,
    height: 1.6,
    color: Color(0xFFE65100),
    accentColor: Color(0xFFFFCC80),
  );

  static const bench = ObstacleData(
    type: ObstacleType.bench,
    label: 'SEAT',
    width: 2.5,
    height: 0.5,
    color: Color(0xFF5D4037),
    accentColor: Color(0xFF8D6E63),
    requiresJump: true,
    spansAllLanes: true,
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
  );

  static const turnstile = ObstacleData(
    type: ObstacleType.turnstile,
    label: 'GATE',
    width: 1.5,
    height: 1.8,
    color: Color(0xFF78909C),
    accentColor: Color(0xFFB0BEC5),
  );

  static const ticketKiosk = ObstacleData(
    type: ObstacleType.ticketKiosk,
    label: 'TICKETS',
    width: 2.0,
    height: 2.4,
    color: Color(0xFF1565C0),
    accentColor: Color(0xFF42A5F5),
  );
}
