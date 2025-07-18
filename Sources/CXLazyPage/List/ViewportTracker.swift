//
//  ViewportTracker.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/17/25.
//

import Combine
import UIKit

// MARK: - ViewportTracker

@MainActor
class ViewportTracker {

    // MARK: Lifecycle

    init(collectionView: UICollectionView, onViewportUpdate: @escaping (Viewport) -> Void) {
        self.collectionView = collectionView
        trackableArea = collectionView.frame.heightScaled(by: ViewportTracker.heightScaledRatio)
        self.onViewportUpdate = onViewportUpdate

        setupTracker()
    }

    // MARK: Internal

    func track() {
        trackerSubject.send()
    }

    // MARK: Private

    private static let heightScaledRatio: CGFloat = 2.0 / 3.0
    private static let validViewPortRatio: CGFloat = 0.8
    private static let throttleBuffer = DispatchQueue.SchedulerTimeType.Stride.milliseconds(100)

    private let trackableArea: CGRect

    private let collectionView: UICollectionView

    private let trackerSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    private var onViewportUpdate: (Viewport) -> Void

    private func setupTracker() {
        trackerSubject
            .throttle(for: ViewportTracker.throttleBuffer, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.trackViewPortUpdate()
            }
            .store(in: &cancellables)
    }

    private func trackViewPortUpdate() {
        if let validViewPort = fetchValidViewPort() {
            onViewportUpdate(validViewPort)
        }
    }

    private func fetchValidViewPort() -> Viewport? {
        let viewPorts = collectionView.indexPathsForVisibleItems
            .compactMap { indexPath -> Viewport? in
                guard let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
                    return nil
                }
                let frameInSuperview = collectionView.convert(frame, to: collectionView.superview)
                return Viewport(rect: frameInSuperview, indexPath: indexPath)
            }
        return viewPorts.first(where: isValidViewPort)
    }

    private func isValidViewPort(viewPort: Viewport) -> Bool {
        let intersection = viewPort.rect.intersection(trackableArea)
        return intersection.area >= viewPort.rect.area * ViewportTracker.validViewPortRatio
    }
}

extension CGRect {
    var area: CGFloat {
        width * height
    }

    func heightScaled(by ratio: CGFloat) -> CGRect {
        CGRect(x: origin.x, y: origin.y, width: width, height: height * ratio)
    }
}
