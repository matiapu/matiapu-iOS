//
//  CreatePostUseCase.swift
//  matiapu
//

import Foundation
import UIKit

struct CreatePostUseCase: Sendable {
    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func execute(
        title: String,
        body: String,
        tag: MapFilter,
        image: UIImage,
        location: PostLocation
    ) async throws -> Post {
        try await postRepository.createPost(
            title: title,
            body: body,
            tag: tag,
            image: image,
            location: location
        )
    }
}

enum PostSubmissionErrorMapper {
    static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }

        return "投稿に失敗しました。通信環境を確認して再度お試しください。"
    }
}
