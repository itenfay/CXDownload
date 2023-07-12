//
//  SettingsConfigurator.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SettingsConfigurator: Configurator {
    
    typealias C = SettingsViewController
    
    func configure(controller: SettingsViewController) {
        let apiClient = DLApiClient(urlSession: DefaultURLSession())
        
        let presenter = SettingsPresenter(view: controller, apiClient: apiClient)
        controller.presenter = presenter
    }
    
}
