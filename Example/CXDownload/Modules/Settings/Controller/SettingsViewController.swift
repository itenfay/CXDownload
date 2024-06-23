//
//  SettingsViewController.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
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
    
    private func getSettingsPresenter() -> SettingsPresenter? {
        return presenter as? SettingsPresenter
    }
    
    override func makeUI() {
        settingsView = SettingsView(frame: CGRect.init(x: 0,
                                                       y: kNavigaH,
                                                       width: view.bounds.width,
                                                       height: view.bounds.height - kNavigaH - kTabBarH))
        view.addSubview(settingsView)
        
        settingsView.maxConcurrentCountWarningAction = { [weak self] in
            self?.getSettingsPresenter()?.warnToInputMaxConcurrentCount()
        }
        settingsView.maxConcurrentCountUpdatingAction = { [weak self] count in
            self?.getSettingsPresenter()?.updateMaxConcurrentCount(count)
        }
        settingsView.cellularAccessAllowingAction = { [weak self] isOn in
            self?.getSettingsPresenter()?.allowsCellularAccess(isOn)
        }
        settingsView.clearButtonAction = { [weak self] in
            self?.getSettingsPresenter()?.clearButtonPressed()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        settingsView.done()
    }
    
}
