import SwiftUI

extension Color {
    // MARK: - Brand Colors (replace with your actual brand palette)
    static let brandPrimary = Color(red: 0.95, green: 0.30, blue: 0.25)   // Vibrant red
    static let brandSecondary = Color(red: 0.20, green: 0.20, blue: 0.30) // Dark navy
    static let brandAccent = Color(red: 1.0, green: 0.75, blue: 0.0)      // Gold/yellow

    // MARK: - Semantic Colors
    static let ratingStarFilled = Color.brandAccent
    static let ratingStarEmpty = Color(.systemGray4)

    // MARK: - Third-party Brand Colors
    static let tmdbBrand = Color(red: 0.004, green: 0.706, blue: 0.894) // TMDB cyan
}
