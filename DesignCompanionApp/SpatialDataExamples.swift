import Foundation
import RoomPlan
import simd

// MARK: - Practical Examples for Enhanced RoomPlan Spatial Data Usage

@available(iOS 16.0, *)
class SpatialDataExamples {

    // MARK: - Example 1: Finding Window Positions on Walls

    /// Example: Find all windows on a specific wall and their positions
    static func analyzeWindowPositions(roomData: RoomScanData) {
        print("🪟 Window Analysis:")

        for wall in roomData.spatialData.walls {
            let windowsOnWall = roomData.spatialData.windows(attachedTo: wall.identifier)

            if !windowsOnWall.isEmpty {
                print("Wall \(wall.identifier): \(windowsOnWall.count) windows")

                for window in windowsOnWall {
                    if let relativePos = window.relativePositionOnWall {
                        print("  • Window at \(String(format: "%.1f", relativePos.normalizedX * 100))% from left, \(String(format: "%.1f", relativePos.normalizedY * 100))% from bottom")
                        print("    Size: \(String(format: "%.2f", window.dimensions.width))m × \(String(format: "%.2f", window.dimensions.height))m")
                        print("    Distance from left edge: \(String(format: "%.2f", relativePos.distanceFromLeft))m")
                        print("    Distance from bottom: \(String(format: "%.2f", relativePos.distanceFromBottom))m")
                    }
                }
            }
        }
    }

    // MARK: - Example 2: Door-Wall Relationships

    /// Example: Analyze door placement and accessibility
    static func analyzeDoorPlacements(roomData: RoomScanData) {
        print("🚪 Door Analysis:")

        for door in roomData.spatialData.doors {
            guard let parentWallId = door.parentWallId,
                  let parentWall = roomData.spatialData.wall(withId: parentWallId) else {
                print("  • Door with no identified parent wall")
                continue
            }

            print("Door on wall \(parentWallId):")
            print("  • Door size: \(String(format: "%.2f", door.dimensions.width))m × \(String(format: "%.2f", door.dimensions.height))m")
            print("  • Wall size: \(String(format: "%.2f", parentWall.dimensions.width))m × \(String(format: "%.2f", parentWall.dimensions.height))m")

            if let normalizedPos = door.normalizedWallPosition {
                print("  • Position: \(String(format: "%.1f", normalizedPos.x * 100))% from wall left edge")

                // Check if door is centered on wall
                let centerThreshold: Float = 0.1 // 10% tolerance
                if abs(normalizedPos.x - 0.5) < centerThreshold {
                    print("  • ✅ Door is centered on wall")
                } else {
                    print("  • ℹ️  Door is offset from center")
                }
            }
        }
    }

    // MARK: - Example 3: Wall Corner Calculations

    /// Example: Get precise corner coordinates for furniture placement
    static func calculateWallCorners(roomData: RoomScanData) {
        print("📐 Wall Corner Analysis:")

        for (index, wall) in roomData.spatialData.walls.enumerated() {
            print("Wall \(index + 1) corners:")

            for (cornerIndex, corner) in wall.wallCorners.enumerated() {
                print("  Corner \(cornerIndex + 1): (\(String(format: "%.3f", corner.x)), \(String(format: "%.3f", corner.y)), \(String(format: "%.3f", corner.z)))")
            }

            // Calculate wall length using corner distance
            if wall.wallCorners.count >= 2 {
                let wallLength = wall.wallCorners[0].distance(to: wall.wallCorners[1])
                print("  Calculated wall length: \(String(format: "%.2f", wallLength))m")
            }
        }
    }

    // MARK: - Example 4: Room Layout Analysis

    /// Example: Analyze room layout for furniture placement suggestions
    static func analyzeRoomLayout(roomData: RoomScanData) -> RoomLayoutAnalysis {
        let spatialData = roomData.spatialData

        // Find the longest wall (good for large furniture)
        let longestWall = spatialData.walls.max { wall1, wall2 in
            wall1.dimensions.width < wall2.dimensions.width
        }

        // Find walls without windows/doors (best for furniture)
        let clearWalls = spatialData.walls.filter { wall in
            spatialData.elementsAttached(to: wall.identifier).isEmpty
        }

        // Calculate effective wall space (excluding openings)
        let effectiveWallArea = spatialData.effectiveWallArea

        // Find natural light sources
        let windowWalls = spatialData.walls.filter { wall in
            !spatialData.windows(attachedTo: wall.identifier).isEmpty
        }

        return RoomLayoutAnalysis(
            longestWall: longestWall,
            clearWalls: clearWalls,
            effectiveWallArea: effectiveWallArea,
            windowWalls: windowWalls,
            totalWindows: spatialData.windows.count,
            totalDoors: spatialData.doors.count
        )
    }

    // MARK: - Example 5: Spatial Relationships

    /// Example: Find spatial relationships between elements
    static func analyzeSpatialRelationships(roomData: RoomScanData) {
        print("🔗 Spatial Relationships:")

        for relationship in roomData.spatialData.surfaceRelationships {
            if let childElement = findElement(withId: relationship.childId, in: roomData.spatialData),
               let parentWall = roomData.spatialData.wall(withId: relationship.parentId) {

                print("\(childElement.type.rawValue.capitalized) is \(relationship.relationshipType.rawValue) wall")

                if let contactArea = relationship.spatialConnection.contactArea {
                    print("  Contact area: \(String(format: "%.2f", contactArea)) m²")
                }

                // Calculate percentage of wall occupied
                let wallArea = parentWall.area
                if let contactArea = relationship.spatialConnection.contactArea {
                    let percentage = (contactArea / wallArea) * 100
                    print("  Occupies \(String(format: "%.1f", percentage))% of wall area")
                }
            }
        }
    }

