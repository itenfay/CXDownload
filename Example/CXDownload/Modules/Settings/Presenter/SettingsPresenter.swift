//
//  SettingsPresenter.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CXDownload

protocol SettingsPresenterDelegate: AnyObject {
    func clearButtonDidClick()
    func warnToInputMaxConcurrentCount()
    func updateMaxConcurrentCount(_ count: Int)
    func allowsCellularAccess(_ isOn: Bool)
}

class SettingsPresenter: BasePresenter, SettingsPresenterDelegate {
    
    private unowned let view: SettingsViewable
    private let apiClient: ApiClient
    
    init(view: SettingsViewable, apiClient: ApiClient) {
        self.view = view
        self.apiClient = apiClient
    }
    
    func clearButtonDidClick() {
        guard let vc = view as? SettingsViewController else { return }
        showAlert(in: vc, title: "是否清空所有缓存？", message: nil, sureTitle: "确定", cancelTitle: "取消", sureHandler: { action in
            self.clearLocalCaches()
        }, cancelHandler: nil, warningHandler: nil)
    }
    
    func warnToInputMaxConcurrentCount() {
        guard let vc = view as? SettingsViewController else { return }
        showAlert(in: vc, title: "提示", message: "请输入数字1~5", sureTitle: "确定", cancelTitle: "取消", sureHandler: nil, cancelHandler: nil, warningHandler: nil)
    }
    
    func updateMaxConcurrentCount(_ count: Int) {
        // Save
        UserDefaults.standard.set(count, forKey: CXDownloadConfig.maxConcurrentCountKey)
        // Notify
        NotificationCenter.default.post(name: CXDownloadConfig.maxConcurrentCountChangeNotification, object: NSNumber(value: count))
    }
    
    func allowsCellularAccess(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: CXDownloadConfig.allowsCellularAccessKey)
        NotificationCenter.default.post(name: CXDownloadConfig.allowsCellularAccessChangeNotification, object: NSNumber(value: isOn))
    }
    
    func clearLocalCaches() {
        let allCaches = CXDownloadDatabaseManager.shared.getAllCacheData()
        for model in allCaches {
            guard let url = model.url else {
                continue
            }
            CXDownloadManager.shared.deleteTaskAndCache(url: url)
        }
    }
    
}
