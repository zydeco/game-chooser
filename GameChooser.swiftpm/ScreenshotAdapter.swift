//
//  ScreenshotAdapter.swift
//  GameChooser
//
//  Created by Jesús A. Álvarez on 2024-02-18.
//

import SwiftUI
import UIKit

class ScreenshotAdapter: NSObject, UIScreenshotServiceDelegate {
    static var shared = ScreenshotAdapter()
    var generator: ((_ completionHandler: @escaping (Data?, Int, CGRect) -> Void) -> Void)?

    func screenshotService(_ screenshotService: UIScreenshotService, generatePDFRepresentationWithCompletion completionHandler: @escaping (Data?, Int, CGRect) -> Void) {
        if let generator {
            generator(completionHandler)
        }
    }
}

