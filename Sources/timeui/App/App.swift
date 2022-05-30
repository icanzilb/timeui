// MIT License
//
// Copyright (c) 2022 Marin Todorov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Cocoa
import Combine
import CryptoKit

extension String {
    var md5Digest: Insecure.MD5Digest {
        Insecure.MD5.hash(data: Data(self.utf8))
    }
}

extension String: Error {}

class App {
    static var shared: App!
    static func main(arguments: [String]) throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)

        shared = App(application: application)
        try shared.parseArguments(arguments)

        shared.runUIWithDelegate(
            ApplicationDelegate(
                window: shared.makeWindow(title: shared.targetURL.lastPathComponent)
            )
        )
    }

    let application: NSApplication
    let model = RunnerModel()

    var targetURL: URL!

    init(application: NSApplication) {
        self.application = application
    }

    func makeWindow(title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSMakeRect(0, 0, 10, 10),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "▶  " + title
        window.titlebarAppearsTransparent = true
        window.makeKeyAndOrderFront(window)

        class WindowDelegate: NSObject, NSWindowDelegate {
            func windowWillClose(_ notification: Notification) {
                NSApplication.shared.terminate(0)
            }
        }
        let windowDelegate = WindowDelegate()
        window.delegate = windowDelegate

        return window
    }

    func runUIWithDelegate(_ delegate: ApplicationDelegate) {
        application.delegate = delegate
        application.activate(ignoringOtherApps: true)
        application.run()
    }

    func parseArguments(_ args: [String]) throws {
        guard !args.isEmpty else {
            throw "Provide target path as first argument"
        }

        let url = URL(fileURLWithPath: args[0])

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw "'\(url.path)' not found"
        }

        targetURL = url

        model.arguments = Array(CommandLine.arguments.dropFirst())
    }

    func startRunner() throws {
        let pid = try model.runner.run(targetURL, terminated: {
            self.model.usage.stop()
        })

        model.logDataSource = LogDataSource()
        model.logDataSource!.run(pid: pid)
        model.usage.run(pid: pid)
    }
}
