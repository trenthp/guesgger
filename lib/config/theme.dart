import 'dart:ui';

class GameTheme {
  // Sky — late-afternoon golden hour
  static const Color skyTop = Color(0xFF3B3568);
  static const Color skyMid = Color(0xFF7A4A6E);
  static const Color skyBottom = Color(0xFFD17A45);

  // Hot pink/orange sunset horizon
  static const Color horizonGlow = Color(0xFFFFB066);

  // Dusk palette — used when daylight drops near park closing
  static const Color skyTopDusk = Color(0xFF0E0F26);
  static const Color skyMidDusk = Color(0xFF26143A);
  static const Color skyBottomDusk = Color(0xFF4A1830);
  static const Color horizonGlowDusk = Color(0xFF7A2030);

  // Zone ground colors — warmer, sunlit-asphalt tones
  static const Color parkingLotGround = Color(0xFF4A3D32);
  static const Color parkingLotRoad = Color(0xFF2E2620);
  static const Color securityGround = Color(0xFF3F3C42);
  static const Color securityRoad = Color(0xFF26252C);
  static const Color shopsGround = Color(0xFF5C4226);
  static const Color shopsRoad = Color(0xFF3A2A18);
  static const Color ticketBoothsGround = Color(0xFF2E4530);
  static const Color ticketBoothsRoad = Color(0xFF1C2E20);
  // Walkway — metallic moving walkway / travelator
  static const Color walkwayGround = Color(0xFF494A55);
  static const Color walkwayRoad = Color(0xFF8B95A3);
  static const Color parkEntranceGround = Color(0xFF2E6B30);
  static const Color parkEntranceRoad = Color(0xFF3D8A40);

  // Lane markers
  static const Color laneMarker = Color(0xAAFFFFFF);
  static const Color roadEdge = Color(0xBBFFFFFF);

  // Player (more vivid)
  static const Color playerBody = Color(0xFF00BCD4);
  static const Color playerBodyHighlight = Color(0xFF26C6DA);
  static const Color playerHead = Color(0xFFFFCC80);
  static const Color playerLegs = Color(0xFF00838F);
  static const Color playerArms = Color(0xFF0097A7);
  static const Color playerBackpack = Color(0xFFFF6F00);
  static const Color playerTrail = Color(0x4000BCD4);

  // HUD (glassmorphism)
  static const Color hudBackground = Color(0x44000000);
  static const Color hudBorder = Color(0x33FFFFFF);
  static const Color hudText = Color(0xFFFFFFFF);
  static const Color hudAccent = Color(0xFF00E5FF);
  static const Color heartFull = Color(0xFFFF1744);
  static const Color heartEmpty = Color(0xFF37474F);
  static const Color heartGlow = Color(0x66FF1744);
  static const Color progressBar = Color(0xFF00E676);
  static const Color progressBarBg = Color(0x33FFFFFF);

  // Zone accent colors (for ambient effects)
  static const Color parkingAccent = Color(0xFFFFEB3B);
  static const Color securityAccent = Color(0xFF2196F3);
  static const Color shopsAccent = Color(0xFFFF9800);
  static const Color ticketAccent = Color(0xFF9C27B0);
  static const Color walkwayAccent = Color(0xFF78909C);
  static const Color entranceAccent = Color(0xFF4CAF50);

  // Zone ambient light colors — warm late-afternoon cast
  static const Color parkingLotAmbient = Color(0xFFE6C8A0);
  static const Color securityAmbient = Color(0xFFC8B8A0);
  static const Color shopsAmbient = Color(0xFFFFCC8C);
  static const Color ticketBoothsAmbient = Color(0xFFD8C098);
  static const Color walkwayAmbient = Color(0xFFD0BCA8);
  static const Color parkEntranceAmbient = Color(0xFFC8D098);

  // Zone fog colors — golden-hour dust, deepens to dusk
  static const Color parkingLotFog = Color(0xFFA47452);
  static const Color securityFog = Color(0xFF806B62);
  static const Color shopsFog = Color(0xFFC8855A);
  static const Color ticketBoothsFog = Color(0xFF8A8A5E);
  static const Color walkwayFog = Color(0xFF8E7C82);
  static const Color parkEntranceFog = Color(0xFF6B8862);

  // UI gradients
  static const Color menuGradientTop = Color(0xFF0A0E27);
  static const Color menuGradientMid = Color(0xFF1A1A4E);
  static const Color menuGradientBottom = Color(0xFF0D2137);
  static const Color gameOverGradientTop = Color(0xFF1A0000);
  static const Color gameOverGradientBottom = Color(0xFF2D0A1E);
  static const Color winGradientTop = Color(0xFF0A1A00);
  static const Color winGradientBottom = Color(0xFF0D2E0A);

  // Button colors
  static const Color buttonPrimary = Color(0xFFFF6F00);
  static const Color buttonPrimaryGlow = Color(0x66FF6F00);
  static const Color buttonSecondary = Color(0xFF00BCD4);
  static const Color buttonSecondaryGlow = Color(0x6600BCD4);

  // Scenery
  static const Color treeTrunk = Color(0xFF4E342E);
  static const Color treeLeaves = Color(0xFF2E7D32);
  static const Color treeLeavesLight = Color(0xFF43A047);
  static const Color lampPost = Color(0xFF424242);
  static const Color lampGlow = Color(0xFFFFE082);
  static const Color fenceColor = Color(0xFF5D4037);
}
