// glassbar: real macOS Liquid Glass (NSGlassEffectView, macOS 26+) behind
// SketchyBar's capsules. SketchyBar draws only a colour, an edge and a blur;
// this draws Apple's glass material in borderless windows just below the
// bar, and SketchyBar draws the text and icons on top.
//
//   glassbar <bracket> [<bracket> ...]
//
// It reads each bracket's place from `sketchybar --query <bracket>` once a
// second, and at once on SIGUSR1 (plugins/workspaces.sh sends it after a
// workspace change). Open menus get glass too (see refreshMenus). launchd
// runs it (Library/LaunchAgents/com.noman.glassbar.plist); install_mac.sh
// builds it.

import AppKit

let sketchybar = "/opt/homebrew/bin/sketchybar"
let brackets = Array(CommandLine.arguments.dropFirst())
// SketchyBar's windows sit at level -20 (topmost=off); the glass goes just
// below them and above the desktop.
let glassLevel = NSWindow.Level(rawValue: -21)
// Height of the glass pill inside the 32-point bar (background.height).
let pillHeight: CGFloat = 28
// Style picked in the demo (variant 6): clear glass, a light dark tint, and
// the macOS 27 interactive effect.
let glassStyle = NSGlassEffectView.Style.clear
let glassTint = NSColor(white: 0, alpha: 0.2)
let glassInteractive = true

// Liquid Glass draws its light and highlights only while its window looks
// active; glassbar never becomes the active app, so its glass stayed flat
// (the demo pills lit up only while the pointer made the demo active).
// These windows always report the active look. They still refuse keyboard
// focus, so typing stays in the real active window.
final class ActiveLookPanel: NSPanel {
    override var isKeyWindow: Bool { true }
    override var isMainWindow: Bool { true }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    @objc func _hasActiveAppearance() -> Bool { true }
    @objc func _hasActiveAppearanceIgnoringKeyFocus() -> Bool { true }
    @objc func _hasKeyAppearance() -> Bool { true }
    @objc func _hasMainAppearance() -> Bool { true }
}

var panels: [String: NSPanel] = [:]

// Menus: SketchyBar draws an open menu as windows at level 101, one per
// entry plus its background, and reports no places for them. The menu
// glass is read from the window list instead, which needs no process per
// check, so it runs every 0.1 s and follows a menu as it opens and grows.
let menuLevel = 101
let menuGlassLevel = NSWindow.Level(rawValue: 100)
let menuCornerRadius: CGFloat = 20
let menuTint = NSColor(white: 0, alpha: 0.3)
var menuPanels: [Int: NSPanel] = [:]

func sketchybarMenuRects() -> [CGRect] {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] else { return [] }
    var rects: [CGRect] = []
    for w in list {
        guard (w[kCGWindowOwnerName as String] as? String) == "sketchybar",
              (w[kCGWindowLayer as String] as? Int) == menuLevel,
              let b = w[kCGWindowBounds as String] as? [String: Any],
              let rect = CGRect(dictionaryRepresentation: b as CFDictionary),
              rect.minX > -9000, rect.width > 2, rect.height > 2 else { continue }
        rects.append(rect)
    }
    return rects
}

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

func makePanel(level: NSWindow.Level = glassLevel, tint: NSColor = glassTint) -> NSPanel {
    let panel = ActiveLookPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
    panel.level = level
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    let glass = NSGlassEffectView()
    glass.style = glassStyle
    glass.tintColor = tint
    glass.effectIsInteractive = glassInteractive
    panel.contentView = glass
    return panel
}

