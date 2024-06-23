//
//  AppCommon.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit

// MARK: - Const

public let kScreen  = UIScreen.main.bounds
public let kScreenW = UIScreen.main.bounds.size.width
public let kScreenH = UIScreen.main.bounds.size.height

public let kMargin = kAdapt(10)
public let kLineMargin = kAdapt(1)

public let isIphoneX = { () -> Bool in
    var isX = false
    if #available(iOS 11.0, *) {
        let app = UIApplication.shared
        let window = app.delegate?.window ?? app.activeKeyWindow
        isX = (window?.safeAreaInsets.bottom ?? 0) > CGFloat(0.0)
    }
    return isX
}

public let kSafeAreaInset = { () -> UIEdgeInsets in
    var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    if #available(iOS 11.0, *) {
        let app = UIApplication.shared
        let window = app.delegate?.window ?? app.activeKeyWindow
        insets = window?.safeAreaInsets ?? insets
    }
    return insets
}

public let kSafeAreaTop = kSafeAreaInset().top == 0 ? 20 : kSafeAreaInset().top
public let kSafeAreaBottom = kSafeAreaInset().bottom
public let kStatusH = kSafeAreaTop
public let kNavigaH = 44 + kStatusH
public let kTabBarH = 49 + kSafeAreaBottom

// 6s's dimension
public func kAdapt(_ value: CGFloat) -> CGFloat
{
    return (kScreenW / 375) * value
}

public func kLoadImage(named: String) -> UIImage
{
    return UIImage(named: named) ?? UIImage()
}

public func showAlert(in controller: UIViewController,
                      title: String?,
                      message: String?,
                      style: UIAlertController.Style = .alert,
                      sureTitle: String? = nil,
                      cancelTitle: String? = nil,
                      warningTitle: String? = nil,
                      sureHandler: ((UIAlertAction) -> Void)? = nil,
                      cancelHandler: ((UIAlertAction) -> Void)? = nil,
                      warningHandler: ((UIAlertAction) -> Void)? = nil)
{
    let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
    
    if sureTitle != nil {
        let sureAction = UIAlertAction(title: sureTitle, style: .default) { action in
            sureHandler?(action)
        }
        alertController.addAction(sureAction)
    }
    
    if cancelTitle != nil {
        let cancelAction = UIAlertAction(title: cancelTitle!, style: .cancel) { action in
            cancelHandler?(action)
        }
        alertController.addAction(cancelAction)
    }
    
    if warningTitle != nil {
        let warningAction = UIAlertAction(title: sureTitle, style: .destructive) { action in
            warningHandler?(action)
        }
        alertController.addAction(warningAction)
    }
    
    if sureTitle == nil && cancelTitle == nil && warningTitle == nil {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alertController.dismiss(animated: true)
        }
    }
    
    controller.present(alertController, animated: true)
}

extension UIApplication {
    
    /// Get the active key window.
    public var activeKeyWindow: UIWindow? {
        var keyWindow: UIWindow?
        if #available(iOS 13.0, *) {
            keyWindow = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
        } else {
            keyWindow = UIApplication.shared.windows
                .filter({ $0.isKeyWindow }).first
        }
        return keyWindow
    }
    
}
