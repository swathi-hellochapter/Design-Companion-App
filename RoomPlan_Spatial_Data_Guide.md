# RoomPlan Enhanced Spatial Data Guide

## Overview

This guide provides comprehensive information about the detailed spatial data available from Apple's RoomPlan CapturedRoom object and how to use the enhanced data structures in your Design Companion App.

## Key Spatial Properties Available

### 1. CapturedRoom.walls Properties
- **transform**: 4x4 matrix defining position and orientation in 3D space
- **dimensions**: simd_float3 with (width, height, depth) in meters
- **identifier**: UUID for unique identification
- **confidence**: Detection confidence level (0.0 to 1.0)
- **polygon** (iOS 17+): For curved/complex wall shapes

### 2. CapturedRoom.windows Properties
- **transform**: 4x4 matrix for position and orientation
- **dimensions**: simd_float3 with (width, height, depth) in meters
- **identifier**: UUID for unique identification
- **confidence**: Detection confidence level
- **parent** (iOS 17+): Reference to the wall it's positioned on

### 3. CapturedRoom.doors Properties
- **transform**: 4x4 matrix for position and orientation
- **dimensions**: simd_float3 with (width, height, depth) in meters
- **identifier**: UUID for unique identification
- **confidence**: Detection confidence level
- **parent** (iOS 17+): Reference to the wall it's positioned on

## Transform Matrix Breakdown

The 4x4 transform matrix contains:
- **Column 0**: Right vector (X-axis orientation)
- **Column 1**: Up vector (Y-axis orientation)
- **Column 2**: Forward vector (Z-axis orientation)
- **Column 3**: Position vector (X, Y, Z coordinates)

```swift
let transform = surface.transform
let position = Position3D(
    x: transform.columns.3.x,
    y: transform.columns.3.y,
    z: transform.columns.3.z
)
let rightVector = Position3D(
    x: transform.columns.0.x,
    y: transform.columns.0.y,
    z: transform.columns.0.z
)
```

## Enhanced Data Structures

### RoomSpatialData
The main container for all spatial information:
```swift
struct RoomSpatialData {
    let walls: [WallSpatialInfo]
    let doors: [SurfaceSpatialInfo]
    let windows: [SurfaceSpatialInfo]
    let openings: [SurfaceSpatialInfo]
    let surfaceRelationships: [SurfaceRelationship]
}
```

### WallSpatialInfo
Enhanced wall information with spatial context:
```swift
struct WallSpatialInfo {
    let identifier: UUID
    let position: Position3D
    let dimensions: Dimensions3D
    let orientation: Orientation3D
    let corners: [Position3D]        // All 8 corners of wall bounding box
    let attachedElements: [AttachedElement]  // Windows/doors on this wall
    let confidence: Float
}
```

### SurfaceSpatialInfo
Enhanced surface information for doors, windows, openings:
```swift
struct SurfaceSpatialInfo {
    let identifier: UUID
    let position: Position3D
    let dimensions: Dimensions3D
    let orientation: Orientation3D
    let corners: [Position3D]
    let parentWallId: UUID?              // Which wall this is attached to
    let relativePositionOnWall: RelativePosition?  // Position relative to wall
    let confidence: Float
}
```

### RelativePosition
Precise positioning on walls:
```swift
struct RelativePosition {
    let distanceFromLeft: Float      // Absolute distance from left edge (meters)
    let distanceFromBottom: Float    // Absolute distance from bottom edge (meters)
    let normalizedX: Float          // 0.0 to 1.0 position along wall width
    let normalizedY: Float          // 0.0 to 1.0 position along wall height
}
```

## Determining Wall-Window/Door Relationships

### Method 1: Using Parent Property (iOS 17+)
```swift
// Direct parent reference available in iOS 17+
if #available(iOS 17.0, *) {
    for window in capturedRoom.windows {
        if let parentWall = window.parent as? CapturedRoom.Surface {
            print("Window is on wall: \(parentWall.identifier)")
        }
    }
}
```

### Method 2: Spatial Analysis (All iOS Versions)
```swift
// Our enhanced approach using spatial proximity
for window in roomData.spatialData.windows {
    if let parentWallId = window.parentWallId {
        print("Window is on wall: \(parentWallId)")

        if let relativePos = window.relativePositionOnWall {
            print("Position: \(relativePos.normalizedX * 100)% from left")
        }
    }
}
```

## Practical Usage Examples

### 1. Finding Windows on Specific Walls
```swift
let roomData = RoomScanData(from: capturedRoom)

// Find all windows on a specific wall
for wall in roomData.spatialData.walls {
    let windowsOnWall = roomData.spatialData.windows(attachedTo: wall.identifier)
    print("Wall has \(windowsOnWall.count) windows")

    for window in windowsOnWall {
        if let pos = window.normalizedWallPosition {
            print("Window at \(pos.x * 100)% from left, \(pos.y * 100)% from bottom")
        }
    }
}
```

