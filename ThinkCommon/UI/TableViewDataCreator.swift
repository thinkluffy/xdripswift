//
//  TableViewDataCreator.swift
//  Thinkyeah
//
//  Created by Yuanbin Cai on 2020/4/13.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

fileprivate class BaseTableViewCell: UITableViewCell {

    fileprivate var marginTop: CGFloat?
    fileprivate var marginBottom: CGFloat?

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        if marginTop != nil {
            contentView.frame.origin.y += marginTop!
        }

        if marginBottom != nil {
            contentView.frame.origin.y -= marginBottom!
        }
    }
}

fileprivate class TableViewCellToggle: BaseTableViewCell {

    fileprivate let switchButton = UISwitch(frame: .zero)

    fileprivate required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    fileprivate override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    fileprivate func setupView() {
        accessoryView = switchButton
        selectionStyle = .none
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        if marginTop != nil {
            switchButton.frame.origin.y += marginTop!
        }

        if marginBottom != nil {
            switchButton.frame.origin.y -= marginBottom!
        }
    }
}

fileprivate class TableViewCellOperation: BaseTableViewCell {

    fileprivate required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    fileprivate override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    fileprivate func setupView() {
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        if marginTop != nil {
            accessoryView?.frame.origin.y += marginTop!
        }

        if marginBottom != nil {
            accessoryView?.frame.origin.y -= marginBottom!
        }
    }
}

public struct TableConfigure {

    public fileprivate (set) var cellBackgroundColor: UIColor?

    public fileprivate (set) var titleTextColor: UIColor?
    public fileprivate (set) var detailTextColor: UIColor?

    public fileprivate (set) var toggleButtonThumbColorOn: UIColor?
    public fileprivate (set) var toggleButtonThumbColorOff: UIColor?
    public fileprivate (set) var toggleButtonBgColorOn: UIColor?

    public fileprivate (set) var sectionVerticalMargin: CGFloat?
    public fileprivate (set) var sectionHeaderColor: UIColor?
}

public class TableSection {

    public let headerTitle: String?
    public let footerTitle: String?

    public fileprivate (set) var cells: [TableCell] = []

    public init(headerTitle: String? = nil, footerTitle: String? = nil) {
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
    }

    public func addCell(cell: TableCell) {
        cells.append(cell)
    }

    public var visibleCells: [TableCell] {
        cells.filter { cell in
            !cell.isHidden
        }
    }
}

public class TableCell {

    fileprivate static let cellIdOperation = "Operation"
    fileprivate static let cellIdToggle = "Toggle"

    public enum CellType: Int {
        case operation
        case toggle
    }

    public let cellId: Int?
    public let cellType: CellType
    public let title: String
    public let icon: UIImage?
    public var isHidden = false

    public init(cellId: Int? = nil, cellType: CellType, title: String, icon: UIImage? = nil) {
        self.cellId = cellId
        self.cellType = cellType
        self.title = title
        self.icon = icon
    }
}

public class TableCellOperation: TableCell {

    public var detailedText: String?
    public var accessoryView: UIView?
    public var accessoryType: UITableViewCell.AccessoryType
    public let operationDidClick: ((_ operationCell: TableCellOperation,
                                    _ tableView: UITableView,
                                    _ indexPath: IndexPath) -> Void)?

    init(cellId: Int? = nil,
         title: String,
         detailedText: String? = nil,
         icon: UIImage? = nil,
         accessoryView: UIView? = nil,
         accessoryType: UITableViewCell.AccessoryType = .none,
         isHidden: Bool = false,
         didClick clickHandler: ((_ operationCell: TableCellOperation, _ tableView: UITableView, _ indexPath: IndexPath) -> Void)? = nil) {
        self.detailedText = detailedText
        self.accessoryView = accessoryView
        self.accessoryType = accessoryType
        operationDidClick = clickHandler
        super.init(cellId: cellId, cellType: .operation, title: title, icon: icon)
        self.isHidden = isHidden
    }
}

public class TableCellToggle: TableCell {

    public var isOn: Bool
    public let toggleWilChange: ((_ toggleCell: TableCellToggle,
                                  _ from: Bool) -> Bool)?
    public let toggleDidChange: ((_ toggleCell: TableCellToggle,
                                  _ from: Bool,
                                  _ to: Bool) -> Void)?

