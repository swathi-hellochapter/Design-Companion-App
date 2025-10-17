import Foundation

struct Config {
    struct Supabase {
        static let url = "https://bwpkvfyomkajbhzckjcj.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3cGt2ZnlvbWthamJoemNramNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzMzk0MDksImV4cCI6MjA0MTkxNTQwOX0.0hDrcMZlhJa0HYPSQWk3sUEWTVZSoYW8jUfMiSs5iMA"
    }

    struct N8N {
        static let webhookURL = "https://chapter-interior-design.n8n.hellochapter.workers.dev/webhook/chapter-interior-design"
    }

    struct Storage {
        static let bucket = "design-images"
    }
}