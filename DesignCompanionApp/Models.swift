import Foundation
import UIKit
import RoomPlan
import simd

enum APIError: Error {
    case saveFailed
    case networkError
    case processingFailed
    case uploadFailed
    case invalidResponse
    case invalidData
}

struct LIDARData: Codable {
    let id = UUID()
    let roomDimensions: RoomDimensions
    let pointCloud: [LIDARPoint]
    let timestamp: Date
    let roomType: String
    let roomFeatures: RoomFeatures
    let spatialLayout: RoomSpatialLayout?

    init(roomDimensions: RoomDimensions, pointCloud: [LIDARPoint] = [], roomType: String = "living_room", roomFeatures: RoomFeatures, spatialLayout: RoomSpatialLayout? = nil) {
        self.roomDimensions = roomDimensions
        self.pointCloud = pointCloud
        self.timestamp = Date()
        self.roomType = roomType
        self.roomFeatures = roomFeatures
        self.spatialLayout = spatialLayout
    }

    enum CodingKeys: String, CodingKey {
        case id
        case roomDimensions = "room_dimensions"
        case pointCloud = "point_cloud"
        case timestamp
        case roomType = "room_type"
        case roomFeatures = "room_features"
        case spatialLayout = "spatial_layout"
    }
}

struct RoomDimensions: Codable {
    let width: Float
    let height: Float
    let depth: Float
    let area: Float

    init(width: Float, height: Float, depth: Float) {
        self.width = width
        self.height = height
        self.depth = depth
        self.area = width * depth
    }
}

struct LIDARPoint: Codable {
    let x: Float
    let y: Float
    let z: Float
    let confidence: Float

    init(x: Float, y: Float, z: Float, confidence: Float = 1.0) {
        self.x = x
        self.y = y
        self.z = z
        self.confidence = confidence
    }
}

struct StyleReference: Codable {
    let images: [String]
    let urls: [String]
    let styleKeywords: [String]
    let userThoughts: String?

    init(images: [String] = [], urls: [String] = [], styleKeywords: [String] = [], userThoughts: String? = nil) {
        self.images = images
        self.urls = urls
        self.styleKeywords = styleKeywords
        self.userThoughts = userThoughts
    }

    enum CodingKeys: String, CodingKey {
        case images
        case urls
        case styleKeywords = "style_keywords"
        case userThoughts = "user_thoughts"
    }
}

struct DesignRequest: Codable {
    let id = UUID()
    let lidarData: LIDARData
    let styleReference: StyleReference
    let timestamp: Date
    let userId: String?

    init(lidarData: LIDARData, styleReference: StyleReference, userId: String? = nil) {
        self.lidarData = lidarData
        self.styleReference = styleReference
        self.timestamp = Date()
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case lidarData = "lidar_data"
        case styleReference = "style_reference"
        case timestamp
        case userId = "user_id"
    }
}

struct DesignResponse: Codable {
    let id: String
    let requestId: String
    let generatedImages: [String]?
    let status: ProcessingStatus
    let createdAt: Date
    let completedAt: Date?
    let error: String?

    enum ProcessingStatus: String, Codable, CaseIterable {
        case queued = "queued"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requestId = "request_id"
        case generatedImages = "generated_images"
        case status
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        requestId = try container.decode(String.self, forKey: .requestId)
        generatedImages = try container.decodeIfPresent([String].self, forKey: .generatedImages)
        status = try container.decode(ProcessingStatus.self, forKey: .status)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // Custom date decoding for ISO 8601 strings from Supabase
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = createdAtDate

        if let completedAtString = try container.decodeIfPresent(String.self, forKey: .completedAt) {
            guard let completedAtDate = dateFormatter.date(from: completedAtString) else {
                throw DecodingError.dataCorruptedError(forKey: .completedAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
            }
            completedAt = completedAtDate
        } else {
            completedAt = nil
        }
    }