    public init(cellId: Int? = nil,
                title: String,
                isOn: Bool,
                icon: UIImage? = nil,
                isHidden: Bool = false,
                toggleWilChange: ((_ toggleCell: TableCellToggle,
                                   _ from: Bool) -> Bool)? = nil,
                toggleDidChange: ((_ toggleCell: TableCellToggle,
                                   _ from: Bool,
                                   _ to: Bool) -> Void)? = nil) {
        self.isOn = isOn
        self.toggleWilChange = toggleWilChange
        self.toggleDidChange = toggleDidChange
        super.init(cellId: cellId, cellType: .toggle, title: title, icon: icon)
        self.isHidden = isHidden
    }
}

public class TableData: NSObject {

    public fileprivate (set) var configure = TableConfigure()
    public fileprivate (set) var sections: [TableSection] = []

    private var cellIdToCell = [Int: TableCell]()

    public func appendSection(headerTitle: String?, footerTitle: String?) {
        sections.append(TableSection(headerTitle: headerTitle, footerTitle: footerTitle))
    }

    public var currentSection: TableSection {
        if sections.isEmpty {
            sections.append(TableSection())
        }
        return sections.last!
    }

    public func addCell(cell: TableCell) {
        currentSection.addCell(cell: cell)
        if let cellId = cell.cellId {
            cellIdToCell[cellId] = cell
        }
    }

    fileprivate func innerCellId(from indexPath: IndexPath) -> Int {
        indexPath.section * 100 + indexPath.row
    }

    fileprivate func indexPathFrom(innerCellId: Int) -> IndexPath {
        IndexPath(row: innerCellId % 100, section: innerCellId / 100)
    }

    public func tableCell(ofCellId cellId: Int) -> TableCell? {
        cellIdToCell[cellId]
    }
}

extension TableData: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].visibleCells.count
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].headerTitle
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footerTitle
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sections[indexPath.section].visibleCells[indexPath.row]
        if cell.cellType == .operation {
            let operation = cell as! TableCellOperation
            let row = tableView.dequeueReusableCell(withIdentifier: TableCell.cellIdOperation) as? TableViewCellOperation ??
                    TableViewCellOperation(style: .value1, reuseIdentifier: TableCell.cellIdOperation)

            applyCommon(cellView: row, cellData: cell, indexPath: indexPath)
            row.detailTextLabel?.text = operation.detailedText
            row.accessoryView = operation.accessoryView
            row.accessoryType = operation.accessoryType
            return row

        } else { // toggle
            let toggle = cell as! TableCellToggle
            let row = tableView.dequeueReusableCell(withIdentifier: TableCell.cellIdToggle) as? TableViewCellToggle ??
                    TableViewCellToggle()

            applyCommon(cellView: row, cellData: cell, indexPath: indexPath)
            row.switchButton.isOn = toggle.isOn
            row.switchButton.tag = innerCellId(from: indexPath)
            row.switchButton.onTintColor = configure.toggleButtonBgColorOn
            applySwitchThumbColor(row.switchButton)
            row.switchButton.addTarget(self, action: #selector(onSwitchButtonChanged(sender:)), for: .valueChanged)

            return row
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = sections[indexPath.section].visibleCells[indexPath.row]
        guard let cellOperation = cell as? TableCellOperation else {
            return
        }
        cellOperation.operationDidClick?(cellOperation, tableView, indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let baseHeight: CGFloat = 44
        if let sectionVerticalMargin = configure.sectionVerticalMargin {
            if indexPath.row == 0 {
                return baseHeight + sectionVerticalMargin
            }

            if indexPath.row == sections[indexPath.section].visibleCells.count - 1 {
                return baseHeight + sectionVerticalMargin
            }
        }
        return baseHeight
    }

    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView, let sectionHeaderColor = configure.sectionHeaderColor {
            view.textLabel?.textColor = sectionHeaderColor
        }
    }

    private func applyCommon(cellView: BaseTableViewCell, cellData: TableCell, indexPath: IndexPath) {
        cellView.textLabel?.text = cellData.title
        cellView.imageView?.image = cellData.icon

        if let theBgColor = configure.cellBackgroundColor {
            cellView.backgroundColor = theBgColor
        }

        if let titleTextColor = configure.titleTextColor {
            cellView.textLabel?.textColor = titleTextColor
        }

        if let detailTextColor = configure.detailTextColor {
            cellView.detailTextLabel?.textColor = detailTextColor
        }

        if let sectionVerticalMargin = configure.sectionVerticalMargin {
            if indexPath.row == 0 {
                cellView.marginTop = sectionVerticalMargin / 2

            } else if indexPath.row == sections[indexPath.section].visibleCells.count - 1 {
                cellView.marginBottom = sectionVerticalMargin / 2
            }
        }
    }

    @objc private func onSwitchButtonChanged(sender: UISwitch) {
        applySwitchThumbColor(sender)

        let indexPath = indexPathFrom(innerCellId: sender.tag)
        let cellToggle = sections[indexPath.section].visibleCells[indexPath.row] as! TableCellToggle
        if let willChangeCallback = cellToggle.toggleWilChange {
            if !willChangeCallback(cellToggle, !sender.isOn) {
                // revert
                sender.isOn = !sender.isOn
                applySwitchThumbColor(sender)
                return
            }
        }
        cellToggle.isOn = sender.isOn
        // wait uiSwitch animation completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cellToggle.toggleDidChange?(cellToggle, !sender.isOn, sender.isOn)
        }
    }

    private func applySwitchThumbColor(_ switchButton: UISwitch) {
        if switchButton.isOn {
            switchButton.thumbTintColor = configure.toggleButtonThumbColorOn

        } else {
            switchButton.thumbTintColor = configure.toggleButtonThumbColorOff
        }
    }
}

