// glassbar: real macOS Liquid Glass (NSGlassEffectView, macOS 26+) behind
// SketchyBar's capsules. SketchyBar draws only a colour, an edge and a blur;
// this draws Apple's glass material in borderless windows just below the
// bar, and SketchyBar draws the text and icons on top.
//
//   glassbar <bracket> [<bracket> ...]
//
// It reads each bracket's place from `sketchybar --query <bracket>` once a
// second, and at once on SIGUSR1 (plugins/workspaces.sh sends it after a
// workspace change). sketchybarrc starts it; install_mac.sh builds it.

import AppKit

let sketchybar = "/opt/homebrew/bin/sketchybar"
let brackets = Array(CommandLine.arguments.dropFirst())
// SketchyBar's windows sit at level -20 (topmost=off); the glass goes just
// below them and above the desktop.
let glassLevel = NSWindow.Level(rawValue: -21)
// Height of the glass pill inside the 32-point bar (background.height).
let pillHeight: CGFloat = 28

var panels: [String: NSPanel] = [:]

func query(_ name: String) -> [String: NSRect] {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: sketchybar)
    task.arguments = ["--query", name]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do { try task.run() } catch { return [:] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let rects = json["bounding_rects"] as? [String: Any] else { return [:] }
    var out: [String: NSRect] = [:]
    for (display, value) in rects {
        guard let r = value as? [String: Any],
              let origin = r["origin"] as? [Double], let size = r["size"] as? [Double],
              origin.count == 2, size.count == 2,
              origin[0] > -9000, size[0] > 2 else { continue }
        out[display] = NSRect(x: origin[0], y: origin[1], width: size[0], height: size[1])
    }
    return out
}

func makePanel() -> NSPanel {
    let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
    panel.level = glassLevel
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    panel.contentView = NSGlassEffectView()
    return panel
}

func refresh() {
    // SketchyBar reports top-left screen coordinates; AppKit counts from the
    // bottom-left of the main screen.
    guard let mainHeight = NSScreen.screens.first?.frame.height else { return }
    var seen = Set<String>()
    for name in brackets {
        for (display, r) in query(name) {
            let key = name + "|" + display
            seen.insert(key)
            let inset = max(0, (r.height - pillHeight) / 2)
            let frame = NSRect(x: r.minX, y: mainHeight - r.maxY + inset,
                               width: r.width, height: r.height - 2 * inset)
            let panel = panels[key] ?? makePanel()
            panels[key] = panel
            if panel.frame != frame { panel.setFrame(frame, display: true) }
            (panel.contentView as? NSGlassEffectView)?.cornerRadius = frame.height / 2
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }
    for (key, panel) in panels where !seen.contains(key) {
        panel.orderOut(nil)
        panels[key] = nil
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

signal(SIGUSR1, SIG_IGN)
let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
usr1.setEventHandler { refresh() }
usr1.resume()

let timer = Timer(timeInterval: 1.0, repeats: true) { _ in refresh() }
RunLoop.main.add(timer, forMode: .common)
DispatchQueue.main.async { refresh() }

app.run()
