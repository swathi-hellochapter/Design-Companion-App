import Foundation

struct Config {
    // Development mode - set to false when you have real endpoints
    static let mockMode = false

    struct Supabase {
        static let url = "https://raxtpcmboalnjxbgpcez.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJheHRwY21ib2Fsbmp4YmdwY2V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2MzQ4MjAsImV4cCI6MjA3MzIxMDgyMH0.p9ruKpgZb-Vn9XKYFmVeMgjBg_2bqNVUHbUK1TEpWh8"
    }

    struct N8N {
        // Production webhook
        static let webhookURL = "https://chapterdesignapp.app.n8n.cloud/webhook/chapter-design-webhook"

        // Test webhook for development
        static let testWebhookURL = "https://chapterdesignapp.app.n8n.cloud/webhook-test/2a283622-c885-4b2b-8765-ccf7343dc001"

        // Current webhook to use (switch for testing)
        static let currentWebhookURL = testWebhookURL
    }

    struct Storage {
        static let referenceBucket = "reference-images"
        static let generatedBucket = "generated-images"
    }
}
