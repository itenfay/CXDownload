//
//  MinePresenter.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit
import CXDownload

protocol IMinePresenter: AnyObject {
    func cacheButtonPressed()
    func settingsButtonPressed()
}

class MinePresenter: BasePresenter, IMinePresenter {
    
    private unowned let view: MineViewable
    private let apiClient: ApiClient
    
    init(view: MineViewable, apiClient: ApiClient) {
        self.view = view
        self.apiClient = apiClient
    }
    
    func cacheButtonPressed() {
        gotoCacheScene()
    }
    
    func settingsButtonPressed() {
        gotoSettingsScene()
    }
    
    func gotoCacheScene() {
        //let downloadedDataArray = CXDownloadDatabaseManager.shared.getAllDownloadedData()
        //let unDownloadedDataArray = CXDownloadDatabaseManager.shared.getAllUnDownloadedData()
    }
    
    func gotoSettingsScene() {
        guard let mineVC = view as? MineViewController else {
            return
        }
        let settingsVC = SettingsViewController()
        settingsVC.hidesBottomBarWhenPushed = true
        mineVC.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
}
