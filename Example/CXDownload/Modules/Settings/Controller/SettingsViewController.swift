//
//  SettingsViewController.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController, SettingsViewable {
    
    private var settingsView: SettingsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navTitle = "设置"
    }
    
    override func configure() {
        let configurator = SettingsConfigurator()
        configurator.configure(controller: self)
        self.configurator = configurator
    }
    
    override func makeUI() {
        settingsView = SettingsView(frame: CGRect.init(x: 0,
                                                       y: kNavigaH,
                                                       width: view.bounds.width,
                                                       height: view.bounds.height - kNavigaH - kTabBarH))
        settingsView.delegate = presenter as? SettingsPresenter
        view.addSubview(settingsView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        settingsView.done()
    }
    
}
