//
//  NotificationCategory.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 10/02/25.
//

import Foundation

enum NotificationCategory: String, CaseIterable {
    case message = "message.badge.filled.fill"
    case email = "envelope.badge.fill"
    case phone = "phone.badge.fill"
    case social = "bubble.left.and.bubble.right.fill"
    case notification = "bell.badge.fill"
    case browser = "safari.fill"
    case calendar = "calendar.badge.exclamationmark"
}
