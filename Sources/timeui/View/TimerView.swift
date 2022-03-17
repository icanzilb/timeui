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

import SwiftUI
import Foundation
import Combine

extension FloatingPoint {
    var whole: Self { modf(self).0 }
    var fraction: Self { modf(self).1 }
}

func timerFormatted(_ duration: TimeInterval) -> String {
    let nanos = min(duration.fraction * 100, 99)
    let minutes = (duration / 360.0).whole
    let seconds = duration.whole - (minutes * 360.0)
    return String(format: "%02.f:%02.f.%02.f", minutes, seconds, nanos)
}

struct TimerView: View {
    @EnvironmentObject var model: RunnerModel

    @State var timer: Timer? = nil
    @State var started = CACurrentMediaTime()
    @State var text = "00:00.000"
    @State var isFinished = false

    private let finishedColor = Color.white
    private let runningColor = Color(hex: 0xcccccc)

    private let regionFinishedColor = Color(hex: 0xcccccc)
    private let regionRunningColor = Color(hex: 0x000000)

    @State var regions = [RegionEntry]()
    @State var regionsCancellable: AnyCancellable?
    @State var stats = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                Text(text)
                    .font(.custom("Menlo", fixedSize: 21.0).bold())
                    .foregroundColor(isFinished ? finishedColor : runningColor)


                if !stats.isEmpty {
                    Text(stats)
                        .font(.custom("Menlo", fixedSize: 10.0).bold())
                        .foregroundColor(isFinished ? finishedColor : runningColor)
                        .frame(height: 25)
                }

                if !regions.isEmpty {
                    VStack (alignment: .leading) {
                        ForEach(regions, id: \.id) { region in
                            VStack(alignment: .leading) {
                                Text(timerFormatted(region.durationNow()))
                                    .font(.custom("Menlo", fixedSize: 15.0).bold())
                                Text("\(region.count)x \(region.name)")
                                    .font(.caption)
                            }
                            .frame(height: 35)
                            .foregroundColor(region.started == nil ? regionFinishedColor : regionRunningColor)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .padding()
        }
        .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
        .onReceive(model.runner.state) { newState in
            switch newState {
            case .running(let started):
                self.started = started
                timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { timer in
                    text = timerFormatted(CACurrentMediaTime() - started)

                    let sampleUsage = model.usage.usage
                    if sampleUsage.memory.total > 0 {
                        let memFootprintMB = Double(sampleUsage.memory.used) / 1024 / 1024
                        let memPercentage = Double(sampleUsage.memory.used) / Double(sampleUsage.memory.total) * 100
                        stats = String(format: "CPU: %.0f%%\nMemory: %.0f%% %.2fMb", sampleUsage.cpu, memPercentage, memFootprintMB)
                    }
                })
            case .completed(let duration):
                timer?.invalidate()
                text = timerFormatted(duration)
                isFinished = true
            default: break
            }
        }
        .onChange(of: model.logDataSource) { dataSource in
            if let source = dataSource {
                regionsCancellable = source.regionsSubject
                    .sink(receiveValue: { newRegions in
                        //print(newRegions)
                        regions = source.regionOrder.map {
                            newRegions[$0]!
                        }
                    })
            }
        }
    }
}
