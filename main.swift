import AppKit
import Foundation

// MARK: - History Manager

class HistoryManager {
    static let shared = HistoryManager()
    private let key = "StickyNoteHistory"
    private let maxEntries = 50

    func save(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var history = load()
        let entry: [String: Any] = [
            "content": content,
            "date": Date().timeIntervalSince1970
        ]
        history.insert(entry, at: 0)
        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }
        UserDefaults.standard.set(history, forKey: key)
    }

    func load() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
    }
}

// MARK: - Plain Text View

class PlainTextView: NSTextView {

    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        if let string = pboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }
        return super.readSelection(from: pboard, type: type)
    }
}

// MARK: - Sticky Window

class StickyWindow: NSWindow {

    static let stickyYellow = NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.65, alpha: 1.0)
    weak var textView: PlainTextView?

    init(content: String? = nil, cascadeFrom point: NSPoint? = nil) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        title = "Sticky"
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        backgroundColor = StickyWindow.stickyYellow
        minSize = NSSize(width: 160, height: 120)
        isReleasedWhenClosed = false

        setupContent()

        if let content = content {
            textView?.string = content
        }

        if let point = point {
            _ = cascadeTopLeft(from: point)
        } else {
            center()
        }
    }

    private func setupContent() {
        // ScrollView container
        let scrollView = NSScrollView()
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .legacy                       // siempre visible
        scrollView.verticalScroller?.knobStyle = .dark           // knob oscuro sobre fondo amarillo

        // TextView configured for vertical scrolling
        let tv = PlainTextView()
        tv.backgroundColor = StickyWindow.stickyYellow
        tv.drawsBackground = true
        tv.isRichText = false
        tv.font = NSFont.systemFont(ofSize: 14)
        tv.textColor = NSColor.black
        tv.isEditable = true
        tv.isSelectable = true
        tv.textContainerInset = NSSize(width: 8, height: 8)
        tv.allowsUndo = true

        // Key settings for scrolling to work
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.minSize = NSSize(width: 0, height: 0)
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.heightTracksTextView = false
        tv.textContainer?.size = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = tv
        contentView = scrollView
        textView = tv

        // Size the textView to match the scroll content width
        tv.frame = NSRect(x: 0, y: 0, width: 320, height: 0)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var windows: [StickyWindow] = []
    var statusItem: NSStatusItem?
    var nextCascadePoint = NSPoint(x: 200, y: 500)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        openNewNote()
    }

    // MARK: New note

    func openNewNote(content: String? = nil) {
        let w = StickyWindow(content: content, cascadeFrom: nextCascadePoint)
        w.delegate = self
        windows.append(w)
        nextCascadePoint = w.cascadeTopLeft(from: nextCascadePoint)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateTooltip()
    }

    // MARK: Menu bar setup

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.title = "📝"
        button.toolTip = "Click → nueva nota  |  Click derecho → historial"
        button.action = #selector(statusBarClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc func statusBarClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            openNewNote()
        }
    }

    func showContextMenu() {
        let menu = buildContextMenu()
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Reset so next left-click does not trigger menu
        DispatchQueue.main.async { self.statusItem?.menu = nil }
    }

    func buildContextMenu() -> NSMenu {
        let menu = NSMenu()

        let newItem = NSMenuItem(title: "Nueva nota", action: #selector(newNoteFromMenu), keyEquivalent: "")
        newItem.target = self
        menu.addItem(newItem)

        menu.addItem(NSMenuItem.separator())

        // History
        let history = HistoryManager.shared.load()
        if history.isEmpty {
            let empty = NSMenuItem(title: "Sin historial", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let histTitle = NSMenuItem(title: "Historial (\(history.count))", action: nil, keyEquivalent: "")
            let submenu = NSMenu()

            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short

            for (i, entry) in history.enumerated() {
                let content = entry["content"] as? String ?? ""
                let date = Date(timeIntervalSince1970: entry["date"] as? TimeInterval ?? 0)

                // First non-empty line, max 45 chars
                let firstLine = content
                    .components(separatedBy: .newlines)
                    .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
                let preview = firstLine.count > 45 ? String(firstLine.prefix(45)) + "…" : firstLine
                let label = (preview.isEmpty ? "(sin texto)" : preview) + "  —  " + df.string(from: date)

                let item = NSMenuItem(title: label, action: #selector(openFromHistory(_:)), keyEquivalent: "")
                item.tag = i
                item.target = self
                submenu.addItem(item)
            }

            histTitle.submenu = submenu
            menu.addItem(histTitle)
        }

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    @objc func newNoteFromMenu() {
        openNewNote()
    }

    @objc func openFromHistory(_ sender: NSMenuItem) {
        let history = HistoryManager.shared.load()
        guard sender.tag < history.count,
              let content = history[sender.tag]["content"] as? String else { return }
        openNewNote(content: content)
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? StickyWindow else { return }
        // Save to history before closing
        if let text = window.textView?.string {
            HistoryManager.shared.save(text)
        }
        windows.removeAll { $0 === window }
        updateTooltip()
    }

    func updateTooltip() {
        let n = windows.count
        statusItem?.button?.toolTip = n > 0
            ? "\(n) nota(s) abierta(s)  |  Click → nueva  |  Click derecho → historial"
            : "Click → nueva nota  |  Click derecho → historial"
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        for w in windows {
            if let text = w.textView?.string {
                HistoryManager.shared.save(text)
            }
        }
    }
}

// MARK: - Entry Point
// AppDelegate must be a global — NSApplication.delegate is weak,
// a local variable can be released by ARC before app.run() finishes.

let appDelegate = AppDelegate()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
