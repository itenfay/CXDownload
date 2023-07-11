//
//  BaseViewController.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

protocol Navigable {
    var navigationBar: UINavigationBar? { get }
    var navTitle: String? { get set }
    var navTitleColor: UIColor { get set }
    var navTitleFont: UIFont { get set }
    var navTitleWidth: CGFloat { get set }
    var navTitleAlignment: NSTextAlignment { get set }
    func configNavigationBarAppearance()
    func configNavigaitonBar(backgroundImage: UIImage, titleTextAttributes: [NSAttributedString.Key : Any]?)
    func configNavigaitonBar(backgroundImage: UIImage, shadowImage: UIImage, titleTextAttributes: [NSAttributedString.Key : Any]?)
    func makeNavigationBarHidden(_ hidden: Bool)
    func setNavigationTitle(_ title: String)
    func setNavigationTitleView(_ view: UIView)
    func addLeftNavigationBarItem(_ view: UIView)
    func addLeftNavigationBarButtons(_ buttons: UIButton...)
    func addRightNavigationBarItem(_ view: UIView)
    func addRightNavigationBarButtons(_ buttons: UIButton...)
}

class BaseViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    /// ios(6.0, 16.0)
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    var navigationBar: UINavigationBar? { navigationController?.navigationBar }
    
    var navTitle: String? {
        didSet {
            navTitleView.text = navTitle
        }
    }
    
    var navTitleColor: UIColor = .black {
        didSet {
            navTitleView.textColor = navTitleColor
        }
    }
    
    var navTitleFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .bold) {
        didSet {
            navTitleView.font = navTitleFont
        }
    }
    
    var navTitleWidth: CGFloat = 240 {
        didSet {
            var frame = navTitleView.frame
            frame.size.width = navTitleWidth
            navTitleView.frame = frame
        }
    }
    
    var navTitleAlignment: NSTextAlignment = .center {
        didSet {
            navTitleView.textAlignment = navTitleAlignment
        }
    }
    
    private lazy var navTitleView: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: navTitleWidth, height: 44))
        label.textColor = navTitleColor
        label.font = navTitleFont
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }()
    
    lazy var leftFixedSpaceItem: UIBarButtonItem = {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 10, height: 44))
        let item = UIBarButtonItem(customView: view)
        return item
    }()
    
    lazy var rightFixedSpaceItem: UIBarButtonItem = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: -10, height: 44))
        let item = UIBarButtonItem.init(customView: view)
        return item
    }()
    
    func configNavigationBarAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.white
            //appearance.backgroundEffect = nil
            appearance.shadowColor = UIColor.clear
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: .bold)]
            navigationBar?.standardAppearance = appearance
            navigationBar?.scrollEdgeAppearance = appearance
        }
    }
    
    func configNavigaitonBar(backgroundImage: UIImage, titleTextAttributes: [NSAttributedString.Key : Any]?) {
        configNavigaitonBar(backgroundImage: backgroundImage, shadowImage: UIImage(), titleTextAttributes: titleTextAttributes)
    }
    
    func configNavigaitonBar(backgroundImage: UIImage, shadowImage: UIImage, titleTextAttributes: [NSAttributedString.Key : Any]?) {
        navigationBar?.setBackgroundImage(backgroundImage, for: .default)
        navigationBar?.shadowImage = shadowImage
        navigationBar?.titleTextAttributes = titleTextAttributes
    }
    
    func makeNavigationBarHidden(_ hidden: Bool) {
        navigationBar?.isHidden = hidden
    }
    
    func setNavigationTitle(_ title: String) {
        navigationItem.title = title
    }
    
    func setNavigationTitleView(_ view: UIView) {
        navigationItem.titleView = view
    }
    
    func addLeftNavigationBarItem(_ view: UIView) {
        var items = navigationItem.leftBarButtonItems
        let item = UIBarButtonItem(customView: view)
        if items == nil {
            items = [leftFixedSpaceItem, item]
        } else {
            items?.append(item)
        }
    }
    
    func addLeftNavigationBarButtons(_ buttons: UIButton...) {
        buttons.forEach { btn in
            self.addLeftNavigationBarItem(btn)
        }
    }
    
    func addRightNavigationBarItem(_ view: UIView) {
        var items = navigationItem.leftBarButtonItems
        let item = UIBarButtonItem(customView: view)
        if items == nil {
            items = [rightFixedSpaceItem, item]
        } else {
            items?.append(item)
        }
    }
    
    func addRightNavigationBarButtons(_ buttons: UIButton...) {
        buttons.forEach { btn in
            self.addRightNavigationBarItem(btn)
        }
    }
    
    var configurator: (any Configurator)!
    var presenter: Presenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackgroundColor()
        updateToSupportedInterfaceOrientations()
        updateEdgesForExtendedLayout(.all)
        setNavigationTitleView(navTitleView)
        configure()
        makeUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateToSupportedInterfaceOrientations()
    }
    
    func setBackgroundColor() {
        view.backgroundColor = .white
    }
    
    func updateEdgesForExtendedLayout(_ edge: UIRectEdge) {
        edgesForExtendedLayout = edge
    }
    
    func includesOpaqueBarsForExtendedLayout(_ included: Bool) {
        extendedLayoutIncludesOpaqueBars = included
    }
    
    func updateToSupportedInterfaceOrientations() {
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            Self.attemptRotationToDeviceOrientation()
        }
    }
    
    func configure() {}
    
    func makeUI() {}
    
}