    // Simple initializer for creating mock responses
    init(id: String, requestId: String, generatedImages: [String]?, status: ProcessingStatus, createdAt: Date, completedAt: Date?, error: String?) {
        self.id = id
        self.requestId = requestId
        self.generatedImages = generatedImages
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.error = error
    }
}

// MARK: - Enhanced Room Scan Data Structures

@available(iOS 16.0, *)
struct RoomScanData {
    let capturedRoom: CapturedRoom
    let roomDescription: String
    let dimensions: RoomDimensions
    let roomType: String
    let features: RoomFeatures
    let spatialData: RoomSpatialData

    init(from capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
        self.roomType = Self.determineRoomType(from: capturedRoom)
        self.dimensions = Self.extractDimensions(from: capturedRoom)
        self.features = Self.extractFeatures(from: capturedRoom)
        self.spatialData = Self.extractSpatialData(from: capturedRoom)
        self.roomDescription = Self.generateDescription(
            roomType: roomType,
            dimensions: dimensions,
            features: features
        )
    }

    // MARK: - Room Analysis Methods

    private static func determineRoomType(from room: CapturedRoom) -> String {
        // Use RoomPlan's sections to detect room type (iOS 17+)
        if #available(iOS 17.0, *) {
            // Check if room has sections with labels
            for section in room.sections {
                switch section.label {
                case .bedroom:
                    print("🏠 ✅ Detected room type: bedroom")
                    return "bedroom"
                case .kitchen:
                    print("🏠 ✅ Detected room type: kitchen")
                    return "kitchen"
                case .bathroom:
                    print("🏠 ✅ Detected room type: bathroom")
                    return "bathroom"
                case .diningRoom:
                    print("🏠 ✅ Detected room type: dining_room")
                    return "dining_room"
                case .livingRoom:
                    print("🏠 ✅ Detected room type: living_room")
                    return "living_room"
                @unknown default:
                    print("🏠 ⚠️ Unknown room section detected")
                    break
                }
            }
        }

        // Fallback: Try to infer from room characteristics
        let roomArea: Float
        if let firstWall = room.walls.first {
            roomArea = firstWall.dimensions.x * firstWall.dimensions.z
        } else {
            roomArea = 0
        }
        print("🏠 ⚠️ No room sections detected, using fallback detection")
        print("🏠 📏 Room area: \(roomArea) sq m")

        // Basic inference based on size and features
        if roomArea < 8 {
            return "bathroom"
        } else if roomArea < 15 {
            return "bedroom"
        } else {
            return "living_room"
        }
    }

    private static func extractDimensions(from room: CapturedRoom) -> RoomDimensions {
        // Calculate bounding box from the room
        var minX: Float = Float.greatestFiniteMagnitude
        var maxX: Float = -Float.greatestFiniteMagnitude
        var minY: Float = Float.greatestFiniteMagnitude
        var maxY: Float = -Float.greatestFiniteMagnitude
        var minZ: Float = Float.greatestFiniteMagnitude
        var maxZ: Float = -Float.greatestFiniteMagnitude

        // Analyze walls to get room bounds
        for surface in room.walls {
            let bounds = surface.dimensions
            let transform = surface.transform

            // Extract position from transform matrix
            let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

            minX = min(minX, position.x - bounds.x/2)
            maxX = max(maxX, position.x + bounds.x/2)
            minY = min(minY, position.y - bounds.y/2)
            maxY = max(maxY, position.y + bounds.y/2)
            minZ = min(minZ, position.z - bounds.z/2)
            maxZ = max(maxZ, position.z + bounds.z/2)
        }

        let width = maxX - minX
        let height = maxY - minY
        let depth = maxZ - minZ

        // Ensure reasonable minimum dimensions
        let finalWidth = max(width, 2.0)
        let finalHeight = max(height, 2.4)
        let finalDepth = max(depth, 2.0)

        return RoomDimensions(width: finalWidth, height: finalHeight, depth: finalDepth)
    }

    private static func extractFeatures(from room: CapturedRoom) -> RoomFeatures {
        let doors = room.doors.count
        let windows = room.windows.count
        let openings = room.openings.count
        let walls = room.walls.count

        return RoomFeatures(
            walls: walls,
            doors: doors,
            windows: windows,
            openings: openings
        )
    }

