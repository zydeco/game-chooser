import SwiftUI

struct TimeFilterChooser: View {
    @Binding var filter: GameFilter
    @Binding var showingTime: Bool
    var timeOptions: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Label {
                Text("Any")
            } icon: {
                Image(systemName: filter.time == nil ? "checkmark.circle" : "circle")
            }.onTapGesture {
                filter.time = nil
                showingTime = false
            }
            ForEach(timeOptions, id: \.self) { minutes in
                TimeFilterChooser.Checkbox(minutes: minutes, filter: $filter, options: timeOptions, showingTime: $showingTime)
            }
        }
    }

    private struct Checkbox: View {
        var minutes: Int
        @Binding var filter: GameFilter
        var options: [Int]
        @Binding var showingTime: Bool

        var body: some View {
            Label {
                Text(formatMinutes(minutes))
            } icon: {
                if let time = filter.time {
                    if time.lowerBound == 0 && time.upperBound == minutes {
                        Image(systemName: "checkmark.circle")
                    } else if time.lowerBound > 0 && time.contains(minutes) {
                        if time.upperBound != minutes {
                            Image(systemName: "circle.fill").overlay(Rectangle().frame(width: 11.0, height: 30, alignment:.bottomLeading).offset(y: 13.0).foregroundColor(.black))
                        } else {
                            Image(systemName: "circle.fill")
                        }
                    } else {
                        Image(systemName: "circle")
                    }
                } else {
                    Image(systemName: "circle")
                }

            }.onTapGesture {
                filter.time = 0...minutes
                showingTime = false
            }.onLongPressGesture {
                guard let time = filter.time,
                      let index = options.firstIndex(of: minutes),
                      let indexHi = options.firstIndex(of: time.upperBound)
                else {
                    filter.time = 0...minutes
                    return
                }
                if time.lowerBound == 0 {
                    if time.upperBound != minutes {
                        filter.time = min(time.upperBound, minutes)...max(time.upperBound, minutes)
                    } else {
                        filter.time = nil
                    }
                } else if minutes < time.lowerBound {
                    filter.time = minutes...time.upperBound
                } else if minutes > time.upperBound {
                    filter.time = time.lowerBound...minutes
                } else if minutes == time.lowerBound {
                    updateFilter(options[index+1]...time.upperBound)
                } else if minutes == time.upperBound {
                    updateFilter(time.lowerBound...options[index-1])
                } else if let indexLo = options.firstIndex(of: time.lowerBound) {
                    if index - indexLo <= indexHi - index {
                        // clamp on lower bound
                        filter.time = minutes...time.upperBound
                    } else {
                        // clamp on upper bound
                        filter.time = time.lowerBound...minutes
                    }
                } else {
                    filter.time = nil //0...minutes
                }
            }
        }

        func updateFilter(_ bounds: ClosedRange<Int>) {
            if bounds.lowerBound == bounds.upperBound {
                filter.time = 0...bounds.lowerBound
            } else {
                filter.time = bounds
            }
        }
    }

    fileprivate struct Preview: View {
        @State var filter = GameFilter(time: 30...120)
        @State var showingTime = false
        var timeOptions = [5, 30, 60, 120, 180, 240]

        var body: some View {
            VStack {
                if let time = filter.time {
                    Text("Selected: \(formatMinutes(time))")
                } else {
                    Text("Selected: any")
                }
                TimeFilterChooser(filter: $filter, showingTime: $showingTime, timeOptions: timeOptions)
            }
        }
    }
}


#Preview {
    TimeFilterChooser.Preview()
}
