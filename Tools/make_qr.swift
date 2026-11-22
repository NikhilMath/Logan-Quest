// Draws a QR code for a link as a PNG, then reads it back to check it scans.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/make_qr.swift \
//     https://testflight.apple.com/join/ynz9DXQa TestFlight/qr.png
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 3 else {
    print("usage: swift Tools/make_qr.swift <link> <output.png>")
    exit(1)
}
let link = args[1]
let output = URL(fileURLWithPath: args[2])

let filter = CIFilter.qrCodeGenerator()
filter.message = Data(link.utf8)
filter.correctionLevel = "M"
guard let code = filter.outputImage else { fatalError("Couldn't make the QR code") }

// Scale each module up to whole pixels so the edges stay sharp, and leave a
// four-module white border around it, which scanners need.
let modulePixels: CGFloat = 24
let border: CGFloat = 4 * modulePixels
let scaled = code.transformed(by: CGAffineTransform(scaleX: modulePixels, y: modulePixels))
    .transformed(by: CGAffineTransform(translationX: border, y: border))
let canvas = CGRect(x: 0, y: 0, width: scaled.extent.width + 2 * border, height: scaled.extent.height + 2 * border)
let image = scaled.composited(over: CIImage(color: .white).cropped(to: canvas))

let context = CIContext()
guard let cgImage = context.createCGImage(image, from: canvas),
      let file = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("Couldn't write \(output.path)") }
CGImageDestinationAddImage(file, cgImage, nil)
guard CGImageDestinationFinalize(file) else { fatalError("Couldn't write \(output.path)") }

let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: nil)
let read = detector?.features(in: CIImage(cgImage: cgImage)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
guard read == [link] else { fatalError("The QR code reads back as \(read ?? []), not \(link)") }
print("Wrote \(output.path) (\(cgImage.width)×\(cgImage.height)); it scans as \(link)")
