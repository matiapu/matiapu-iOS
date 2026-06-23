//
//  ProfilePostItem.swift
//  matiapu
//

import Foundation

struct ProfilePostItem: Identifiable, Hashable {
    let id: String
    let imageName: String
    let imageURL: String?

    init(id: String, imageName: String, imageURL: String? = nil) {
        self.id = id
        self.imageName = imageName
        self.imageURL = imageURL
    }
}

#if DEBUG
enum ProfilePreviewData {
    static let posts: [ProfilePostItem] = (1...12).map { index in
        ProfilePostItem(id: "profile-post-\(index)", imageName: MockImages.postImage(at: index - 1))
    }
}
#endif
