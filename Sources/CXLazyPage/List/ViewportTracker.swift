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

    init(
        context: ViewportTrackerContext,
        collectionView: UICollectionView,
        onViewportUpdate: @escaping (Viewport) -> Void
    ) {
        self.context = context
        self.collectionView = collectionView
        self.onViewportUpdate = onViewportUpdate

        detectArea = ViewportTracker.makeDetectArea(
            context: context,
            collectionView: collectionView
        )

        setupTracker()
    }

    // MARK: Internal

    func track(_ ignoreTracking: Bool = false) {
        if ignoreTracking {
            return
        }
        trackerSubject.send()
    }

    // MARK: Private

    private let context: ViewportTrackerContext

    private let detectArea: CGRect

    private let collectionView: UICollectionView

    private let trackerSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    private var onViewportUpdate: (Viewport) -> Void

    private var trackerOverlay: UIView = {
        let overlayView = TrackingOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        return overlayView
    }()

    private static func makeDetectArea(
        context: ViewportTrackerContext,
        collectionView: UICollectionView
    ) -> CGRect {
        CGRect(
            x: collectionView.frame.origin.x,
            y: collectionView.frame.origin.y + context.detectAreaOriginYOffset,
            width: collectionView.frame.width,
            height: collectionView.frame.height * context.detectAreaRatio
        )
    }

    private func setupTracker() {
        trackerSubject
            .throttle(
                for: context.detectFrequencyBuffer,
                scheduler: DispatchQueue.main,
                latest: true
            )
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
                guard let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame
                else {
                    return nil
                }
                let frameInSuperview = collectionView.convert(frame, to: collectionView.superview)
                return Viewport(rect: frameInSuperview, indexPath: indexPath)
            }
        return viewPorts.first(where: isViewportFulfilled)
    }

    private func isViewportFulfilled(_ viewPort: Viewport) -> Bool {
        let intersection = viewPort.rect.intersection(detectArea)
        return intersection.area >= (viewPort.rect.area * context.fulfillThreshold)
    }
}

extension CGRect {
    var area: CGFloat {
        width * height
    }
}

extension ViewportTracker {
    func attachTrackerOverlay() {
        guard context.showDetectArea,
              let superview = collectionView.superview,
              trackerOverlay.superview == nil else {
            return
        }
        superview.addSubview(trackerOverlay)
        NSLayoutConstraint.activate([
            trackerOverlay.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trackerOverlay.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            trackerOverlay.topAnchor.constraint(equalTo: superview.topAnchor),
            trackerOverlay.heightAnchor.constraint(
                equalTo: superview.heightAnchor,
                multiplier: context.detectAreaRatio
            )
        ])
    }

    func removeTrackerOverlay() {
        trackerOverlay.removeFromSuperview()
    }
}

extension ViewportTracker {
    class TrackingOverlayView: UIView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let hitView = super.hitTest(point, with: event)
            return hitView == self ? nil : hitView
        }
    }
}
