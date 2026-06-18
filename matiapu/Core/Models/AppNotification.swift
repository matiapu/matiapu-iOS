//
//  AppNotification.swift
//  matiapu
//

import Foundation

struct AppNotification: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let publishedAt: Date
    let isRead: Bool
}
