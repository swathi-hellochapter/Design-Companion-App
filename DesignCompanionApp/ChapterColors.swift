import SwiftUI

struct ChapterColors {
    // Chapter Brand Colors from hellochapter.com
    static let primary = Color(red: 35/255, green: 31/255, blue: 32/255) // #231f20 - Dark charcoal
    static let cream = Color(red: 248/255, green: 246/255, blue: 242/255) // Warm cream background
    static let lightCream = Color(red: 252/255, green: 251/255, blue: 249/255) // Very light cream
    static let warmGray = Color(red: 135/255, green: 130/255, blue: 125/255) // Warm neutral gray
    static let softGray = Color(red: 180/255, green: 175/255, blue: 170/255) // Soft gray accent

    // Additional Brand Colors
    static let background = cream
    static let cardBackground = lightCream
    static let text = primary
    static let secondaryText = warmGray
    static let accent = primary
    static let border = Color(red: 220/255, green: 215/255, blue: 210/255) // Subtle border

    // Status Colors (keeping professional)
    static let success = Color(red: 76/255, green: 125/255, blue: 95/255) // Muted green
    static let processing = warmGray
    static let error = Color(red: 160/255, green: 90/255, blue: 80/255) // Muted red
}

// Extension for easier usage
extension Color {
    static let chapterPrimary = ChapterColors.primary
    static let chapterCream = ChapterColors.cream
    static let chapterLightCream = ChapterColors.lightCream
    static let chapterWarmGray = ChapterColors.warmGray
    static let chapterSoftGray = ChapterColors.softGray
    static let chapterBackground = ChapterColors.background
    static let chapterCardBackground = ChapterColors.cardBackground
    static let chapterText = ChapterColors.text
    static let chapterSecondaryText = ChapterColors.secondaryText
    static let chapterAccent = ChapterColors.accent
    static let chapterBorder = ChapterColors.border
    static let chapterSuccess = ChapterColors.success
    static let chapterProcessing = ChapterColors.processing
    static let chapterError = ChapterColors.error
}