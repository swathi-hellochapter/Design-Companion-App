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

    init(roomDimensions: RoomDimensions, pointCloud: [LIDARPoint] = [], roomType: String = "living_room") {
        self.roomDimensions = roomDimensions
        self.pointCloud = pointCloud
        self.timestamp = Date()
        self.roomType = roomType
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
    let instagramUrl: String?
    let pinterestUrl: String?
    let styleKeywords: [String]
    let userThoughts: String?

    init(images: [String] = [], instagramUrl: String? = nil, pinterestUrl: String? = nil, styleKeywords: [String] = [], userThoughts: String? = nil) {
        self.images = images
        self.instagramUrl = instagramUrl
        self.pinterestUrl = pinterestUrl
        self.styleKeywords = styleKeywords
        self.userThoughts = userThoughts
    }

    enum CodingKeys: String, CodingKey {
        case images
        case instagramUrl = "instagram_url"
        case pinterestUrl = "pinterest_url"
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

// MARK: - Room Scan Data Structures

@available(iOS 16.0, *)
struct RoomScanData {
    let capturedRoom: CapturedRoom
    let roomDescription: String
    let dimensions: RoomDimensions
    let roomType: String
    let features: RoomFeatures

    init(from capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
        self.roomType = Self.determineRoomType(from: capturedRoom)
        self.dimensions = Self.extractDimensions(from: capturedRoom)
        self.features = Self.extractFeatures(from: capturedRoom)
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

struct RoomFeatures {
    let walls: Int
    let doors: Int
    let windows: Int
    let openings: Int
}