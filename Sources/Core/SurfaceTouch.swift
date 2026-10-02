import Foundation
import CoreGraphics

/// A touch on the normalized (0...1) Magic Mouse surface.
struct SurfaceTouch: Equatable {
    let identifier: Int32
    let position: CGPoint
}
