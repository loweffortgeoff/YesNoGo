//
//  YesNoGoWidgetBundle.swift
//  YesNoGoWidget
//
//  Created by Geoffrey Silva on 12/20/25.
//

import WidgetKit
import SwiftUI

@main
struct YesNoGoWidgetBundle: WidgetBundle {
    var body: some Widget {
        YesNoGoWidget()
        YesNoGoWidgetControl()
        YesNoGoWidgetLiveActivity()
    }
}
