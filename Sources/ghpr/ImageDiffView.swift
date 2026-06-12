import AppKit
import Foundation
import SwiftUI

/// GitHub-style 2-up image comparison: the deleted version framed red,
/// the added version framed green, each captioned with its pixel size.
struct ImageDiffView: View {
    let sides: ImageDiffSides

    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "heic", "icns", "svg",
    ]

    /// Whether a path looks like an image ghpr can preview.
    static func supports(_ path: String) -> Bool {
        imageExtensions.contains((path as NSString).pathExtension.lowercased())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            if let old = sides.old {
                column(title: "Deleted", color: .red, data: old)
            }
            if let new = sides.new {
                column(title: "Added", color: .green, data: new)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func column(title: String, color: Color, data: Data) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            if let image = NSImage(data: data) {
                let pixels = pixelSize(of: image)
                let display = displaySize(for: pixels)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: display.width, height: display.height)
                    .border(color, width: 1)
                Text("W: \(Int(pixels.width))px | H: \(Int(pixels.height))px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Preview unavailable")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(24)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(color, lineWidth: 1))
            }
        }
    }

    /// True pixel dimensions (NSImage.size is in points).
    private func pixelSize(of image: NSImage) -> CGSize {
        if let rep = image.representations.first, rep.pixelsWide > 0 {
            CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        } else {
            image.size
        }
    }

    /// Fits within a GitHub-like cell, never upscaling.
    private func displaySize(for pixels: CGSize) -> CGSize {
        guard pixels.width > 0, pixels.height > 0 else { return CGSize(width: 100, height: 100) }
        let scale = min(1, 360 / pixels.width, 480 / pixels.height)
        return CGSize(width: pixels.width * scale, height: pixels.height * scale)
    }
}
