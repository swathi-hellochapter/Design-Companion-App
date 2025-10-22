import Foundation

struct Config {
    // Development mode - set to false when you have real endpoints
    static let mockMode = false

    // Demo mode for testing UI without API calls - set to true for testing share/save features
    static let demoMode = false

    struct Supabase {
        static let url = "https://raxtpcmboalnjxbgpcez.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJheHRwY21ib2Fsbmp4YmdwY2V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2MzQ4MjAsImV4cCI6MjA3MzIxMDgyMH0.p9ruKpgZb-Vn9XKYFmVeMgjBg_2bqNVUHbUK1TEpWh8"
    }

    struct N8N {
        // Production webhook
        static let webhookURL = "https://chapterdesignapp.app.n8n.cloud/webhook/2a283622-c885-4b2b-8765-ccf7343dc001"
        

        // Test webhook for development
        static let testWebhookURL = "https://chapterdesignapp.app.n8n.cloud/webhook-test/2a283622-c885-4b2b-8765-ccf7343dc001"

        // Current webhook to use (switch for testing)
        static let currentWebhookURL = webhookURL
    }

    struct Storage {
        static let referenceBucket = "reference-images"
        static let generatedBucket = "generated-images"
    }

    struct DemoData {
        // Sample interior design images for testing share/save functionality
        static let sampleDesignImages = [
            "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800",  // Modern living room
            "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",  // Scandinavian bedroom
            "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800",  // Modern kitchen
            "https://images.unsplash.com/photo-1540932239986-30128078f3c5?w=800"  // Cozy dining room
        ]
    }
}
