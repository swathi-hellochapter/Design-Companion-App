import Foundation
#if canImport(UIKit)
import UIKit
#endif

class APIService: ObservableObject {
    static let shared = APIService()

    private let supabaseURL = Config.Supabase.url
    private let supabaseKey = Config.Supabase.anonKey
    private let n8nWebhookURL = Config.N8N.currentWebhookURL

    private init() {
        print("🚀 APIService initialized")
        print("🌐 Supabase URL: \(supabaseURL)")
        print("🔑 Supabase Key: \(String(supabaseKey.prefix(20)))...")
        print("🌐 N8N Webhook: \(n8nWebhookURL)")
    }

    func submitDesignRequest(lidarData: LIDARData, styleReference: StyleReference, referenceImages: [Data]) async throws -> String {
        print("🚀 === APIService.submitDesignRequest STARTED ===")

        print("📋 LIDAR Data Details:")
        print("   Room Type: \(lidarData.roomType)")
        print("   Dimensions: \(lidarData.roomDimensions.width) x \(lidarData.roomDimensions.depth) x \(lidarData.roomDimensions.height)m")
        print("   Area: \(lidarData.roomDimensions.area) sq m")
        print("🖼️ Reference images count: \(referenceImages.count)")
        if !referenceImages.isEmpty {
            print("   Image sizes: \(referenceImages.map { "\($0.count) bytes" })")
        }
        print("📍 Instagram: \(styleReference.instagramUrl ?? "none")")
        print("📍 Pinterest: \(styleReference.pinterestUrl ?? "none")")
        print("🏷️ Style Keywords: \(styleReference.styleKeywords)")
        print("💭 User Thoughts: \(styleReference.userThoughts ?? "none")")

        let request = DesignRequest(lidarData: lidarData, styleReference: styleReference)

        print("📤 === PHASE 1: IMAGE UPLOAD ===")
        let imageUrls: [String]
        if !referenceImages.isEmpty {
            print("📤 Uploading \(referenceImages.count) reference images to Supabase Storage...")
            imageUrls = try await uploadImagesToSupabase(referenceImages)
            print("✅ Images uploaded successfully. URLs: \(imageUrls)")
        } else {
            imageUrls = []
            print("ℹ️ No reference images to upload")
        }

        // Update style reference with uploaded image URLs
        let updatedStyleReference = StyleReference(
            images: imageUrls,
            instagramUrl: styleReference.instagramUrl,
            pinterestUrl: styleReference.pinterestUrl,
            styleKeywords: styleReference.styleKeywords,
            userThoughts: styleReference.userThoughts
        )

        let finalRequest = DesignRequest(
            lidarData: request.lidarData,
            styleReference: updatedStyleReference
        )

        print("💾 === PHASE 2: SAVE REQUEST TO DATABASE ===")
        let requestId: String
        do {
            requestId = try await saveRequestToSupabase(finalRequest)
            print("✅ Request saved to Supabase with ID: \(requestId)")
        } catch {
            print("❌ Failed to save request to Supabase: \(error)")
            throw error
        }

        print("🔗 === PHASE 3: TRIGGER N8N WORKFLOW ===")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let lidarDataJSON: [String: Any]
            do {
                let lidarDataEncoded = try encoder.encode(request.lidarData)
                lidarDataJSON = try JSONSerialization.jsonObject(with: lidarDataEncoded, options: []) as! [String: Any]
                print("📊 LIDAR JSON keys: \(lidarDataJSON.keys.joined(separator: ", "))")
            } catch {
                print("❌ Failed to encode LIDAR data: \(error)")
                throw error
            }

            let styleReferenceJSON: [String: Any]
            do {
                let styleReferenceEncoded = try encoder.encode(updatedStyleReference)
                styleReferenceJSON = try JSONSerialization.jsonObject(with: styleReferenceEncoded, options: []) as! [String: Any]
                print("🎨 Style Reference JSON keys: \(styleReferenceJSON.keys.joined(separator: ", "))")
            } catch {
                print("❌ Failed to encode style reference: \(error)")
                throw error
            }

            let webhookPayload: [String: Any] = [
                "requestId": requestId,
                "lidarData": lidarDataJSON,
                "styleReference": styleReferenceJSON,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]

            try await triggerN8NWorkflow(payload: webhookPayload)
            print("✅ N8N workflow triggered successfully")
        } catch {
            print("❌ Failed to trigger N8N workflow: \(error)")
            throw error
        }

