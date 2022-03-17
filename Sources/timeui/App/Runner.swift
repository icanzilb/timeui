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

import QuartzCore
import Combine

class Runner {
    enum State {
        case ready
        case running(started: TimeInterval)
        case completed(duration: TimeInterval)
        case error(message: String)
    }
    
    let state = CurrentValueSubject<State, Never>(.ready)

    private var started = Date.distantPast.timeIntervalSinceReferenceDate
    private var duration = Date.distantPast.timeIntervalSinceReferenceDate

    private var onTerminated: (() -> Void)?

    func run(_ location: URL, terminated: @escaping () -> Void) throws -> Int32 {
        let process = Process()
        process.executableURL = location
        process.environment = ProcessInfo.processInfo.environment
        process.arguments = ProcessInfo.processInfo.arguments
        process.terminationHandler = self.terminated(process:)

        started = CACurrentMediaTime()
        DispatchQueue.main.async {
            self.state.send(.running(started: self.started))
        }
        try process.run()

        onTerminated = terminated

        return process.processIdentifier
    }

    func terminated(process: Process) {
        duration = CACurrentMediaTime() - started
        DispatchQueue.main.async {
            self.state.send(.completed(duration: self.duration))
        }
        print(String(format: "Duration: %.4fs", duration))
        print("Close the timer window to quit the process.")
        process.terminate()

        onTerminated?()
        onTerminated = nil
    }
}
