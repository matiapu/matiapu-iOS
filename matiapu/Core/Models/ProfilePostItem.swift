//
//  ProfilePostItem.swift
//  matiapu
//

import Foundation

struct ProfilePostItem: Identifiable, Hashable {
    let id: String
    let imageName: String
}

#if DEBUG
enum ProfilePreviewData {
    static let posts: [ProfilePostItem] = (1...12).map { index in
        ProfilePostItem(id: "profile-post-\(index)", imageName: MockImages.postImage(at: index - 1))
    }
}
#endif
