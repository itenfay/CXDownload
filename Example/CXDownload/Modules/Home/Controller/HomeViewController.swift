//
//  HomeViewController.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class HomeViewController: BaseViewController, HomeViewable {
    
    private var homeView: HomeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navTitle = "首页"
        presenter.loadData()
    }
    
    override func configure() {
        let configurator = HomeConfigurator()
        self.configurator = configurator
        configurator.configure(controller: self)
    }
    
    override func makeUI() {
        homeView = HomeView()
        homeView.setTableDelegate(presenter as? HomePresenter)
        homeView.frame = view.bounds
        view.addSubview(homeView)
    }
    
    func refreshView() {
        homeView.reload()
    }
    
    func reloadRows(atIndex index: Int) {
        homeView.reloadRows(atIndex: index)
    }
    
}
