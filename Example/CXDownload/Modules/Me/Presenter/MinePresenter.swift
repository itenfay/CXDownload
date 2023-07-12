//
//  MinePresenter.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

protocol MinePresenterDelegate: AnyObject {
    func cacheButtonDidClick()
    func settingsButtonDidClick()
}

class MinePresenter: BasePresenter, MinePresenterDelegate {
    
    private unowned let view: MineViewable
    private let apiClient: ApiClient
    
    init(view: MineViewable, apiClient: ApiClient) {
        self.view = view
        self.apiClient = apiClient
    }
    
    func cacheButtonDidClick() {
        view.gotoCacheView()
    }
    
    func settingsButtonDidClick() {
        view.gotoSettingsView()
    }
    
}
