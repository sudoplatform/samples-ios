import Foundation

/// Represents the selected segment in the alias type filter control.
/// Maps directly to UISegmentedControl segment indices.
enum AliasTypeSegment: Int {
    case `internal` = 0
    case external = 1
}