    private static func extractSpatialData(from room: CapturedRoom) -> RoomSpatialData {
        let walls = extractWallSpatialInfo(from: room)
        let doors = extractSurfaceSpatialInfo(from: room.doors, walls: walls)
        let windows = extractSurfaceSpatialInfo(from: room.windows, walls: walls)
        let openings = extractSurfaceSpatialInfo(from: room.openings, walls: walls)
        let relationships = extractSurfaceRelationships(doors: doors, windows: windows, openings: openings, walls: walls)

        return RoomSpatialData(
            walls: walls,
            doors: doors,
            windows: windows,
            openings: openings,
            surfaceRelationships: relationships
        )
    }

    private static func extractWallSpatialInfo(from room: CapturedRoom) -> [WallSpatialInfo] {
        return room.walls.map { wall in
            let position = extractPosition(from: wall.transform)
            let dimensions = Dimensions3D(from: wall.dimensions)
            let orientation = extractOrientation(from: wall.transform)
            let corners = calculateCorners(position: position, dimensions: dimensions, orientation: orientation)

            // Find attached elements (doors, windows, openings)
            let attachedElements = findAttachedElements(
                wallId: wall.identifier,
                doors: room.doors,
                windows: room.windows,
                openings: room.openings
            )

            return WallSpatialInfo(
                identifier: wall.identifier,
                position: position,
                dimensions: dimensions,
                orientation: orientation,
                corners: corners,
                attachedElements: attachedElements,
                confidence: convertConfidenceToFloat(wall.confidence)
            )
        }
    }

    private static func extractSurfaceSpatialInfo(from surfaces: [CapturedRoom.Surface], walls: [WallSpatialInfo]) -> [SurfaceSpatialInfo] {
        return surfaces.map { surface in
            let position = extractPosition(from: surface.transform)
            let dimensions = Dimensions3D(from: surface.dimensions)
            let orientation = extractOrientation(from: surface.transform)
            let corners = calculateCorners(position: position, dimensions: dimensions, orientation: orientation)

            // Find parent wall and relative position
            let (parentWallId, relativePosition) = findParentWallAndPosition(
                surface: surface,
                walls: walls
            )

            return SurfaceSpatialInfo(
                identifier: surface.identifier,
                position: position,
                dimensions: dimensions,
                orientation: orientation,
                corners: corners,
                parentWallId: parentWallId,
                relativePositionOnWall: relativePosition,
                confidence: convertConfidenceToFloat(surface.confidence)
            )
        }
    }

    private static func extractPosition(from transform: simd_float4x4) -> Position3D {
        // The 4th column contains the position
        return Position3D(
            x: transform.columns.3.x,
            y: transform.columns.3.y,
            z: transform.columns.3.z
        )
    }

    private static func extractOrientation(from transform: simd_float4x4) -> Orientation3D {
        // Extract orientation vectors from transform matrix
        let rightVector = Position3D(
            x: transform.columns.0.x,
            y: transform.columns.0.y,
            z: transform.columns.0.z
        )

        let upVector = Position3D(
            x: transform.columns.1.x,
            y: transform.columns.1.y,
            z: transform.columns.1.z
        )

        let forwardVector = Position3D(
            x: transform.columns.2.x,
            y: transform.columns.2.y,
            z: transform.columns.2.z
        )

        return Orientation3D(
            rightVector: rightVector,
            upVector: upVector,
            forwardVector: forwardVector
        )
    }

