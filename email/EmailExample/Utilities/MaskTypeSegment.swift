import Foundation

/// Represents the selected segment in the mask type filter control.
/// Maps directly to UISegmentedControl segment indices.
enum MaskTypeSegment: Int {
    case `internal` = 0
    case external = 1
}
