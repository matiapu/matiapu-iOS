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
    private(set) var isBodyExpanded = false
    private(set) var isCameraPresented = false
    private(set) var isCreatePostPresented = false
    private(set) var capturedImage: UIImage?
    private(set) var capturedLocation: PostLocation?
    private(set) var createPostViewModel: CreatePostViewModel?
    private(set) var isLoading = false

    var onPostCreated: (() async -> Void)?

    private var swipeQueue = PostSwipeQueue()
    private let postRepository: any PostRepository
    private let locationCaptureService: LocationCaptureService

    init(
        postRepository: any PostRepository,
        initialQueue: [Post]? = nil
    ) {
        self.postRepository = postRepository
        self.locationCaptureService = LocationCaptureService()
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

        isBodyExpanded = false
        if swipeQueue.advance(with: action) != nil {
            Task {
                try? await postRepository.recordSwipe(postId: current.id, action: action)
            }
        }
        post = swipeQueue.current
    }

    func toggleBodyExpanded() {
        isBodyExpanded.toggle()
    }

    func openCreatePost() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        locationCaptureService.prepareForCapture()
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
            locationCaptureService.stopCapture()

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
            isCreatePostPresented = true
        }
    }

    private func resolvedDeviceCoordinate(fallbackPhotoCoordinate: CLLocationCoordinate2D?) async -> CLLocationCoordinate2D? {
        if fallbackPhotoCoordinate != nil {
            return locationCaptureService.currentCoordinate
        }

        if let currentCoordinate = locationCaptureService.currentCoordinate {
            return currentCoordinate
        }

        return await locationCaptureService.waitForLocation()
    }

    func cancelCamera() {
        locationCaptureService.stopCapture()
        isCameraPresented = false
    }

    func dismissCreatePost() {
        isCreatePostPresented = false
        capturedImage = nil
        capturedLocation = nil
        createPostViewModel = nil
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