    private static func calculateCorners(position: Position3D, dimensions: Dimensions3D, orientation: Orientation3D) -> [Position3D] {
        // Calculate all 8 corners of the bounding box
        let halfWidth = dimensions.width / 2
        let halfHeight = dimensions.height / 2
        let halfDepth = dimensions.depth / 2

        // Define corner offsets in local space
        let localCorners = [
            [-halfWidth, -halfHeight, -halfDepth], // Bottom-left-back
            [halfWidth, -halfHeight, -halfDepth],  // Bottom-right-back
            [halfWidth, halfHeight, -halfDepth],   // Top-right-back
            [-halfWidth, halfHeight, -halfDepth],  // Top-left-back
            [-halfWidth, -halfHeight, halfDepth],  // Bottom-left-front
            [halfWidth, -halfHeight, halfDepth],   // Bottom-right-front
            [halfWidth, halfHeight, halfDepth],    // Top-right-front
            [-halfWidth, halfHeight, halfDepth]    // Top-left-front
        ]

        // Transform local corners to world space
        return localCorners.map { localCorner in
            let localX = localCorner[0]
            let localY = localCorner[1]
            let localZ = localCorner[2]

            let worldX = position.x +
                localX * orientation.rightVector.x +
                localY * orientation.upVector.x +
                localZ * orientation.forwardVector.x

            let worldY = position.y +
                localX * orientation.rightVector.y +
                localY * orientation.upVector.y +
                localZ * orientation.forwardVector.y

            let worldZ = position.z +
                localX * orientation.rightVector.z +
                localY * orientation.upVector.z +
                localZ * orientation.forwardVector.z

            return Position3D(x: worldX, y: worldY, z: worldZ)
        }
    }

    private static func findAttachedElements(
        wallId: UUID,
        doors: [CapturedRoom.Surface],
        windows: [CapturedRoom.Surface],
        openings: [CapturedRoom.Surface]
    ) -> [AttachedElement] {
        var attachedElements: [AttachedElement] = []

        // Check doors
        for door in doors {
            if let relativePosition = calculateRelativePosition(surface: door, wallId: wallId) {
                attachedElements.append(AttachedElement(
                    elementId: door.identifier,
                    elementType: .door,
                    relativePosition: relativePosition
                ))
            }
        }

        // Check windows
        for window in windows {
            if let relativePosition = calculateRelativePosition(surface: window, wallId: wallId) {
                attachedElements.append(AttachedElement(
                    elementId: window.identifier,
                    elementType: .window,
                    relativePosition: relativePosition
                ))
            }
        }

        // Check openings
        for opening in openings {
            if let relativePosition = calculateRelativePosition(surface: opening, wallId: wallId) {
                attachedElements.append(AttachedElement(
                    elementId: opening.identifier,
                    elementType: .opening,
                    relativePosition: relativePosition
                ))
            }
        }

        return attachedElements
    }

    private static func findParentWallAndPosition(
        surface: CapturedRoom.Surface,
        walls: [WallSpatialInfo]
    ) -> (UUID?, RelativePosition?) {
        let surfacePosition = extractPosition(from: surface.transform)
        var closestWall: WallSpatialInfo?
        var minDistance = Float.greatestFiniteMagnitude

        // Find the closest wall to the surface
        for wall in walls {
            let distance = calculateDistance(from: surfacePosition, to: wall.position)
            if distance < minDistance && distance < 1.0 { // Within 1 meter threshold
                minDistance = distance
                closestWall = wall
            }
        }

        guard let parentWall = closestWall else {
            return (nil, nil)
        }

        // Calculate relative position on the wall
        let relativePosition = calculateRelativePositionOnWall(
            surface: surface,
            wall: parentWall
        )

        return (parentWall.identifier, relativePosition)
    }

    private static func calculateRelativePosition(surface: CapturedRoom.Surface, wallId: UUID) -> RelativePosition? {
        // This is a simplified implementation
        // In practice, you'd need to project the surface position onto the wall plane
        let surfacePosition = extractPosition(from: surface.transform)

        return RelativePosition(
            distanceFromLeft: surfacePosition.x,
            distanceFromBottom: surfacePosition.y,
            normalizedX: 0.5, // Placeholder - requires wall plane projection
            normalizedY: 0.5  // Placeholder - requires wall plane projection
        )
    }

    private static func calculateRelativePositionOnWall(
        surface: CapturedRoom.Surface,
        wall: WallSpatialInfo
    ) -> RelativePosition {
        let surfacePosition = extractPosition(from: surface.transform)

        // Project surface position onto wall plane
        // This is simplified - full implementation would require plane projection math
        let distanceFromLeft = abs(surfacePosition.x - wall.position.x)
        let distanceFromBottom = abs(surfacePosition.y - wall.position.y)

        let normalizedX = min(1.0, max(0.0, distanceFromLeft / wall.dimensions.width))
        let normalizedY = min(1.0, max(0.0, distanceFromBottom / wall.dimensions.height))

        return RelativePosition(
            distanceFromLeft: distanceFromLeft,
            distanceFromBottom: distanceFromBottom,
            normalizedX: normalizedX,
            normalizedY: normalizedY
        )
    }

