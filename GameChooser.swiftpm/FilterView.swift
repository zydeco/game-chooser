import SwiftUI

struct FilterView: UIViewRepresentable {
    @Binding var playersRange: ClosedRange<Int>
    @Binding var timeOptions: [Int]
    @Binding var filter: GameFilter

    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        return tableView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, playerOptions: playersRange.map({$0}), timeOptions: timeOptions)
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        context.coordinator.updateValues(playerOptions: playersRange.map({$0}), timeOptions: timeOptions, filter: filter)
    }

    enum FilterType {
        case players
        case time
    }

    class Coordinator: NSObject {
        var parent: FilterView
        var headerView: UIView?
        var expandedFilter: FilterType?
        var playersLabel: UILabel?
        var timeLabel: UILabel?
        var playersPicker: UIPickerView?
        var timePicker: UIPickerView?
        var playerOptions: [Int]
        var timeOptions: [Int]
        var defaultTimeFilter: ClosedRange<Int> { timeOptions[0]...timeOptions.last! }

        init(_ parent: FilterView, playerOptions: [Int], timeOptions: [Int]) {
            let headerLabel = UITextView(frame: .zero)
            headerLabel.text = "Filter"
            headerLabel.font = .preferredFont(forTextStyle: .extraLargeTitle2)
            headerLabel.isSelectable = false
            headerLabel.isEditable = false
            headerLabel.backgroundColor = .clear
            headerLabel.textContainerInset = .init(top: 18.0, left: 0.0, bottom: 12.0, right: 0.0)
            headerLabel.sizeToFit()
            self.headerView = headerLabel
            self.playersLabel = makeValueLabel("\(playerOptions[0]) to \(playerOptions.last!)")
            self.timeLabel = makeValueLabel("\(timeOptions[0]) to \(timeOptions.last!) minutes")
            self.playerOptions = []
            self.timeOptions = []
            self.parent = parent
            super.init()
            self.playersPicker = makePicker(self)
            self.timePicker = makePicker(self)
            updateValues(playerOptions: playerOptions, timeOptions: timeOptions, filter: parent.filter)
        }

        func updateValues(playerOptions: [Int], timeOptions: [Int], filter: GameFilter) {
            var filter = filter
            if playerOptions != self.playerOptions {
                self.playerOptions = playerOptions
                if filter.players != nil && playerOptions.firstIndex(of: filter.players!) == nil {
                    filter.players = nil
                    playersPicker?.selectRow(0, inComponent: 0, animated: expandedFilter == .players)
                }
            }
            if timeOptions != self.timeOptions {
                self.timeOptions = timeOptions
                filter.time = updatePicker(timePicker!, withOptions: timeOptions, filter: filter.time ?? defaultTimeFilter, animated: expandedFilter == .time)
            }
            if filter != parent.filter {
                parent.filter = filter
            }
            updatePlayersLabel(filter)
            updateTimeLabel(filter)
        }

        func updatePicker(_ picker: UIPickerView, withOptions options: [Int], filter: ClosedRange<Int>, animated: Bool) -> ClosedRange<Int> {
            picker.reloadAllComponents()
            if let lowBoundIndex = options.firstIndex(of: filter.lowerBound) {
                picker.selectRow(lowBoundIndex, inComponent: 0, animated: animated)
            } else {
                picker.selectRow(0, inComponent: 0, animated: animated)
                return options[0]...filter.upperBound
            }
            if let hiBoundIndex = options.firstIndex(of: filter.upperBound) {
                picker.selectRow(hiBoundIndex, inComponent: 2, animated: animated)
            } else {
                picker.selectRow(options.count-1, inComponent: 0, animated: animated)
                return filter.lowerBound...options.last!
            }
            return filter
        }

        func updateTimeLabel(_ filter: GameFilter) {
            if let time = filter.time {
                timeLabel?.text = "\(time.lowerBound) to \(time.upperBound) minutes"
            } else {
                timeLabel?.text = "any"
            }
            timeLabel?.sizeToFit()
        }

        func updatePlayersLabel(_ filter: GameFilter) {
            if let players = filter.players {
                playersLabel?.text = "\(players)"
            } else {
                playersLabel?.text = "any"
            }
            playersLabel?.sizeToFit()
        }
    }
}

