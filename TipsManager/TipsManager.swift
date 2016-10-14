//
//  TipsManager.swift
//  LuooFM
//
//  Created by LawLincoln on 15/9/7.
//  Copyright © 2015年 LawLincoln. All rights reserved.
//

import UIKit
import MBProgressHUD

public enum PromotType: String {
	case Success = "prompt_complete"
	case Error = "prompt_error"
	case Warning = "prompt_warning"
	case None = ""
}

final public class TipsManager {

	fileprivate static var _shared: TipsManager? = nil
	public var language = "zh-Hans"
	public static var shared: TipsManager {
		if _shared == nil {
			_shared = TipsManager()
		}
		return _shared!
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	fileprivate init() {
		let center = NotificationCenter.default
		center.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil) { [weak self](_) in
			guard let sself = self else { return }
			if !sself.isShowing && sself.tipsQueue.count == 0 {
				TipsManager._shared = nil
			}
		}
	}
	/// 提示队列
	fileprivate var tipsQueue: [(tip: String, image: String, y: Float)]! = {
		let q = [(tip: String, image: String, y: Float)]()
		return q
	}()

	/// 是否正在展示提示语
	fileprivate var isShowing = false {
		didSet {
			if !isShowing {
				if let (tips, img, yoffset) = tipsQueue.first {
					print(tipsQueue.first)
					tipsQueue.removeFirst()
					realShow(tips, img, yoffset)
				}
			}
		}
	}

	public class func hideHUDFor(_ view: UIView, animated: Bool = true) {
		MBProgressHUD.hide(for: view, animated: animated)
	}
	// MARK: 弹出提示语

	public class func showBlockTips(_ tips: String, _ imageName: String = "") -> MBProgressHUD? {
		return shared.showBlockTips(tips, imageName)
	}

	public func showBlockTips(_ tips: String, _ imageName: String = "") -> MBProgressHUD? {
		return blockShow(tips, imageName)
	}

	fileprivate func blockShow(_ tips: String, _ imageName: String = "") -> MBProgressHUD? {
		if let win = UIApplication.shared.keyWindow {

			func show() -> MBProgressHUD {
                var hud: MBProgressHUD! = MBProgressHUD.showAdded(to: win, animated: true)
                if hud == nil {
                    hud = MBProgressHUD()
                    win.addSubview(hud)
                }
				hud.mode = MBProgressHUDMode.text
				hud.labelText = tips.tk_i18n
				if imageName != "" {
					hud.customView = UIImageView(image: UIImage(named: imageName))
					hud.mode = MBProgressHUDMode.customView
				}
				hud.show(true)
				return hud
			}

			if Thread.isMainThread {
				return show()
			} else {
				var hud: MBProgressHUD!
				DispatchQueue.main.async(execute: { () -> Void in
					hud = show()
				})
				return hud
			}
		}
		return nil
	}

	// MARK: 弹出提示语

	public class func showTips(_ tips: String, _ imageName: String = "") {
		shared.showTips(tips, imageName)
	}

	public func showTips(_ tips: String, _ imageName: String = "") {

		if isShowing {
			tipsQueue.append((tips, imageName, 0))
			return
		}
		isShowing = true
		if tipsQueue.count == 0 {
			realShow(tips, imageName)
		} else {
			tipsQueue.append((tips, imageName, 0))
		}
	}

	public class func showErrorTips(_ tips: String) {
		shared.showErrorTips(tips)
	}

	public func showErrorTips(_ tips: String) {
		let type = PromotType.Error
		showTipsWith(tips, type)
	}

	public class func showSuccessTips(_ tips: String = "success") {
		shared.showSuccessTips(tips)
	}

	public func showSuccessTips(_ tips: String = "success") {
		let type = PromotType.Success
		showTipsWith(tips, type)
	}

	public class func showWarningTips(_ tips: String) {
		shared.showWarningTips(tips)
	}

	public func showWarningTips(_ tips: String) {
		let type = PromotType.Warning
		showTipsWith(tips, type)
	}

	public class func showBottomTipsWith(_ tips: String, _ type: PromotType = .None) {
		shared.showBottomTipsWith(tips, type)
	}

	public func showBottomTipsWith(_ tips: String, _ type: PromotType = .None) {

		let mainScreenHeight = UIScreen.main.bounds.height
		if isShowing {
			addTipsToQueue((tips, type.rawValue, Float(mainScreenHeight / 2)))
			return
		}
		isShowing = true
		if tipsQueue.count == 0 {
			realShow(tips, type.rawValue, Float(mainScreenHeight / 2))
		}
	}

	fileprivate func showTipsWith(_ tips: String, _ type: PromotType) {

		if isShowing {
			addTipsToQueue((tips, type.rawValue, 0))
			return
		}
		isShowing = true
		if tipsQueue.count == 0 {
			realShow(tips, type.rawValue)
		}
	}

	fileprivate func realShow(_ tips: String, _ imageName: String = "", _ offsetY: Float = 0) {
		guard let win = UIApplication.shared.keyWindow else { return }
		func show() {
			MBProgressHUD.hideAllHUDs(for: win, animated: true)
			var hud: MBProgressHUD! = MBProgressHUD.showAdded(to: win, animated: true)
            if hud == nil {
                hud = MBProgressHUD()
                win.addSubview(hud)
            }
			hud.mode = MBProgressHUDMode.text
			hud.detailsLabelText = tips.tk_i18n
			hud.yOffset = offsetY == 0 ? 0 : (offsetY - 40)
			if imageName != "" {
				hud.customView = UIImageView(image: UIImage(named: imageName))
				hud.mode = MBProgressHUDMode.customView
			}
			hud.isUserInteractionEnabled = false
			hud.show(true)
			DispatchQueue.main.asyncAfter(deadline: .now() + durationOfText(tips)) { [weak self]() -> Void in
				hud?.hide(true)
				self?.isShowing = false
			}
		}

		if Thread.isMainThread {
			show()
		} else {
			DispatchQueue.main.async(execute: { () -> Void in
				show()
			})
		}
	}

	// MARK: 计算文本显示时间 有待优化
	fileprivate func durationOfText(_ text: String) -> TimeInterval {
		let readingLetterPerSecond: TimeInterval = 15
		var duration = TimeInterval(text.characters.count) / readingLetterPerSecond
		let minimum: TimeInterval = 0.35
		if duration < minimum {
			duration = minimum
		}
		return duration
	}

	fileprivate func durationOfLoadingText(_ text: String) -> TimeInterval {
		return 0.35
	}

	fileprivate func addTipsToQueue(_ item: (tip: String, image: String, y: Float)) {

		if tipsQueue.count == 0 {
			tipsQueue.append(item)
			return
		}
		for val in tipsQueue {
			if val.tip == item.tip && val.image == item.image && val.y == item.y {
				return
			}
			tipsQueue.append(item)
		}
	}
}

private extension String {

	var tk_i18n: String {
		if let path = Bundle.main.path(forResource: TipsManager.shared.language, ofType: "lproj") {
			let bundle = Bundle(path: path)
			if let str = bundle?.localizedString(forKey: self, value: nil, table: nil) {
				return str
			}
		} else if let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj") {
			let bundle = Bundle(path: path)
			if let str = bundle?.localizedString(forKey: self, value: nil, table: nil) {
				return str
			}
		}
		return self
	}
}