        print("🎉 === APIService.submitDesignRequest COMPLETED ===")
        print("✅ Final Request ID: \(requestId)")
        return requestId
    }

    private func uploadImagesToSupabase(_ imageData: [Data]) async throws -> [String] {
        var uploadedUrls: [String] = []

        for (index, data) in imageData.enumerated() {
            let fileName = "reference_image_\(UUID().uuidString)_\(index).jpg"
            let url = try await uploadSingleImageToSupabase(data: data, fileName: fileName)
            uploadedUrls.append(url)
            print("📤 Uploaded image \(index + 1)/\(imageData.count): \(fileName)")
        }

        return uploadedUrls
    }

    private func uploadSingleImageToSupabase(data: Data, fileName: String) async throws -> String {
        let uploadURL = "\(supabaseURL)/storage/v1/object/\(Config.Storage.referenceBucket)/\(fileName)"

        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("public", forHTTPHeaderField: "x-upsert")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📤 Upload response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let publicURL = "\(supabaseURL)/storage/v1/object/public/\(Config.Storage.referenceBucket)/\(fileName)"
            return publicURL
        } else {
            print("❌ Upload failed with status: \(httpResponse.statusCode)")
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("❌ Upload error response: \(responseString)")
            }
            throw APIError.uploadFailed
        }
    }

    private func saveRequestToSupabase(_ request: DesignRequest) async throws -> String {
        let endpoint = "\(supabaseURL)/rest/v1/design_requests"

        var urlRequest = URLRequest(url: URL(string: endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(request)
            urlRequest.httpBody = jsonData

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📦 Request JSON: \(jsonString)")
            }
        } catch {
            print("❌ Failed to encode request: \(error)")
            throw APIError.invalidData
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("💾 Supabase save response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("💾 Supabase response: \(responseString)")
        }

        if httpResponse.statusCode == 201 {
            // Parse the response to get the generated ID
            if let responseArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResponse = responseArray.first,
               let id = firstResponse["id"] as? String {
                return id
            } else {
                // Fallback to using the request ID
                return request.id.uuidString
            }
        } else {
            throw APIError.saveFailed
        }
    }

    private func triggerN8NWorkflow(payload: [String: Any]) async throws {
        print("🔗 Triggering N8N workflow with payload...")

        var request = URLRequest(url: URL(string: n8nWebhookURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonData

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🔗 N8N payload: \(jsonString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("🔗 N8N webhook response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("🔗 N8N response: \(responseString)")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.networkError
        }
    }

    func checkProcessingStatus(requestId: String) async throws -> DesignResponse {
        print("🔍 Checking processing status for request: \(requestId)")

        let endpoint = "\(supabaseURL)/rest/v1/design_responses"
        let queryURL = "\(endpoint)?request_id=eq.\(requestId)&order=created_at.desc&limit=1"

        var request = URLRequest(url: URL(string: queryURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("🔍 Status check response: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 Status response: \(responseString)")
        }

        if httpResponse.statusCode == 200 {
            do {
                let responses = try JSONDecoder().decode([DesignResponse].self, from: data)
                if let latestResponse = responses.first {
                    print("✅ Found response with status: \(latestResponse.status)")
                    return latestResponse
                } else {
                    print("⏳ No response found yet, still processing...")
                    // Return a processing status
                    return DesignResponse(
                        id: UUID().uuidString,
                        requestId: requestId,
                        generatedImages: nil,
                        status: .processing,
                        createdAt: Date(),
                        completedAt: nil,
                        error: nil
                    )
                }
            } catch {
                print("❌ Failed to decode response: \(error)")
                throw APIError.invalidData
            }
        } else {
            throw APIError.networkError
        }
    }

    func testConnection() async throws -> Bool {
        print("🔍 Testing Supabase connection...")

        let endpoint = "\(supabaseURL)/rest/v1/"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        let isConnected = (200...299).contains(httpResponse.statusCode)
        print("🔍 Supabase connection test: \(isConnected ? "✅ Success" : "❌ Failed") (\(httpResponse.statusCode))")

        return isConnected
    }
}