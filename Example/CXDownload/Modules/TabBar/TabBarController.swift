//
//  TabBarController.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/10.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit
import CXDownload

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        monitorCellularAccessAvailable()
    }
    
    func setup() {
        let normalTextAttr: [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: 13), .foregroundColor : UIColor.gray]
        let selectedTextAttr : [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: 13), .foregroundColor : UIColor.blue]
        
        let homeController = HomeViewController()
        let homeItem = UITabBarItem(title: "", image: UIImage(named: "tabbar_home_nor"), selectedImage: UIImage(named: "tabbar_home_sel"))
        homeItem.setTitleTextAttributes(normalTextAttr, for: .normal)
        homeItem.setTitleTextAttributes(selectedTextAttr, for: .selected)
        homeController.tabBarItem = homeItem
        let homeNavController = UINavigationController(rootViewController: homeController)
        
        let mineController = MineViewController()
        let mineItem = UITabBarItem(title: "", image: UIImage(named: "tabbar_me_nor"), selectedImage: UIImage(named: "tabbar_me_sel"))
        homeItem.setTitleTextAttributes(normalTextAttr, for: .normal)
        homeItem.setTitleTextAttributes(selectedTextAttr, for: .selected)
        mineController.tabBarItem = mineItem
        let mineNavController = UINavigationController(rootViewController: mineController)
        
        viewControllers = [homeNavController, mineNavController]
        selectedIndex = 0
        
        let bgColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = bgColor
            //appearance.backgroundEffect = nil
            //appearance.shadowColor = nil
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        } else {
            tabBar.backgroundColor = bgColor
            tabBar.shadowImage = nil
            tabBar.tintColor = UIColor.black
            tabBar.barTintColor = UIColor.white
        }
    }
    
}

extension TabBarController {
    
    func monitorCellularAccessAvailable() {
        CXDownloadManager.shared.displayPromptThatCellularAccessNotAllowed {
            self.showPrompt()
        }
    }
    
    func showPrompt() {
        showAlert(in: self, title: "提示", message: "当前为蜂窝网络，已停止下载任务，可在设置中开启", sureTitle: "确定", sureHandler: { action in
            print("ActionTitle=\(String(describing: action.title))")
        })
    }
    
}