func refreshMenus() {
    guard let mainHeight = NSScreen.screens.first?.frame.height else { return }
    // One glass panel per screen with an open menu: the union of its windows.
    var unions: [Int: CGRect] = [:]
    for r in sketchybarMenuRects() {
        let center = NSPoint(x: r.midX, y: mainHeight - r.midY)
        let screen = NSScreen.screens.firstIndex { $0.frame.contains(center) } ?? 0
        unions[screen] = unions[screen].map { $0.union(r) } ?? r
    }
    for (screen, r) in unions {
        let frame = NSRect(x: r.minX, y: mainHeight - r.maxY, width: r.width, height: r.height)
        let panel = menuPanels[screen] ?? makePanel(level: menuGlassLevel, tint: menuTint)
        menuPanels[screen] = panel
        if panel.frame != frame { panel.setFrame(frame, display: true) }
        (panel.contentView as? NSGlassEffectView)?.cornerRadius = menuCornerRadius
        if !panel.isVisible { panel.orderFrontRegardless() }
    }
    for (screen, panel) in menuPanels where unions[screen] == nil {
        panel.orderOut(nil)
        menuPanels[screen] = nil
    }
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

// First thing: the bar sends SIGUSR1 to every process named glassbar, and
// its default action ends the process (the demo closed at the next
// workspace change).
signal(SIGUSR1, SIG_IGN)

// `glassbar --demo`: a window with coloured stripes behind six glass pills,
// one per style, tint and interactive setting, to compare with Control
// Center. It closes after 60 seconds.
if CommandLine.arguments.dropFirst().first == "--demo" {
    let size = NSSize(width: 760, height: 420)
    let screen = NSScreen.main?.frame ?? .zero
    // Left: a normal window (glass lights up only while it is active).
    // Right: an ActiveLookPanel, like the bar (always the active look).
    let window = NSWindow(contentRect: NSRect(x: screen.midX - size.width - 10, y: screen.midY - size.height / 2,
                                              width: size.width, height: size.height),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "glassbar demo: normal window"
    let lit = ActiveLookPanel(contentRect: NSRect(x: screen.midX + 10, y: screen.midY - size.height / 2,
                                                  width: size.width, height: size.height),
                              styleMask: [.titled, .closable, .nonactivatingPanel], backing: .buffered, defer: false)
    lit.title = "glassbar demo: always active look (as in the bar)"
    window.level = .floating
    func demoContent() -> NSView {
        let root = NSView(frame: NSRect(origin: .zero, size: size))
        let stripes: [NSColor] = [.systemRed, .systemGreen, .black, .systemGreen, .systemBlue, .black, .systemPink]
        for (i, colour) in stripes.enumerated() {
            let stripe = NSView(frame: NSRect(x: 0, y: CGFloat(i) * size.height / CGFloat(stripes.count),
                                              width: size.width * 0.75, height: size.height / CGFloat(stripes.count)))
            stripe.wantsLayer = true
            stripe.layer?.backgroundColor = colour.withAlphaComponent(0.8).cgColor
            root.addSubview(stripe)
        }
        let variants: [(String, NSGlassEffectView.Style, CGFloat, Bool)] = [
            ("1 regular", .regular, 0, false),
            ("2 regular tint .35", .regular, 0.35, false),
            ("3 clear", .clear, 0, false),
            ("4 clear tint .35", .clear, 0.35, false),
            ("5 regular interactive", .regular, 0, true),
            ("6 clear interactive", .clear, 0.2, true),
        ]
        for (i, v) in variants.enumerated() {
            let col = CGFloat(i % 2), row = CGFloat(i / 2)
            let glass = NSGlassEffectView(frame: NSRect(x: 40 + col * 360, y: size.height - 110 - row * 130,
                                                        width: 320, height: 64))
            glass.style = v.1
            glass.cornerRadius = 32
            if v.2 > 0 { glass.tintColor = NSColor(white: 0, alpha: v.2) }
            if v.3 { glass.effectIsInteractive = true }
            let label = NSTextField(labelWithString: v.0)
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .white
            label.frame = NSRect(x: 24, y: 20, width: 280, height: 24)
            let content = NSView(frame: glass.bounds)
            content.addSubview(label)
            glass.contentView = content
            root.addSubview(glass)
        }
        return root
    }
    window.contentView = demoContent()
    lit.contentView = demoContent()
    lit.level = .floating
    window.makeKeyAndOrderFront(nil)
    lit.orderFrontRegardless()
    app.activate(ignoringOtherApps: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 60) { exit(0) }
    app.run()
}

let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
usr1.setEventHandler { refresh() }
usr1.resume()

let timer = Timer(timeInterval: 1.0, repeats: true) { _ in refresh() }
RunLoop.main.add(timer, forMode: .common)
let menuTimer = Timer(timeInterval: 0.1, repeats: true) { _ in refreshMenus() }
RunLoop.main.add(menuTimer, forMode: .common)
DispatchQueue.main.async { refresh() }

app.run()
