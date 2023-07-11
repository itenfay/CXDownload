//
//  BaseView.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

protocol IBaseView: AnyObject {
    func setup()
    func layoutUI()
    func addActions()
}

class BaseView: UIView, IBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        layoutUI()
        addActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {}
    
    func layoutUI() {}
    
    func addActions() {}
    
}

class BaseNibView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        layoutUI()
        addActions()
    }
    
    func setup() {}
    
    func layoutUI() {}
    
    func addActions() {}
}

class BaseTableViewCell: UITableViewCell, IBaseView {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        layoutUI()
        addActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        layoutUI()
        addActions()
    }
    
    func setup() {
        
    }
    
    func layoutUI() {
        
    }
    
    func addActions() {
        
    }
    
}
