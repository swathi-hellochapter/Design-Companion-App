import Foundation
import UIKit

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