    private static func calculateDistance(from point1: Position3D, to point2: Position3D) -> Float {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        let dz = point1.z - point2.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }

    private static func convertConfidenceToFloat(_ confidence: CapturedRoom.Confidence) -> Float {
        switch confidence {
        case .high:
            return 1.0
        case .medium:
            return 0.5
        case .low:
            return 0.1
        @unknown default:
            return 0.0
        }
    }

    private static func extractSurfaceRelationships(
        doors: [SurfaceSpatialInfo],
        windows: [SurfaceSpatialInfo],
        openings: [SurfaceSpatialInfo],
        walls: [WallSpatialInfo]
    ) -> [SurfaceRelationship] {
        var relationships: [SurfaceRelationship] = []

        // Create relationships for doors to walls
        for door in doors {
            if let parentWallId = door.parentWallId {
                relationships.append(SurfaceRelationship(
                    childId: door.identifier,
                    parentId: parentWallId,
                    relationshipType: .attachedTo,
                    spatialConnection: SpatialConnection(
                        connectionType: "surface_attachment",
                        contactArea: door.dimensions.width * door.dimensions.height,
                        distance: 0.0
                    )
                ))
            }
        }

        // Create relationships for windows to walls
        for window in windows {
            if let parentWallId = window.parentWallId {
                relationships.append(SurfaceRelationship(
                    childId: window.identifier,
                    parentId: parentWallId,
                    relationshipType: .attachedTo,
                    spatialConnection: SpatialConnection(
                        connectionType: "surface_attachment",
                        contactArea: window.dimensions.width * window.dimensions.height,
                        distance: 0.0
                    )
                ))
            }
        }

        // Create relationships for openings to walls
        for opening in openings {
            if let parentWallId = opening.parentWallId {
                relationships.append(SurfaceRelationship(
                    childId: opening.identifier,
                    parentId: parentWallId,
                    relationshipType: .containedIn,
                    spatialConnection: SpatialConnection(
                        connectionType: "opening_cut",
                        contactArea: opening.dimensions.width * opening.dimensions.height,
                        distance: 0.0
                    )
                ))
            }
        }

        return relationships
    }

    // MARK: - Spatial Layout Conversion

    func getSimplifiedSpatialLayout() -> RoomSpatialLayout {
        return Self.convertToSimplifiedLayout(from: self.spatialData)
    }

