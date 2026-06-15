//
//  PostViewModel.swift
//  matiapu
//

import CoreLocation
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class PostViewModel {
    private(set) var post: Post?
    var detailPost: Post?
    private(set) var isCameraPresented = false
    private(set) var capturedImage: UIImage?
    private(set) var capturedLocation: PostLocation?
    private(set) var createPostViewModel: CreatePostViewModel?
    private(set) var isLoading = false

    var onPostCreated: (() async -> Void)?

    private var swipeQueue = PostSwipeQueue()
    private let postRepository: any PostRepository
    private var locationCaptureService: LocationCaptureService?

    init(postRepository: any PostRepository, initialQueue: [Post]? = nil) {
        self.postRepository = postRepository
        if let initialQueue {
            swipeQueue = PostSwipeQueue(candidates: initialQueue)
            post = swipeQueue.current
        }
    }

    func loadPosts() async {
        guard swipeQueue.isEmpty, post == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let candidates = (try? await postRepository.fetchFeedPosts()) ?? []
        swipeQueue = PostSwipeQueue(candidates: candidates)
        post = swipeQueue.current
    }

    func handleSwipe(_ action: PostSwipeAction) {
        guard let current = post else { return }

        detailPost = nil
        if swipeQueue.advance(with: action) != nil {
            Task {
                try? await postRepository.recordSwipe(postId: current.id, action: action)
            }
        }
        post = swipeQueue.current
    }

    func openDetail() {
        detailPost = post
    }

    func openCreatePost() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        locationService.prepareForCapture()
        isCameraPresented = true
    }

    func handleCapturedImage(_ image: UIImage, coordinate: CLLocationCoordinate2D?) {
        isCameraPresented = false

        Task {
            let deviceCoordinate = await resolvedDeviceCoordinate(fallbackPhotoCoordinate: coordinate)
            capturedImage = image
            capturedLocation = PostLocationResolver.resolve(
                photoCoordinate: coordinate,
                deviceCoordinate: deviceCoordinate
            )
            locationService.stopCapture()

            createPostViewModel = CreatePostViewModel(
                capturedImage: image,
                capturedLocation: capturedLocation,
                postRepository: postRepository,
                onComplete: { [weak self] in
                    guard let self else { return }
                    self.dismissCreatePost()
                    Task {
                        await self.onPostCreated?()
                    }
                }
            )
        }
    }

    func cancelCamera() {
        locationService.stopCapture()
        isCameraPresented = false
    }

    func dismissCreatePost() {
        capturedImage = nil
        capturedLocation = nil
        createPostViewModel = nil
    }

    private var locationService: LocationCaptureService {
        if locationCaptureService == nil {
            locationCaptureService = LocationCaptureService()
        }
        return locationCaptureService!
    }

    private func resolvedDeviceCoordinate(fallbackPhotoCoordinate: CLLocationCoordinate2D?) async -> CLLocationCoordinate2D? {
        if fallbackPhotoCoordinate != nil {
            return locationService.currentCoordinate
        }

        if let currentCoordinate = locationService.currentCoordinate {
            return currentCoordinate
        }

        return await locationService.waitForLocation()
    }
}

#if DEBUG
extension PostViewModel {
    static var preview: PostViewModel {
        PostViewModel(
            postRepository: MockPostRepository(),
            initialQueue: PostPreviewData.feedCandidates
        )
    }
}
#endif
