//
//  MineViewController.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit

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
        view.addSubview(mineView)
        
        mineView.cacheButtonOnClick = { [weak self] sender in
            let pt = self?.presenter as? MinePresenter
            pt?.cacheButtonPressed()
        }
        mineView.settingsButtonOnClick = { [weak self] sender in
            let pt = self?.presenter as? MinePresenter
            pt?.settingsButtonPressed()
        }
    }
    
}