public class TableDataBuilder {

    private var data = TableData()

    public func configure(cellBackgroundColor: UIColor? = nil,
                          titleTextColor: UIColor? = nil,
                          detailTextColor: UIColor? = nil,
                          toggleButtonThumbColorOn: UIColor? = nil,
                          toggleButtonThumbColorOff: UIColor? = nil,
                          toggleButtonBgColorOn: UIColor? = nil,
                          sectionVerticalMargin: CGFloat? = 0,
                          sectionHeaderColor: UIColor? = nil) -> TableDataBuilder {
        data.configure.cellBackgroundColor = cellBackgroundColor

        data.configure.titleTextColor = titleTextColor
        data.configure.detailTextColor = detailTextColor

        data.configure.toggleButtonThumbColorOn = toggleButtonThumbColorOn
        data.configure.toggleButtonThumbColorOff = toggleButtonThumbColorOff
        data.configure.toggleButtonBgColorOn = toggleButtonBgColorOn

        data.configure.sectionVerticalMargin = sectionVerticalMargin
        data.configure.sectionHeaderColor = sectionHeaderColor

        return self
    }

    public func section(headerTitle: String? = nil, footerTitle: String? = nil) -> TableDataBuilder {
        data.appendSection(headerTitle: headerTitle, footerTitle: footerTitle)
        return self
    }

    public func operationCell(id: Int? = nil,
                              title: String,
                              detailedText: String? = nil,
                              icon: UIImage? = nil,
                              accessoryType: UITableViewCell.AccessoryType = .none,
                              accessoryView: UIView? = nil,
                              isHidden: Bool = false,
                              didClick clickHandler: ((_ operationCell: TableCellOperation,
                                                       _ tableView: UITableView,
                                                       _ indexPath: IndexPath) -> Void)? = nil) -> TableDataBuilder {
        let cellOperation = TableCellOperation(cellId: id,
                title: title,
                detailedText: detailedText,
                icon: icon,
                accessoryView: accessoryView,
                accessoryType: accessoryType,
                isHidden: isHidden,
                didClick: clickHandler)
        data.addCell(cell: cellOperation)
        return self
    }

    public func toggleCell(id: Int? = nil,
                           title: String,
                           isOn: Bool,
                           icon: UIImage? = nil,
                           isHidden: Bool = false,
                           toggleWillChange: ((_ toggleCell: TableCellToggle,
                                               _ from: Bool) -> Bool)? = nil,
                           toggleDidChange: ((_ toggleCell: TableCellToggle,
                                              _ from: Bool,
                                              _ to: Bool) -> Void)? = nil) -> TableDataBuilder {
        let cellToggle = TableCellToggle(cellId: id,
                title: title,
                isOn: isOn,
                icon: icon,
                isHidden: isHidden,
                toggleWilChange: toggleWillChange,
                toggleDidChange: toggleDidChange)
        data.addCell(cell: cellToggle)
        return self
    }

    public func build() -> TableData {
        data
    }
}
