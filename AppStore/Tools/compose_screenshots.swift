import AppKit
import Foundation

struct ScreenshotSpec {
    let input: String
    let output: String
    let title: String
}

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let usesEnglish = CommandLine.arguments.dropFirst().contains("--english")
let sourceDirectory = projectRoot.appending(
    path: usesEnglish
        ? "AppStore/Screenshots/en-iPhone-17-Pro"
        : "AppStore/Screenshots/nb-iPhone-17-Pro"
)
let outputDirectory = sourceDirectory.appending(path: "Final")

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let specs: [ScreenshotSpec] = usesEnglish
    ? [
        ScreenshotSpec(input: "01-overview.png", output: "01-see-what-is-left.png", title: "See what you actually\nhave left"),
        ScreenshotSpec(input: "02-budgets.png", output: "02-control-your-budget.png", title: "Stay on top of your\nmonthly budget"),
        ScreenshotSpec(input: "03-new-transaction.png", output: "03-register-quickly.png", title: "Register quickly\nand easily"),
        ScreenshotSpec(input: "04-transactions.png", output: "04-track-your-money.png", title: "Track bills, salary\nand refunds"),
        ScreenshotSpec(input: "05-statistics.png", output: "05-understand-spending.png", title: "Understand where\nyour money goes"),
        ScreenshotSpec(input: "06-settings.png", output: "06-private-data.png", title: "Your data.\nYour private iCloud.")
    ]
    : [
        ScreenshotSpec(input: "01-oversikt.png", output: "01-se-hva-du-har-igjen.png", title: "Se hva du faktisk\nhar igjen"),
        ScreenshotSpec(input: "02-budsjett.png", output: "02-kontroll-pa-budsjettet.png", title: "Få kontroll på\nmånedens budsjett"),
        ScreenshotSpec(input: "03-ny-post.png", output: "03-registrer-raskt.png", title: "Registrer raskt\nog enkelt"),
        ScreenshotSpec(input: "04-poster.png", output: "04-folg-pengene.png", title: "Følg regninger, lønn\nog refusjoner"),
        ScreenshotSpec(input: "05-statistikk.png", output: "05-forsta-forbruket.png", title: "Forstå hvor\npengene går"),
        ScreenshotSpec(input: "06-innstillinger.png", output: "06-private-data.png", title: "Dine data.\nDin private iCloud.")
    ]

let canvasSize = NSSize(width: 1206, height: 2622)
let screenshotRect = NSRect(x: 111, y: 92, width: 984, height: 2140)
let cornerRadius: CGFloat = 72

let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center
paragraphStyle.lineSpacing = 2

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 78, weight: .bold),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraphStyle
]

for spec in specs {
    let inputURL = sourceDirectory.appending(path: spec.input)
    let outputURL = outputDirectory.appending(path: spec.output)
    guard let screenshot = NSImage(contentsOf: inputURL) else {
        throw CocoaError(.fileReadCorruptFile, userInfo: [NSFilePathErrorKey: inputURL.path])
    }

    let canvas = NSImage(size: canvasSize)
    canvas.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        throw CocoaError(.coderInvalidValue)
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(calibratedRed: 0, green: 0.29, blue: 0.60, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.21, green: 0.13, blue: 0.44, alpha: 1).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: canvasSize.height),
        end: CGPoint(x: canvasSize.width, y: 0),
        options: []
    )

    let titleRect = NSRect(x: 70, y: 2265, width: 1066, height: 280)
    NSString(string: spec.title).draw(in: titleRect, withAttributes: titleAttributes)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 32
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor.black.withAlphaComponent(0.18).setFill()
    NSBezierPath(roundedRect: screenshotRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: screenshotRect, xRadius: cornerRadius, yRadius: cornerRadius).addClip()
    NSGraphicsContext.current?.imageInterpolation = .high
    screenshot.draw(in: screenshotRect, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    canvas.unlockFocus()

    guard let tiffData = canvas.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: outputURL.path])
    }
    try pngData.write(to: outputURL, options: .atomic)
}

print("Created \(specs.count) App Store screenshots in \(outputDirectory.path)")
