//
//  TableViewDataCreator.swift
//  Paintist
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

    public fileprivate (set) var toggleButtonThumbColorOn: UIColor?
    public fileprivate (set) var toggleButtonThumbColorOff: UIColor?
    public fileprivate (set) var toggleButtonBgColorOn: UIColor?
    
    public fileprivate (set) var sectionVerticalMargin: CGFloat?
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
}

public class TableCell {
    
    fileprivate static let CELL_ID_OPERATION = "Operation"
    fileprivate static let CELL_ID_TOGGLE = "Toggle"
    
    public enum CellType: Int {
        case operation
        case toggle
    }
    
    public let cellId: Int?
    public let cellType: CellType
    public let title: String
    public let icon: UIImage?

    public init(cellId: Int? = nil, cellType: CellType, title: String, icon: UIImage? = nil) {
        self.cellId = cellId
        self.cellType = cellType
        self.title = title
        self.icon = icon
    }
}

public class TableCellOperation: TableCell {
    
    public var detailedText: String?
    public var accessaryView: UIView?
    public let operationDidClick: ((_ operationCell: TableCellOperation, _ indexPath: IndexPath) -> Void)?
    
    init(cellId: Int? = nil, title: String, detailedText: String? = nil, icon: UIImage? = nil, accessoryView: UIView? = nil,
         didClick: ((_ operationCell: TableCellOperation, _ indexPath: IndexPath) -> Void)? = nil) {
        self.detailedText = detailedText
        self.accessaryView = accessoryView
        self.operationDidClick = didClick
        super.init(cellId: cellId, cellType: .operation, title: title, icon: icon)
    }
}

public class TableCellToggle: TableCell {
    
    public var isOn: Bool
    public let toggleWilChange: ((_ from: Bool) -> Bool)?
    public let toggleDidChange: ((_ from: Bool, _ to: Bool) -> Void)?
    
    public init(cellId: Int? = nil, title: String, isOn: Bool, icon: UIImage? = nil,
         toggleWilChange: ((_ from: Bool) -> Bool)? = nil,
         toggleDidChange: ((_ from: Bool, _ to: Bool) -> Void)? = nil) {
        self.isOn = isOn
        self.toggleWilChange = toggleWilChange
        self.toggleDidChange = toggleDidChange
        super.init(cellId: cellId, cellType: .toggle, title: title, icon: icon)
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
        return indexPath.section * 100 + indexPath.row
    }
    
    fileprivate func indexPathFrom(innerCellId: Int) -> IndexPath {
        return IndexPath(row: innerCellId % 100, section: innerCellId / 100)
    }
    
    public func tableCell(ofCellId cellId: Int) -> TableCell? {
        return cellIdToCell[cellId]
    }
}

extension TableData: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerTitle
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sections[indexPath.section].cells[indexPath.row]
        if cell.cellType == .operation {
            let operation = cell as! TableCellOperation
            let row = tableView.dequeueReusableCell(withIdentifier: TableCell.CELL_ID_OPERATION)  as? TableViewCellOperation ??
                TableViewCellOperation(style: .value1, reuseIdentifier: TableCell.CELL_ID_OPERATION)
            
            applyCommon(cellView: row, cellData: cell, indexPath: indexPath)
            row.detailTextLabel?.text = operation.detailedText
            row.accessoryView = operation.accessaryView
            return row
            
        } else { // toggle
            let toggle = cell as! TableCellToggle
            let row = tableView.dequeueReusableCell(withIdentifier: TableCell.CELL_ID_TOGGLE) as? TableViewCellToggle ??
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
        let cell = sections[indexPath.section].cells[indexPath.row]
        guard let cellOperation = cell as? TableCellOperation else {
            return
        }
        cellOperation.operationDidClick?(cellOperation, indexPath)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let baseHeight: CGFloat = 44
        if let sectionVerticalMargin = configure.sectionVerticalMargin {
            if indexPath.row == 0 {
                return baseHeight + sectionVerticalMargin
            }
            
            if indexPath.row == sections[indexPath.section].cells.count - 1 {
                return baseHeight + sectionVerticalMargin
            }
        }
        return baseHeight
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
        
        if let sectionVerticalMargin = configure.sectionVerticalMargin {
            if indexPath.row == 0 {
                cellView.marginTop = sectionVerticalMargin / 2
                
            } else if indexPath.row == sections[indexPath.section].cells.count - 1 {
                cellView.marginBottom = sectionVerticalMargin / 2
            }
        }
    }
    
    @objc private func onSwitchButtonChanged(sender: UISwitch) {
        applySwitchThumbColor(sender)

        let indexPath = indexPathFrom(innerCellId: sender.tag)
        let cellToggle = sections[indexPath.section].cells[indexPath.row] as! TableCellToggle
        if let willChangeCallback = cellToggle.toggleWilChange {
            if !willChangeCallback(!sender.isOn) {
                // revert
                sender.isOn = !sender.isOn
                applySwitchThumbColor(sender)
                return
            }
        }
        cellToggle.toggleDidChange?(!sender.isOn, sender.isOn)
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
                          toggleButtonThumbColorOn: UIColor? = nil,
                          toggleButtonThumbColorOff: UIColor? = nil,
                          toggleButtonBgColorOn: UIColor?,
                          sectionVerticalMargin: CGFloat? = 0) -> TableDataBuilder {
        data.configure.cellBackgroundColor = cellBackgroundColor
        
        data.configure.titleTextColor = titleTextColor
        
        data.configure.toggleButtonThumbColorOn = toggleButtonThumbColorOn
        data.configure.toggleButtonThumbColorOff = toggleButtonThumbColorOff
        data.configure.toggleButtonBgColorOn = toggleButtonBgColorOn
        
        data.configure.sectionVerticalMargin = sectionVerticalMargin

        return self
    }
    
    public func section(headerTitle: String? = nil, footerTitle: String? = nil) -> TableDataBuilder {
        data.appendSection(headerTitle: headerTitle, footerTitle: footerTitle)
        return self
    }
    
    public func operationCell(id: Int? = nil, title: String, detailedText: String? = nil,
                              icon: UIImage? = nil,
                              accessoryView: UIView? = nil,
                              didClick: ((_ operationCell: TableCellOperation, _ idnexPath: IndexPath) -> Void)? = nil) -> TableDataBuilder {
        let cellOperation = TableCellOperation(cellId: id, title: title, detailedText: detailedText, icon: icon, accessoryView: accessoryView,
                                               didClick: didClick)
        data.addCell(cell: cellOperation)
        return self
    }
    
    public func toggleCell(id: Int? = nil, title: String, isOn: Bool,
                           icon: UIImage? = nil,
                           toggleWillChange: ((_ from: Bool) -> Bool)? = nil,
                           toggleDidChange: ((_ from: Bool, _ to: Bool) -> Void)? = nil) -> TableDataBuilder {
        let cellToggle = TableCellToggle(cellId: id, title: title, isOn: isOn, icon: icon,
                                         toggleWilChange: toggleWillChange,
                                         toggleDidChange: toggleDidChange)
        data.addCell(cell: cellToggle)
        return self
    }
    
    public func build() -> TableData {
        return data
    }
}
