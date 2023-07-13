//
//  MineView.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

protocol MineViewable: AnyObject {
    func gotoCacheView()
    func gotoSettingsView()
}

class MineView: BaseView {
    
    weak var delegate: MinePresenterDelegate?
    
    override func setup() {
        buildView()
    }
    
    func buildView() {
        let paddingX: CGFloat = 30
        let paddingY: CGFloat = 50
        
        let cacheButton = UIButton(type: .custom)
        cacheButton.frame = CGRect(x: paddingX, y: -paddingY, width: kScreenW - 2*paddingX, height: 50)
        cacheButton.backgroundColor = .lightGray
        cacheButton.setTitle("我的缓存", for: .normal)
        cacheButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cacheButton.addTarget(self, action: #selector(onCacheBtnClick), for: .touchUpInside)
        cacheButton.layer.cornerRadius = 10
        cacheButton.isHidden = true
        addSubview(cacheButton)
        
        let settingsButton = UIButton(type: .custom)
        settingsButton.frame = CGRect(x: paddingX, y: cacheButton.frame.maxY + paddingY, width: kScreenW - 2*paddingX, height: 50)
        settingsButton.backgroundColor = .lightGray
        settingsButton.setTitle("设置", for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        settingsButton.addTarget(self, action: #selector(onSettingsBtnClick), for: .touchUpInside)
        settingsButton.layer.cornerRadius = 10
        addSubview(settingsButton)
    }
    
    @objc func onCacheBtnClick() {
        delegate?.cacheButtonDidClick()
    }
    
    @objc func onSettingsBtnClick() {
        delegate?.settingsButtonDidClick()
    }
    
}
