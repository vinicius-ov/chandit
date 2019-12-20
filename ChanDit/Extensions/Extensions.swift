//
//  Extensions.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 18/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//  swiftlint:disable identifier_name

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
        let label = UILabel(frame: CGRect(x: view.frame.origin.x,
                                          y: view.frame.height*0.9,
                                          width: view.frame.width, height: 30))
        label.backgroundColor = backgroundColor
        label.clipsToBounds = true
        label.textAlignment = .center
        label.text = message
        label.textColor = textColor
        label.numberOfLines = 0
        view.addSubview(label)
        UIView.animate(withDuration: duration, delay: 1.0, animations: {
            label.alpha = 0
        }, completion: { _ in
            label.removeFromSuperview()
        })
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

extension String {
    func indicesOf(string: String) -> [Int] {
        // Converting to an array of utf8 characters makes indicing and comparing a lot easier
        let search = self.utf8.map { $0 }
        let word = string.utf8.map { $0 }

        var indices = [Int]()

        // m - the beginning of the current match in the search string
        // i - the position of the current character in the string we're trying to match
        var m = 0, i = 0
        while m + i < search.count {
            if word[i] == search[m+i] {
                if i == word.count - 1 {
                    indices.append(m)
                    m += i + 1
                    i = 0
                } else {
                    i += 1
                }
            } else {
                m += 1
                i = 0
            }
        }

        return indices
    }
}

extension String {
    func toPlainText(fontSize: CGFloat? = 17, postViewModel: PostViewModel? = nil) -> NSAttributedString {
        var attribText = NSMutableAttributedString(string: "")
        if let htmlData = self.data(using: .unicode) {
            do {
                attribText =
                    try NSMutableAttributedString(data: htmlData,
                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                           documentAttributes: nil)
                attribText.addAttributes([.foregroundColor: UIColor.white,
                                          .font: UIFont.systemFont(ofSize: fontSize!)],
                                         range: NSRange(location: 0, length: attribText.mutableString.length))
//                if let pvm = postViewModel {
//                    for index in 0..<pvm.lowerRangeGreenText.count {
//                    attribText.addAttributes([.foregroundColor: UIColor.green,
//                     .font: UIFont.systemFont(ofSize: fontSize!)],
//                                             range: NSRange(location: pvm.lowerRangeGreenText[index], length: pvm.upperRangeGreenText[index] - pvm.lowerRangeGreenText[index] - 1))
//                    }
//                }
            } catch let error as NSError {
                print("Couldn't parse \(self): \(error.localizedDescription)")
            }
        }
        return attribText
    }
}

extension UIView {
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
}
