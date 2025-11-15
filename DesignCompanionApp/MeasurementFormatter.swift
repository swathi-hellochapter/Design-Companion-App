import Foundation

struct MeasurementFormatter {

    /// Convert meters to feet and inches
    /// Returns tuple (feet, inches)
    static func metersToFeetInches(_ meters: Float) -> (feet: Int, inches: Int) {
        let totalInches = meters * 39.3701 // 1 meter = 39.3701 inches
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }

    /// Convert meters to formatted string "X' Y\""
    static func metersToFeetInchesString(_ meters: Float) -> String {
        let (feet, inches) = metersToFeetInches(meters)
        return "\(feet)' \(inches)\""
    }

    /// Convert square meters to square feet
    static func squareMetersToSquareFeet(_ sqMeters: Float) -> Int {
        return Int(sqMeters * 10.7639) // 1 sq m = 10.7639 sq ft
    }

    /// Format dimensions as "W × D × H"
    static func formatDimensions(width: Float, depth: Float, height: Float) -> String {
        let w = metersToFeetInchesString(width)
        let d = metersToFeetInchesString(depth)
        let h = metersToFeetInchesString(height)
        return "\(w) × \(d) × \(h)"
    }

    /// Format area as "XXX sq ft"
    static func formatArea(_ sqMeters: Float) -> String {
        let sqFeet = squareMetersToSquareFeet(sqMeters)
        return "\(sqFeet) sq ft"
    }
}
