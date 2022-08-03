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
import OSLog
import Combine

struct RegionEntry: Identifiable {
	var id: String {
		return name
	}
	
	let name: String
	var started: TimeInterval?
	var duration: TimeInterval = 0.0
	var count = 0

	func durationNow() -> TimeInterval {
		if let started = started {
			return duration + Date().timeIntervalSinceReferenceDate - started
		} else {
			return duration
		}
	}
}

class LogDataSource: Equatable {
	private let id = UUID().uuidString
	static func == (lhs: LogDataSource, rhs: LogDataSource) -> Bool {
		lhs.id == rhs.id
	}

	private var startDate = Date(timeIntervalSinceNow: 0)

	private(set) var regions = [String: RegionEntry]()
	private(set) var regionOrder = [String]()
	
	let regionsSubject = CurrentValueSubject<[String: RegionEntry], Never>([:])

	private var didFail = false

	private func fetchLogs(forPID pid: Int32) {
		guard !didFail else { return }

		guard let store = try? OSLogStore.local() else {
			NotificationCenter.default.post(name: .error, object: nil)
			print("Could not open the shared log for reading")
			timerSubscription?.cancel()
			didFail = true
			return
		}

		let period = store.position(date: startDate)

		let predicate = NSPredicate(format: "category == %@",
										argumentArray: ["PointsOfInterest"])

		guard let logs = try? store
			.getEntries(
				with: [],
				at: period,
				matching: predicate
			) else {
				NotificationCenter.default.post(name: .error, object: nil)
				print("Could not query the shared log")
				timerSubscription?.cancel()
				didFail = true
				return
			}

		var rawCount = 0
		for potentialLog in logs {

			guard let log = potentialLog as? OSLogEntrySignpost,
						log.processIdentifier == pid,
						log.date != startDate else { continue }

			rawCount += 1

			if log.signpostType == .intervalBegin {
				var data = regions[log.signpostName, default: RegionEntry(name: log.signpostName)]
				data.started = log.date.timeIntervalSinceReferenceDate
				data.count += 1
				regions[log.signpostName] = data
				if !regionOrder.contains(log.signpostName) {
					regionOrder.append(log.signpostName)
				}
			}
			if log.signpostType == .intervalEnd {
				if var data = regions[log.signpostName] {
					data.duration += log.date.timeIntervalSinceReferenceDate - (data.started ?? 0)
					data.started = nil
					regions[log.signpostName] = data
				}
			}

			startDate = log.date
		}

		if rawCount > 0 {
			// There are updates
			regionsSubject.send(regions)
		}
	}

	private var timerSubscription: AnyCancellable?
	private var lastTimestamp: TimeInterval = -1

	func run(pid: Int32) {
        timerSubscription = Timer.publish(every: 1.0, tolerance: nil, on: .main, in: .common, options: nil)
			.autoconnect()
			.sink(receiveValue: { _ in
				self.fetchLogs(forPID: pid)
			})
	}

    func stop() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}
