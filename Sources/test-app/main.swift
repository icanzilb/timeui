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

//
// A test app that does some faux calculations and tracks activity intervals.
// Compile and provide as a paramter to the timeui app:
//  1. To track time only: `timeui test-app`
//  2. To track time and cpu: `sudo timeui test-app`
//

import Foundation
import os

let log = OSLog(subsystem: "mySystem", category: .pointsOfInterest)

func delay(_ seconds: Double, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
}

print("Test app to use as source for testing timeui.")
print("Started...")

var data = [Double]()

delay(1) {
    os_signpost(.begin, log: log, name: "My Activity")
    data.append(contentsOf: Array<Double>(repeating: 500_000.123123, count: 10_500_000))
}

delay(2.5) {
    os_signpost(.begin, log: log, name: "Another interval")
    os_signpost(.end, log: log, name: "My Activity")
    data.append(contentsOf: Array<Double>(repeating: 500_000.123123, count: 10_500_000))
}

delay(4) { os_signpost(.begin, log: log, name: "My Activity") }
delay(5) {
    os_signpost(.end, log: log, name: "Another interval")
    data.append(contentsOf: Array<Double>(repeating: 500_000.1312312, count: 10_500_000))
}
delay(6) { os_signpost(.end, log: log, name: "My Activity") }
delay(7) { print("Done."); exit(0) }

RunLoop.main.run()
