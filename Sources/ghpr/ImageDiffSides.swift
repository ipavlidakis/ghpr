import Foundation

/// The two versions of a changed image: `nil` sides don't exist
/// (no old side for added files, no new side for deleted ones).
struct ImageDiffSides: Equatable {
    let old: Data?
    let new: Data?
}