    private static func convertToSimplifiedLayout(from spatialData: RoomSpatialData) -> RoomSpatialLayout {
        // Convert walls
        let walls = spatialData.walls.map { wall in
            WallLayout(
                id: wall.identifier.uuidString,
                orientation: determineWallOrientation(wall: wall),
                dimensions: SimpleDimensions(
                    width: wall.dimensions.width,
                    height: wall.dimensions.height,
                    depth: wall.dimensions.depth
                ),
                position: SimplePosition(
                    x: wall.position.x,
                    y: wall.position.y,
                    z: wall.position.z
                ),
                attachedElements: spatialData.elementsAttached(to: wall.identifier).map { $0.identifier.uuidString }
            )
        }

        // Convert windows
        let windows = spatialData.windows.map { window in
            ElementLayout(
                id: window.identifier.uuidString,
                type: "window",
                dimensions: SimpleDimensions(
                    width: window.dimensions.width,
                    height: window.dimensions.height,
                    depth: window.dimensions.depth
                ),
                wallId: window.parentWallId?.uuidString ?? "",
                positionOnWall: WallPosition(
                    fromLeft: window.relativePositionOnWall?.distanceFromLeft ?? 0,
                    fromBottom: window.relativePositionOnWall?.distanceFromBottom ?? 0,
                    normalizedX: window.relativePositionOnWall?.normalizedX ?? 0,
                    normalizedY: window.relativePositionOnWall?.normalizedY ?? 0
                )
            )
        }

        // Convert doors
        let doors = spatialData.doors.map { door in
            ElementLayout(
                id: door.identifier.uuidString,
                type: "door",
                dimensions: SimpleDimensions(
                    width: door.dimensions.width,
                    height: door.dimensions.height,
                    depth: door.dimensions.depth
                ),
                wallId: door.parentWallId?.uuidString ?? "",
                positionOnWall: WallPosition(
                    fromLeft: door.relativePositionOnWall?.distanceFromLeft ?? 0,
                    fromBottom: door.relativePositionOnWall?.distanceFromBottom ?? 0,
                    normalizedX: door.relativePositionOnWall?.normalizedX ?? 0,
                    normalizedY: door.relativePositionOnWall?.normalizedY ?? 0
                )
            )
        }

        // Convert openings
        let openings = spatialData.openings.map { opening in
            ElementLayout(
                id: opening.identifier.uuidString,
                type: "opening",
                dimensions: SimpleDimensions(
                    width: opening.dimensions.width,
                    height: opening.dimensions.height,
                    depth: opening.dimensions.depth
                ),
                wallId: opening.parentWallId?.uuidString ?? "",
                positionOnWall: WallPosition(
                    fromLeft: opening.relativePositionOnWall?.distanceFromLeft ?? 0,
                    fromBottom: opening.relativePositionOnWall?.distanceFromBottom ?? 0,
                    normalizedX: opening.relativePositionOnWall?.normalizedX ?? 0,
                    normalizedY: opening.relativePositionOnWall?.normalizedY ?? 0
                )
            )
        }

        return RoomSpatialLayout(
            walls: walls,
            windows: windows,
            doors: doors,
            openings: openings
        )
    }

    private static func determineWallOrientation(wall: WallSpatialInfo) -> String {
        // Determine wall orientation based on normal vector
        let normal = wall.orientation.forwardVector

        // Compare against cardinal directions
        if abs(normal.x) > abs(normal.z) {
            return normal.x > 0 ? "east" : "west"
        } else {
            return normal.z > 0 ? "north" : "south"
        }
    }

    private static func generateDescription(roomType: String, dimensions: RoomDimensions, features: RoomFeatures) -> String {
        let formattedWidth = String(format: "%.1f", dimensions.width)
        let formattedDepth = String(format: "%.1f", dimensions.depth)
        let formattedHeight = String(format: "%.1f", dimensions.height)
        let formattedArea = String(format: "%.1f", dimensions.area)

        var description = "\(formattedWidth)m x \(formattedDepth)m x \(formattedHeight)m \(roomType.replacingOccurrences(of: "_", with: " "))"
        description += " with total floor area of \(formattedArea) square meters."

        // Add architectural features
        var featuresArray: [String] = []

        if features.walls > 0 {
            featuresArray.append("\(features.walls) walls")
        }

        if features.doors > 0 {
            featuresArray.append("\(features.doors) \(features.doors == 1 ? "door" : "doors")")
        }

        if features.windows > 0 {
            featuresArray.append("\(features.windows) \(features.windows == 1 ? "window" : "windows")")
        }

        if features.openings > 0 {
            featuresArray.append("\(features.openings) \(features.openings == 1 ? "opening" : "openings")")
        }

        if !featuresArray.isEmpty {
            description += " The room has " + featuresArray.joined(separator: ", ") + "."
        }

        return description
    }
}

struct RoomFeatures: Codable {
    let walls: Int
    let doors: Int
    let windows: Int
    let openings: Int
}

// MARK: - Simplified Spatial Layout for GPT

struct RoomSpatialLayout: Codable {
    let walls: [WallLayout]
    let windows: [ElementLayout]
    let doors: [ElementLayout]
    let openings: [ElementLayout]

    enum CodingKeys: String, CodingKey {
        case walls, windows, doors, openings
    }
}

struct WallLayout: Codable {
    let id: String
    let orientation: String // "north", "south", "east", "west"
    let dimensions: SimpleDimensions
    let position: SimplePosition
    let attachedElements: [String] // IDs of windows/doors on this wall

