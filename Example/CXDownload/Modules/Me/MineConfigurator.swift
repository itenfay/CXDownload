//
//  MineConfigurator.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class MineConfigurator: Configurator {
    
    typealias C = MineViewController
    
    func configure(controller: MineViewController) {
        let apiClient = DLApiClient(urlSession: DefaultURLSession())
        
        let presenter = MinePresenter(view: controller, apiClient: apiClient)
        controller.presenter = presenter
    }
    
}
