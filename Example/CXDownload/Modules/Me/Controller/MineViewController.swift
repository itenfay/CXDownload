//
//  MineViewController.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CXDownload

class MineViewController: BaseViewController, MineViewable {
    
    private var mineView: MineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navTitle = "我的"
    }
    
    override func configure() {
        let configurator = MineConfigurator()
        configurator.configure(controller: self)
        self.configurator = configurator
    }
    
    override func makeUI() {
        mineView = MineView(frame: CGRect.init(x: 0,
                                               y: kNavigaH,
                                               width: view.bounds.width,
                                               height: view.bounds.height - kNavigaH - kTabBarH))
        mineView.delegate = presenter as? MinePresenter
        view.addSubview(mineView)
    }
    
    func gotoCacheView() {
        //let downloadedDataArray = CXDownloadDatabaseManager.shared.getAllDownloadedData()
        //let unDownloadedDataArray = CXDownloadDatabaseManager.shared.getAllUnDownloadedData()
    }
    
    func gotoSettingsView() {
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
