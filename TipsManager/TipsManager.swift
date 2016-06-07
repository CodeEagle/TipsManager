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

	private static var _shared: TipsManager? = nil
	public var language = "zh-Hans"
	public static var shared: TipsManager {
		if _shared == nil {
			_shared = TipsManager()
		}
		return _shared!
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	private init() {
		let center = NSNotificationCenter.defaultCenter()
		center.addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: nil) { [weak self](_) in
			guard let sself = self else { return }
			if !sself.isShowing && sself.tipsQueue.count == 0 {
				TipsManager._shared = nil
			}
		}
	}
	/// 提示队列
	private var tipsQueue: [(tip: String, image: String, y: Float)]! = {
		let q = [(tip: String, image: String, y: Float)]()
		return q
	}()

	/// 是否正在展示提示语
	private var isShowing = false {
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

	public class func hideHUDFor(view: UIView, animated: Bool = true) {
		MBProgressHUD.hideHUDForView(view, animated: animated)
	}
	// MARK: 弹出提示语

	public class func showBlockTips(tips: String, _ imageName: String = "") -> MBProgressHUD? {
		return shared.showBlockTips(tips, imageName)
	}

	public func showBlockTips(tips: String, _ imageName: String = "") -> MBProgressHUD? {
		return blockShow(tips, imageName)
	}

	private func blockShow(tips: String, _ imageName: String = "") -> MBProgressHUD? {
		if let win = UIApplication.sharedApplication().keyWindow {

			func show() -> MBProgressHUD {
				let hud = MBProgressHUD.showHUDAddedTo(win, animated: true)
				hud.mode = MBProgressHUDMode.Text
				hud.labelText = tips.tk_i18n
				if imageName != "" {
					hud.customView = UIImageView(image: UIImage(named: imageName))
					hud.mode = MBProgressHUDMode.CustomView
				}
				hud.show(true)
				return hud
			}

			if NSThread.isMainThread() {
				return show()
			} else {
				var hud: MBProgressHUD!
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					hud = show()
				})
				return hud
			}
		}
		return nil
	}

	// MARK: 弹出提示语

	public class func showTips(tips: String, _ imageName: String = "") {
		shared.showTips(tips, imageName)
	}

	public func showTips(tips: String, _ imageName: String = "") {

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

	public class func showErrorTips(tips: String) {
		shared.showErrorTips(tips)
	}

	public func showErrorTips(tips: String) {
		let type = PromotType.Error
		showTipsWith(tips, type)
	}

	public class func showSuccessTips(tips: String = "success") {
		shared.showSuccessTips(tips)
	}

	public func showSuccessTips(tips: String = "success") {
		let type = PromotType.Success
		showTipsWith(tips, type)
	}

	public class func showWarningTips(tips: String) {
		shared.showWarningTips(tips)
	}

	public func showWarningTips(tips: String) {
		let type = PromotType.Warning
		showTipsWith(tips, type)
	}

	public class func showBottomTipsWith(tips: String, _ type: PromotType = .None) {
		shared.showBottomTipsWith(tips, type)
	}

	public func showBottomTipsWith(tips: String, _ type: PromotType = .None) {

		let mainScreenHeight = UIScreen.mainScreen().bounds.height
		if isShowing {
			addTipsToQueue((tips, type.rawValue, Float(mainScreenHeight / 2)))
			return
		}
		isShowing = true
		if tipsQueue.count == 0 {
			realShow(tips, type.rawValue, Float(mainScreenHeight / 2))
		}
	}

	private func showTipsWith(tips: String, _ type: PromotType) {

		if isShowing {
			addTipsToQueue((tips, type.rawValue, 0))
			return
		}
		isShowing = true
		if tipsQueue.count == 0 {
			realShow(tips, type.rawValue)
		}
	}

	private func realShow(tips: String, _ imageName: String = "", _ offsetY: Float = 0) {
		guard let win = UIApplication.sharedApplication().keyWindow else { return }
		func show() {
			MBProgressHUD.hideAllHUDsForView(win, animated: true)
			let hud: MBProgressHUD! = MBProgressHUD.showHUDAddedTo(win, animated: true)
			hud.mode = MBProgressHUDMode.Text
			hud.detailsLabelText = tips.tk_i18n
			hud.yOffset = offsetY == 0 ? 0 : (offsetY - 40)
			if imageName != "" {
				hud.customView = UIImageView(image: UIImage(named: imageName))
				hud.mode = MBProgressHUDMode.CustomView
			}
			hud.userInteractionEnabled = false
			hud.show(true)
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(durationOfText(tips) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self]() -> Void in
				hud?.hide(true)
				self?.isShowing = false
			}
		}

		if NSThread.isMainThread() {
			show()
		} else {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				show()
			})
		}
	}

	// MARK: 计算文本显示时间 有待优化
	private func durationOfText(text: String) -> NSTimeInterval {
		let readingLetterPerSecond: NSTimeInterval = 15
		var duration = NSTimeInterval(text.characters.count) / readingLetterPerSecond
		let minimum: NSTimeInterval = 0.35
		if duration < minimum {
			duration = minimum
		}
		return duration
	}

	private func durationOfLoadingText(text: String) -> NSTimeInterval {
		return 0.35
	}

	private func addTipsToQueue(item: (tip: String, image: String, y: Float)) {

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
		if let path = NSBundle.mainBundle().pathForResource(TipsManager.shared.language, ofType: "lproj") {
			let bundle = NSBundle(path: path)
			if let str = bundle?.localizedStringForKey(self, value: nil, table: nil) {
				return str
			}
		} else if let path = NSBundle.mainBundle().pathForResource("zh-Hans", ofType: "lproj") {
			let bundle = NSBundle(path: path)
			if let str = bundle?.localizedStringForKey(self, value: nil, table: nil) {
				return str
			}
		}
		return self
	}
}