    enum CodingKeys: String, CodingKey {
        case id, orientation, dimensions, position
        case attachedElements = "attached_elements"
    }
}

struct ElementLayout: Codable {
    let id: String
    let type: String // "window", "door", "opening"
    let dimensions: SimpleDimensions
    let wallId: String // Which wall it's on
    let positionOnWall: WallPosition // Where on the wall

    enum CodingKeys: String, CodingKey {
        case id, type, dimensions
        case wallId = "wall_id"
        case positionOnWall = "position_on_wall"
    }
}

struct SimpleDimensions: Codable {
    let width: Float
    let height: Float
    let depth: Float?
}

struct SimplePosition: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct WallPosition: Codable {
    let fromLeft: Float      // Distance from left edge of wall (meters)
    let fromBottom: Float    // Distance from bottom edge of wall (meters)
    let normalizedX: Float   // 0.0 to 1.0 position along wall width
    let normalizedY: Float   // 0.0 to 1.0 position along wall height

    enum CodingKeys: String, CodingKey {
        case fromLeft = "from_left"
        case fromBottom = "from_bottom"
        case normalizedX = "normalized_x"
        case normalizedY = "normalized_y"
    }
}

// MARK: - Enhanced Spatial Data Structures

@available(iOS 16.0, *)
struct RoomSpatialData {
    let walls: [WallSpatialInfo]
    let doors: [SurfaceSpatialInfo]
    let windows: [SurfaceSpatialInfo]
    let openings: [SurfaceSpatialInfo]
    let surfaceRelationships: [SurfaceRelationship]
}

@available(iOS 16.0, *)
struct WallSpatialInfo {
    let identifier: UUID
    let position: Position3D
    let dimensions: Dimensions3D
    let orientation: Orientation3D
    let corners: [Position3D]
    let attachedElements: [AttachedElement]
    let confidence: Float
}

@available(iOS 16.0, *)
struct SurfaceSpatialInfo {
    let identifier: UUID
    let position: Position3D
    let dimensions: Dimensions3D
    let orientation: Orientation3D
    let corners: [Position3D]
    let parentWallId: UUID?
    let relativePositionOnWall: RelativePosition?
    let confidence: Float
}

@available(iOS 16.0, *)
struct Position3D: Codable {
    let x: Float
    let y: Float
    let z: Float

    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(from simdFloat3: simd_float3) {
        self.x = simdFloat3.x
        self.y = simdFloat3.y
        self.z = simdFloat3.z
    }
}

@available(iOS 16.0, *)
struct Dimensions3D: Codable {
    let width: Float  // x-axis
    let height: Float // y-axis
    let depth: Float  // z-axis

    init(width: Float, height: Float, depth: Float) {
        self.width = width
        self.height = height
        self.depth = depth
    }

    init(from simdFloat3: simd_float3) {
        self.width = simdFloat3.x
        self.height = simdFloat3.y
        self.depth = simdFloat3.z
    }
}

@available(iOS 16.0, *)
struct Orientation3D: Codable {
    let rightVector: Position3D    // First column of transform matrix
    let upVector: Position3D       // Second column of transform matrix
    let forwardVector: Position3D  // Third column of transform matrix

    init(rightVector: Position3D, upVector: Position3D, forwardVector: Position3D) {
        self.rightVector = rightVector
        self.upVector = upVector
        self.forwardVector = forwardVector
    }
}

@available(iOS 16.0, *)
struct AttachedElement {
    let elementId: UUID
    let elementType: ElementType
    let relativePosition: RelativePosition
}

@available(iOS 16.0, *)
struct RelativePosition: Codable {
    let distanceFromLeft: Float   // Distance from left edge of wall
    let distanceFromBottom: Float // Distance from bottom edge of wall
    let normalizedX: Float        // 0.0 to 1.0 position along wall width
    let normalizedY: Float        // 0.0 to 1.0 position along wall height
}

@available(iOS 16.0, *)
struct SurfaceRelationship {
    let childId: UUID
    let parentId: UUID
    let relationshipType: RelationshipType
    let spatialConnection: SpatialConnection
}

