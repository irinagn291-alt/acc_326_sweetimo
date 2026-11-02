import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #F9F6F7
    static let bg = Color(red: 0.976471, green: 0.964706, blue: 0.968627)
    static let bgHex = "#F9F6F7"
    /// #FEFEFE
    static let surface = Color(red: 0.996078, green: 0.996078, blue: 0.996078)
    static let surfaceHex = "#FEFEFE"
    /// #351D25
    static let ink = Color(red: 0.207843, green: 0.113725, blue: 0.145098)
    static let inkHex = "#351D25"
    /// #B82E5C
    static let accent = Color(red: 0.721569, green: 0.180392, blue: 0.360784)
    static let accentHex = "#B82E5C"
    /// #816A71
    static let muted = Color(red: 0.505882, green: 0.415686, blue: 0.443137)
    static let mutedHex = "#816A71"
    static let fontFamily = "Didot"
}