func makeValueLabel(_ text: String) -> UILabel {
    let label = UILabel(frame: .zero)
    label.text = text
    label.sizeToFit()
    let bgView = UIView(frame: label.frame.insetBy(dx: -12.0, dy: -6.0))
    bgView.backgroundColor = .black.withAlphaComponent(0.05)
    bgView.layer.cornerRadius = 6.0
    bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    bgView.translatesAutoresizingMaskIntoConstraints = true
    label.autoresizesSubviews = true
    label.addSubview(bgView)
    return label
}

func makePicker<T: UIPickerViewDelegate & UIPickerViewDataSource>(_ delegateAndDataSource: T) -> UIPickerView {
    let picker = UIPickerView(frame: .zero)
    picker.delegate = delegateAndDataSource
    picker.dataSource = delegateAndDataSource
    picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return picker
}

extension FilterView.Coordinator: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expandedFilter == nil ? 2 : 3
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch (indexPath.row, expandedFilter) {
        case (0, .players):
            expandedFilter = nil
            tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .top)
        case (0, _):
            tableView.beginUpdates()
            if expandedFilter == .time {
                tableView.deleteRows(at: [IndexPath(row:2, section: 0)], with: .top)
            }
            expandedFilter = .players
            tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .top)
            tableView.endUpdates()
        case (1, nil):
            expandedFilter = .time
            tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .top)
        case (1, .time):
            expandedFilter = nil
            tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .top)
        case (2, .players):
            expandedFilter = .time
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .top)
            tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .top)
            tableView.endUpdates()
        default:
            break
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.row, expandedFilter) {
        case (1, .players):
            fallthrough
        case (2, .time):
            return 160.0
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        var content = UIListContentConfiguration.cell()
        switch (indexPath.row, expandedFilter) {
        case (0, _):
            content.text = "Players"
            cell.accessoryView = playersLabel
            cell.contentConfiguration = content
        case (1, .players):
            cell.contentView.addSubview(playersPicker!)
            playersPicker?.frame = cell.contentView.bounds
        case (1, _):
            fallthrough
        case (2, .players):
            content.text = "Time"
            cell.accessoryView = timeLabel
            cell.contentConfiguration = content
        case (2, _):
            cell.contentView.addSubview(timePicker!)
            timePicker?.frame = cell.contentView.bounds
        default:
            fatalError()
        }
        return cell
    }
}

extension FilterView.Coordinator: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerView == timePicker ? 3 : 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 1 {
            return 1
        }

        if pickerView == playersPicker {
            return playerOptions.count + 1
        } else if pickerView == timePicker {
            return timeOptions.count
        }
        fatalError("Unknown picker")
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 1 {
            return "to"
        }

        if pickerView == playersPicker {
            if row == 0 {
                return "any"
            } else {
                return "\(playerOptions[row-1])"
            }
        } else if pickerView == timePicker {
            return formatMinutes(timeOptions[row])
        }
        fatalError("Unknown picker")
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var filter = parent.filter
        if pickerView == playersPicker {
            filter.players = row == 0 ? nil : playerOptions[row-1]
        } else if pickerView == timePicker {
            filter.time = updateRange(picker: pickerView, row: row, component: component, options: timeOptions, currentValue: filter.time ?? defaultTimeFilter)
        }
        parent.filter = filter
    }

    private func updateRange(picker: UIPickerView, row: Int, component: Int, options: [Int], currentValue: ClosedRange<Int>) -> ClosedRange<Int> {
        let newRange: ClosedRange<Int>
        if component == 0 {
            newRange = options[row]...max(currentValue.upperBound, options[row])
            if newRange.upperBound != currentValue.upperBound {
                picker.selectRow(options.firstIndex(of: newRange.upperBound)!, inComponent: 2, animated: true)
            }
        } else if component == 2 {
            newRange = min(currentValue.lowerBound,options[row])...options[row]
            if newRange.lowerBound != currentValue.lowerBound {
                picker.selectRow(options.firstIndex(of: newRange.lowerBound)!, inComponent: 0, animated: true)
            }
        } else {
            newRange = currentValue
        }

        return newRange
    }
}