### 2. Calculating Corner Coordinates
```swift
// Get precise corner coordinates for each wall
for wall in roomData.spatialData.walls {
    for (index, corner) in wall.wallCorners.enumerated() {
        print("Corner \(index): (\(corner.x), \(corner.y), \(corner.z))")
    }
}
```

### 3. Analyzing Room Layout for Furniture Placement
```swift
let layoutAnalysis = SpatialDataExamples.analyzeRoomLayout(roomData: roomData)

// Find walls without windows/doors (best for furniture)
print("Clear walls: \(layoutAnalysis.clearWalls.count)")
print("Effective wall area: \(layoutAnalysis.effectiveWallArea) m²")

// Find the longest wall
if let longestWall = layoutAnalysis.longestWall {
    print("Longest wall: \(longestWall.dimensions.width)m")
}
```

### 4. Natural Light Analysis
```swift
let lightAnalysis = SpatialDataExamples.analyzeNaturalLight(roomData: roomData)

print("Window-to-floor ratio: \(lightAnalysis.windowToFloorRatio * 100)%")
print("Lighting quality: \(lightAnalysis.lightingQuality.description)")
print("Well lit: \(lightAnalysis.isWellLit)")
```

### 5. Spatial Relationships
```swift
// Analyze relationships between elements
for relationship in roomData.spatialData.surfaceRelationships {
    print("Element \(relationship.childId) is \(relationship.relationshipType.rawValue) wall \(relationship.parentId)")

    if let contactArea = relationship.spatialConnection.contactArea {
        print("Contact area: \(contactArea) m²")
    }
}
```

## Advanced Spatial Calculations

### Distance Between Elements
```swift
let door = roomData.spatialData.doors.first!
let window = roomData.spatialData.windows.first!

let distance = door.position.distance(to: window.position)
print("Distance between door and window: \(distance)m")
```

### Wall Normal Vectors
```swift
for wall in roomData.spatialData.walls {
    let normal = wall.normalVector
    print("Wall normal: (\(normal.x), \(normal.y), \(normal.z))")
}
```

### Effective Wall Space Calculation
```swift
// Calculate usable wall space excluding openings
let effectiveArea = roomData.spatialData.effectiveWallArea
print("Effective wall space: \(effectiveArea) m²")
```

## Coordinate Systems and Units

- **Units**: All measurements are in meters
- **Coordinate System**: Right-handed coordinate system
- **Origin**: Relative to the room's coordinate space as determined by RoomPlan
- **Y-Axis**: Typically represents height (up direction)
- **Transform Matrices**: 4x4 matrices in column-major format

## Best Practices

### 1. Always Check Availability
```swift
@available(iOS 16.0, *)
func processRoomData(_ capturedRoom: CapturedRoom) {
    let roomData = RoomScanData(from: capturedRoom)
    // Process spatial data
}
```

### 2. Handle Missing Parent Relationships
```swift
for window in roomData.spatialData.windows {
    if let parentWallId = window.parentWallId {
        // Process window with known parent wall
    } else {
        // Handle orphaned window (no clear parent wall found)
        print("Warning: Window without clear parent wall")
    }
}
```

### 3. Use Confidence Levels
```swift
for wall in roomData.spatialData.walls {
    if wall.confidence > 0.8 {
        // High confidence detection
    } else {
        // Lower confidence, handle accordingly
        print("Warning: Low confidence wall detection")
    }
}
```

### 4. Validate Spatial Relationships
```swift
// Ensure spatial relationships make sense
for relationship in roomData.spatialData.surfaceRelationships {
    if let contactArea = relationship.spatialConnection.contactArea,
       contactArea > 0 {
        // Valid spatial connection
    }
}
```

## Integration with Design Workflow

The enhanced spatial data can be used to:

1. **Furniture Placement**: Identify optimal locations for furniture based on wall dimensions and clearances
2. **Lighting Analysis**: Determine natural light sources and placement for artificial lighting
3. **Space Planning**: Calculate effective usable space considering doors, windows, and openings
4. **Architectural Analysis**: Understand room proportions and architectural features
5. **AR Visualization**: Place virtual objects with precise spatial positioning

## Performance Considerations

- **Lazy Loading**: Spatial calculations are performed once during RoomScanData initialization
- **Memory Usage**: Corner calculations create arrays of Position3D objects
- **Processing Time**: Complex spatial analysis may take additional time for large rooms
- **Caching**: Consider caching spatial analysis results for repeated use

## Error Handling

```swift
// Handle cases where spatial relationships cannot be determined
guard roomData.spatialData.walls.count > 0 else {
    print("No walls detected in room scan")
    return
}

// Validate window-wall relationships
for window in roomData.spatialData.windows {
    guard window.parentWallId != nil else {
        print("Warning: Window with no parent wall relationship")
        continue
    }
}
```

This enhanced spatial data system provides the foundation for sophisticated spatial analysis and design workflows in your Design Companion App.