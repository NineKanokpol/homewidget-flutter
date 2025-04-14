//
//  LiveActivityWidgetBundle.swift
//  LiveActivityWidget
//
//  Created by Kanokpol Tipkan on 14/4/2568 BE.
//

import WidgetKit
import SwiftUI

@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
        LiveActivityWidgetLiveActivity()
    }
}
