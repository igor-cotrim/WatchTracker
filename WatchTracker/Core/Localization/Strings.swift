import Foundation

/// Typesafe access to all localised strings in Localizable.xcstrings.
///
/// Usage:
///   Text(Strings.Home.title)
///   Text(verbatim: Strings.Episode.label(number: 3, name: "Pilot"))
///
/// Keys match the xcstrings file exactly so Xcode's String Catalog editor
/// can track translation coverage automatically.
///
/// The key namespaces live in the `Strings+<Feature>.swift` files alongside
/// this one, mirroring the `Features/` tree.
enum Strings {}
