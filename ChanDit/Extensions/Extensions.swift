//
//  Extensions.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 18/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

extension UserDefaults {
    static var videoCache: UserDefaults {
        return UserDefaults(suiteName: "webm.chandit")!
    }
}

extension UIViewController {
    func showToast(message: String,
                   textColor: UIColor = UIColor.red,
                   backgroundColor: UIColor = UIColor.white,
                   duration: Double = 2.0,
                   heightModifier: Double = 0.9) {

        DispatchQueue.main.async {
            let label = UILabel(frame: CGRect(x: self.view.frame.origin.x,
                                              y: self.view.frame.height*0.9,
                                              width: self.view.frame.width, height: 30))
            label.backgroundColor = backgroundColor
            label.clipsToBounds = true
            label.textAlignment = .center
            label.text = message
            label.textColor = textColor
            label.numberOfLines = 0
            self.view.addSubview(label)
            UIView.animate(withDuration: duration, delay: 1.0, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }
}

extension UINavigationBar {
    func setTransparent() {
        self.isTranslucent = true
        self.shadowImage = UIImage()
        self.backgroundColor = .clear
        let colors = [UIColor.black, UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0)]
        self.applyNavigationGradient(colors: colors)
    }
}

extension UINavigationBar {
    /// Applies a background gradient with the given colors
    func applyNavigationGradient(colors: [UIColor]) {
        var frameAndStatusBar: CGRect = self.bounds
        frameAndStatusBar.size.height += UIApplication.shared.statusBarFrame.height
        frameAndStatusBar.size.height += 120 // add 20 to account for the status bar
        setBackgroundImage(UINavigationBar.gradient(size: frameAndStatusBar.size, colors: colors), for: .default)
    }

    /// Creates a gradient image with the given settings
    static func gradient(size: CGSize,
                         colors: [UIColor]) -> UIImage? {
        // Turn the colors into CGColors
        let cgcolors = colors.map { $0.cgColor }

        // Begin the graphics context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)

        // If no context was retrieved, then it failed
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // From now on, the context gets ended if any return happens
        defer { UIGraphicsEndImageContext() }

        // Create the Coregraphics gradient
        var locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: cgcolors as NSArray as CFArray,
                                        locations: &locations) else { return nil }

        // Draw the gradient
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0.0, y: 0.0),
                                   end: CGPoint(x: 0.0, y: size.height),
                                   options: [])

        // Generate the image (the defer takes care of closing the context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIViewController {
    func showAlertView(title: String, message: String, actions: [UIAlertAction]? = []) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            actions!.forEach {
                alert.addAction($0)
            }
            if actions!.isEmpty {
                let actionOk = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(actionOk)

            } else {
                alert.preferredAction = actions!.first!
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
}
