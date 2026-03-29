import '../../config/game_config.dart';
import '../../config/theme.dart';
import '../obstacles/obstacle_data.dart';
import 'zone.dart';

class ZoneManager {
  late List<Zone> zones;
  int _currentZoneIndex = 0;

  ZoneManager() {
    zones = _buildZones();
  }

  Zone get currentZone => zones[_currentZoneIndex];

  void update(double distanceTraveled) {
    for (int i = zones.length - 1; i >= 0; i--) {
      if (zones[i].containsDistance(distanceTraveled)) {
        _currentZoneIndex = i;
        return;
      }
    }
    // Past all zones — stay on last
    _currentZoneIndex = zones.length - 1;
  }

  Zone getZoneAtDistance(double distance) {
    for (final zone in zones) {
      if (zone.containsDistance(distance)) return zone;
    }
    return zones.last;
  }

  /// Progress through the game as 0.0 to 1.0
  double getProgress(double distanceTraveled) {
    return (distanceTraveled / GameConfig.parkEntranceDistance).clamp(0.0, 1.0);
  }

  void reset() {
    _currentZoneIndex = 0;
  }

  List<Zone> _buildZones() {
    return [
      Zone(
        type: ZoneType.parkingLot,
        name: 'Parking Lot',
        startDistance: 0,
        endDistance: GameConfig.parkingLotEnd,
        speedMultiplier: 1.0,
        groundColor: GameTheme.parkingLotGround,
        roadColor: GameTheme.parkingLotRoad,
        spawnIntervalMin: 1.2,
        spawnIntervalMax: 2.0,
        obstaclePool: [
          ObstacleData.car,
          ObstacleData.shoppingCart,
          ObstacleData.speedBump,
        ],
      ),
      Zone(
        type: ZoneType.walkway,
        name: 'Walkway',
        startDistance: GameConfig.parkingLotEnd,
        endDistance: GameConfig.walkway1End,
        speedMultiplier: GameConfig.walkwaySpeedMultiplier,
        groundColor: GameTheme.walkwayGround,
        roadColor: GameTheme.walkwayRoad,
        isWalkway: true,
        reversesDirection: true,
        spawnIntervalMin: 2.0,
        spawnIntervalMax: 3.0,
        obstaclePool: [ObstacleData.shoppingCart],
      ),
      Zone(
        type: ZoneType.security,
        name: 'Security',
        startDistance: GameConfig.walkway1End,
        endDistance: GameConfig.securityEnd,
        speedMultiplier: 1.2,
        groundColor: GameTheme.securityGround,
        roadColor: GameTheme.securityRoad,
        spawnIntervalMin: 0.9,
        spawnIntervalMax: 1.6,
        obstaclePool: [
          ObstacleData.barricade,
          ObstacleData.metalDetector,
          ObstacleData.bagCheckStation,
        ],
      ),
      Zone(
        type: ZoneType.walkway,
        name: 'Walkway',
        startDistance: GameConfig.securityEnd,
        endDistance: GameConfig.walkway2End,
        speedMultiplier: GameConfig.walkwaySpeedMultiplier,
        groundColor: GameTheme.walkwayGround,
        roadColor: GameTheme.walkwayRoad,
        isWalkway: true,
        reversesDirection: true,
        spawnIntervalMin: 2.0,
        spawnIntervalMax: 3.0,
        obstaclePool: [ObstacleData.barricade],
      ),
      Zone(
        type: ZoneType.shops,
        name: 'Shops',
        startDistance: GameConfig.walkway2End,
        endDistance: GameConfig.shopsEnd,
        speedMultiplier: 1.4,
        groundColor: GameTheme.shopsGround,
        roadColor: GameTheme.shopsRoad,
        spawnIntervalMin: 0.7,
        spawnIntervalMax: 1.4,
        obstaclePool: [
          ObstacleData.merchandiseRack,
          ObstacleData.foodCart,
          ObstacleData.bench,
        ],
      ),
      Zone(
        type: ZoneType.walkway,
        name: 'Walkway',
        startDistance: GameConfig.shopsEnd,
        endDistance: GameConfig.walkway3End,
        speedMultiplier: GameConfig.walkwaySpeedMultiplier,
        groundColor: GameTheme.walkwayGround,
        roadColor: GameTheme.walkwayRoad,
        isWalkway: true,
        reversesDirection: true,
        spawnIntervalMin: 2.0,
        spawnIntervalMax: 3.0,
        obstaclePool: [ObstacleData.foodCart],
      ),
      Zone(
        type: ZoneType.ticketBooths,
        name: 'Ticket Booths',
        startDistance: GameConfig.walkway3End,
        endDistance: GameConfig.ticketBoothsEnd,
        speedMultiplier: 1.6,
        groundColor: GameTheme.ticketBoothsGround,
        roadColor: GameTheme.ticketBoothsRoad,
        spawnIntervalMin: 0.6,
        spawnIntervalMax: 1.2,
        obstaclePool: [
          ObstacleData.ropeLine,
          ObstacleData.turnstile,
          ObstacleData.ticketKiosk,
        ],
      ),
      Zone(
        type: ZoneType.walkway,
        name: 'Walkway',
        startDistance: GameConfig.ticketBoothsEnd,
        endDistance: GameConfig.walkway4End,
        speedMultiplier: GameConfig.walkwaySpeedMultiplier,
        groundColor: GameTheme.walkwayGround,
        roadColor: GameTheme.walkwayRoad,
        isWalkway: true,
        reversesDirection: true,
        spawnIntervalMin: 2.5,
        spawnIntervalMax: 3.5,
        obstaclePool: [ObstacleData.turnstile],
      ),
      Zone(
        type: ZoneType.parkEntrance,
        name: 'Park Entrance!',
        startDistance: GameConfig.walkway4End,
        endDistance: GameConfig.parkEntranceDistance + 100,
        speedMultiplier: 1.0,
        groundColor: GameTheme.parkEntranceGround,
        roadColor: GameTheme.parkEntranceRoad,
        spawnIntervalMin: 5.0,
        spawnIntervalMax: 10.0,
        obstaclePool: [],
      ),
    ];
  }
}