@available(iOS 16.0, *)
enum ElementType: String, Codable {
    case wall = "wall"
    case door = "door"
    case window = "window"
    case opening = "opening"
}

@available(iOS 16.0, *)
enum RelationshipType: String, Codable {
    case attachedTo = "attached_to"
    case containedIn = "contained_in"
    case adjacentTo = "adjacent_to"
}

@available(iOS 16.0, *)
struct SpatialConnection {
    let connectionType: String
    let contactArea: Float?
    let distance: Float?
}

// MARK: - Spatial Data Utility Extensions

@available(iOS 16.0, *)
extension RoomSpatialData {
    /// Find all windows attached to a specific wall
    func windows(attachedTo wallId: UUID) -> [SurfaceSpatialInfo] {
        return windows.filter { $0.parentWallId == wallId }
    }

    /// Find all doors attached to a specific wall
    func doors(attachedTo wallId: UUID) -> [SurfaceSpatialInfo] {
        return doors.filter { $0.parentWallId == wallId }
    }

    /// Find all openings in a specific wall
    func openings(in wallId: UUID) -> [SurfaceSpatialInfo] {
        return openings.filter { $0.parentWallId == wallId }
    }

    /// Get all elements attached to a specific wall
    func elementsAttached(to wallId: UUID) -> [SurfaceSpatialInfo] {
        return windows(attachedTo: wallId) + doors(attachedTo: wallId) + openings(in: wallId)
    }

    /// Find wall by identifier
    func wall(withId wallId: UUID) -> WallSpatialInfo? {
        return walls.first { $0.identifier == wallId }
    }

    /// Calculate total wall area excluding doors, windows, and openings
    var effectiveWallArea: Float {
        var totalWallArea: Float = 0
        var totalOpeningArea: Float = 0

        for wall in walls {
            totalWallArea += wall.dimensions.width * wall.dimensions.height

            // Subtract areas of doors, windows, and openings on this wall
            for element in elementsAttached(to: wall.identifier) {
                totalOpeningArea += element.dimensions.width * element.dimensions.height
            }
        }

        return max(0, totalWallArea - totalOpeningArea)
    }
}

@available(iOS 16.0, *)
extension WallSpatialInfo {
    /// Get the 4 main corners of the wall (ignoring depth for wall surfaces)
    var wallCorners: [Position3D] {
        // For walls, we typically care about the 4 corners of the vertical surface
        return Array(corners.prefix(4))
    }

    /// Calculate the wall's area
    var area: Float {
        return dimensions.width * dimensions.height
    }

    /// Get the center point of the wall surface
    var centerPoint: Position3D {
        return position
    }

    /// Get wall normal vector (pointing outward from the wall)
    var normalVector: Position3D {
        return orientation.forwardVector
    }
}

@available(iOS 16.0, *)
extension SurfaceSpatialInfo {
    /// Calculate the surface area
    var area: Float {
        return dimensions.width * dimensions.height
    }

    /// Get the center point of the surface
    var centerPoint: Position3D {
        return position
    }

    /// Check if this surface is positioned on a specific wall
    func isAttached(to wallId: UUID) -> Bool {
        return parentWallId == wallId
    }

    /// Get normalized position on parent wall (0.0 to 1.0 coordinates)
    var normalizedWallPosition: (x: Float, y: Float)? {
        guard let relativePos = relativePositionOnWall else { return nil }
        return (x: relativePos.normalizedX, y: relativePos.normalizedY)
    }
}

@available(iOS 16.0, *)
extension Position3D {
    /// Calculate distance to another position
    func distance(to other: Position3D) -> Float {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }

    /// Add two positions (vector addition)
    static func + (lhs: Position3D, rhs: Position3D) -> Position3D {
        return Position3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    /// Subtract two positions (vector subtraction)
    static func - (lhs: Position3D, rhs: Position3D) -> Position3D {
        return Position3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// Multiply position by scalar
    static func * (lhs: Position3D, scalar: Float) -> Position3D {
        return Position3D(x: lhs.x * scalar, y: lhs.y * scalar, z: lhs.z * scalar)
    }
}