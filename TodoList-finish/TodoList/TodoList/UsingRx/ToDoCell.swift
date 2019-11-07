//
//  ToDoCell.swift
//  TodoList
//
//  Created by Nakama on 01/11/19.
//  Copyright © 2019 Bloc. All rights reserved.
//

import Foundation
import UIKit

internal class ToDoCell: UITableViewCell {
    static let identifierCell = "TaskCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
