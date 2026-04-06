import SwiftUI

extension Color {
    // MARK: - Brand Colors (replace with your actual brand palette)
    static let brandPrimary = Color(red: 0.95, green: 0.30, blue: 0.25)   // Vibrant red
    static let brandSecondary = Color(red: 0.20, green: 0.20, blue: 0.30) // Dark navy
    static let brandAccent = Color(red: 1.0, green: 0.75, blue: 0.0)      // Gold/yellow

    // MARK: - Semantic Colors
    static let cardBackground = Color(.systemBackground)
    static let subtitleText = Color(.secondaryLabel)
    static let ratingStarFilled = Color.brandAccent
    static let ratingStarEmpty = Color(.systemGray4)
}