    // MARK: - Example 6: Natural Light Analysis

    /// Example: Analyze natural light distribution in the room
    static func analyzeNaturalLight(roomData: RoomScanData) -> NaturalLightAnalysis {
        let spatialData = roomData.spatialData

        var totalWindowArea: Float = 0
        var windowOrientations: [Position3D] = []

        for window in spatialData.windows {
            totalWindowArea += window.area

            // Get window orientation (normal vector of parent wall)
            if let parentWallId = window.parentWallId,
               let parentWall = spatialData.wall(withId: parentWallId) {
                windowOrientations.append(parentWall.normalVector)
            }
        }

        let roomFloorArea = roomData.dimensions.area
        let windowToFloorRatio = totalWindowArea / roomFloorArea

        // Classify room lighting
        let lightingQuality: LightingQuality
        if windowToFloorRatio > 0.15 {
            lightingQuality = .excellent
        } else if windowToFloorRatio > 0.10 {
            lightingQuality = .good
        } else if windowToFloorRatio > 0.05 {
            lightingQuality = .fair
        } else {
            lightingQuality = .poor
        }

        return NaturalLightAnalysis(
            totalWindowArea: totalWindowArea,
            windowToFloorRatio: windowToFloorRatio,
            lightingQuality: lightingQuality,
            windowOrientations: windowOrientations
        )
    }

    // MARK: - Helper Functions

    private static func findElement(withId id: UUID, in spatialData: RoomSpatialData) -> (type: ElementType, info: Any)? {
        if let door = spatialData.doors.first(where: { $0.identifier == id }) {
            return (.door, door)
        }
        if let window = spatialData.windows.first(where: { $0.identifier == id }) {
            return (.window, window)
        }
        if let opening = spatialData.openings.first(where: { $0.identifier == id }) {
            return (.opening, opening)
        }
        return nil
    }
}

// MARK: - Analysis Result Structures

@available(iOS 16.0, *)
struct RoomLayoutAnalysis {
    let longestWall: WallSpatialInfo?
    let clearWalls: [WallSpatialInfo]
    let effectiveWallArea: Float
    let windowWalls: [WallSpatialInfo]
    let totalWindows: Int
    let totalDoors: Int

    var hasGoodFurniturePlacement: Bool {
        return !clearWalls.isEmpty && effectiveWallArea > 10.0 // At least 10m² of clear wall space
    }

    var naturalLightSides: Int {
        return windowWalls.count
    }
}

@available(iOS 16.0, *)
struct NaturalLightAnalysis {
    let totalWindowArea: Float
    let windowToFloorRatio: Float
    let lightingQuality: LightingQuality
    let windowOrientations: [Position3D]

    var hasNaturalLight: Bool {
        return totalWindowArea > 0
    }

    var isWellLit: Bool {
        return lightingQuality == .excellent || lightingQuality == .good
    }
}

@available(iOS 16.0, *)
enum LightingQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    var description: String {
        switch self {
        case .excellent:
            return "Excellent natural lighting with large windows"
        case .good:
            return "Good natural lighting"
        case .fair:
            return "Fair natural lighting"
        case .poor:
            return "Limited natural lighting"
        }
    }
}

// MARK: - Usage Example in Your App

@available(iOS 16.0, *)
extension RoomScanData {
    /// Complete spatial analysis of the scanned room
    func performComprehensiveSpatialAnalysis() {
        print("🏠 === Comprehensive Room Spatial Analysis ===")

        // Basic room info
        print("Room Type: \(roomType)")
        print("Dimensions: \(String(format: "%.1f", dimensions.width))m × \(String(format: "%.1f", dimensions.depth))m × \(String(format: "%.1f", dimensions.height))m")
        print("Floor Area: \(String(format: "%.1f", dimensions.area)) m²")
        print("")

        // Detailed spatial analysis
        SpatialDataExamples.analyzeWindowPositions(roomData: self)
        print("")

        SpatialDataExamples.analyzeDoorPlacements(roomData: self)
        print("")

        SpatialDataExamples.calculateWallCorners(roomData: self)
        print("")

        let layoutAnalysis = SpatialDataExamples.analyzeRoomLayout(roomData: self)
        print("📋 Layout Analysis:")
        print("  Clear walls for furniture: \(layoutAnalysis.clearWalls.count)")
        print("  Effective wall area: \(String(format: "%.1f", layoutAnalysis.effectiveWallArea)) m²")
        print("  Natural light sides: \(layoutAnalysis.naturalLightSides)")
        print("  Good for furniture placement: \(layoutAnalysis.hasGoodFurniturePlacement ? "Yes" : "No")")
        print("")

        SpatialDataExamples.analyzeSpatialRelationships(roomData: self)
        print("")

        let lightAnalysis = SpatialDataExamples.analyzeNaturalLight(roomData: self)
        print("☀️ Natural Light Analysis:")
        print("  Total window area: \(String(format: "%.2f", lightAnalysis.totalWindowArea)) m²")
        print("  Window-to-floor ratio: \(String(format: "%.1f", lightAnalysis.windowToFloorRatio * 100))%")
        print("  Lighting quality: \(lightAnalysis.lightingQuality.description)")
        print("  Well lit: \(lightAnalysis.isWellLit ? "Yes" : "No")")
        print("")

        print("🏠 === Analysis Complete ===")
    }
}