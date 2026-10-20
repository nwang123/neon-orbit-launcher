import Cocoa
import WebKit

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class Launcher: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    var window: NSWindow!
    var web: WKWebView!
    var target: URL?
    var client: NSRunningApplication?
    var launchInProgress = false
    var finishing = false
    var handedOff = false
    var monitor: Any?
    var deadline: Timer?
    let args = CommandLine.arguments
    var snapshot: Bool { args.contains("--snapshot") }
    var resources: URL { Bundle.main.resourceURL! }
    func argument(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), args.count > i+1 else { return nil }
        return args[i+1]
    }
    func log(_ event: String) {
        guard let path = argument("--test-log") else { return }
        let line = "\(Date().timeIntervalSince1970) \(event)\n"
        if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil) }
        if let file = FileHandle(forWritingAtPath: path) { file.seekToEndOfFile(); file.write(Data(line.utf8)); try? file.close() }
    }
    func resolveClient() -> URL? {
        for id in ["com.openai.codex", "com.openai.chat"] {
            if let running = NSRunningApplication.runningApplications(withBundleIdentifier: id).first, let url = running.bundleURL { client = running; return url }
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) { return url }
        }
        return nil
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        target = resolveClient()
        if args.contains("--self-test") {
            let data: [String: Any] = ["target": target?.path ?? "", "bundle": target.flatMap { Bundle(url: $0)?.bundleIdentifier } ?? "", "animation": FileManager.default.fileExists(atPath: resources.appendingPathComponent("animation.html").path), "architecture": "native"]
            print(String(data: try! JSONSerialization.data(withJSONObject: data, options: [.sortedKeys]), encoding: .utf8)!)
            NSApp.terminate(nil); return
        }
        if !snapshot {
            let id = Bundle.main.bundleIdentifier!
            if NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) { NSApp.terminate(nil); return }
            guard target != nil else { let alert = NSAlert(); alert.messageText = "未找到 Codex 或 ChatGPT"; alert.informativeText = "请先安装客户端，再使用动画启动器。"; alert.runModal(); NSApp.terminate(nil); return }
        }
        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main!
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "launcher")
        web = WKWebView(frame: .zero, configuration: config)
        web.setValue(false, forKey: "drawsBackground")
        web.navigationDelegate = self
        let captureWidth = Double(argument("--width") ?? "")
        let captureHeight = Double(argument("--height") ?? "")
        let frame = snapshot && captureWidth != nil && captureHeight != nil ? NSRect(x: 0, y: 0, width: captureWidth!, height: captureHeight!) : screen.frame
        window = OverlayWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.title = "Neon Orbit"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = web
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.finish(); return nil }
            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" { self?.finish(); return nil }
            return event
        }
        web.loadFileURL(resources.appendingPathComponent("animation.html"), allowingReadAccessTo: resources)
        if !snapshot { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
        log("overlay-start target=\(target?.path ?? "preview")")
        deadline = Timer.scheduledTimer(withTimeInterval: 25, repeats: false) { [weak self] _ in self?.finish() }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if snapshot {
            let time = Double(argument("--snapshot") ?? "9") ?? 9
            web.evaluateJavaScript("window.stopAnimation = true; window.renderAt(\(time)); document.getElementById('skip').style.display = 'none'") { [weak self] _, error in
                guard let self = self else { return }
                if let error = error { print(error); NSApp.terminate(nil); return }
                DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                    self.web.takeSnapshot(with: nil) { image, error in
                        if let image = image, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]), let path = self.argument("--output") {
                            do { try png.write(to: URL(fileURLWithPath: path)); print("snapshot written: \(path)") } catch { print(error) }
                        } else { print("snapshot error: \(String(describing: error))") }
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { log("web-error \(error)"); finish() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { log("web-load-error \(error)"); finish() }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { log("web-process-ended"); finish() }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard !snapshot, let action = message.body as? String else { return }
        if action == "launch" { prepareClient() }
        if action == "done" { finish() }
    }
    func prepareClient() {
        guard !launchInProgress else { return }
        if let client = client, !client.isTerminated {
            log("client-reused pid=\(client.processIdentifier)")
            if finishing { handoff() }; return
        }
        guard let target = target else { handoff(); return }
        launchInProgress = true
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: target, configuration: configuration) { [weak self] app, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.launchInProgress = false
                self.client = app
                self.log(error == nil ? "client-opened pid=\(app?.processIdentifier ?? 0)" : "client-error \(error!)")
                if let error = error {
                    self.window.orderOut(nil)
                    let alert = NSAlert(); alert.messageText = "客户端未能打开"; alert.informativeText = error.localizedDescription; alert.runModal()
                    self.handoff()
                } else if self.finishing { self.handoff() }
            }
        }
    }
    func finish() {
        guard !finishing else { if handedOff == false && !launchInProgress { handoff() }; return }
        finishing = true
        if snapshot { NSApp.terminate(nil); return }
        window?.orderOut(nil)
        log("overlay-finished")
        prepareClient()
        DispatchQueue.main.asyncAfter(deadline: .now()+4) { [weak self] in self?.handoff() }
    }
    func handoff() {
        guard !handedOff else { return }
        handedOff = true
        window?.orderOut(nil)
        if let client = client, !client.isTerminated { client.activate(options: [.activateAllWindows, .activateIgnoringOtherApps]); log("handoff pid=\(client.processIdentifier)") }
        NSApp.terminate(nil)
    }
    func applicationWillTerminate(_ notification: Notification) {
        deadline?.invalidate()
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
        web?.configuration.userContentController.removeScriptMessageHandler(forName: "launcher")
        log("exit")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Launcher()
app.delegate = delegate
app.run()
