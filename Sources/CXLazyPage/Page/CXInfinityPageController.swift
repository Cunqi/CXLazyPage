//
//  CXInfinityPageController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 8/13/25.
//

import Combine
import Observation
import SwiftUI

// MARK: - CXInfinityPageController

@Observable
public class CXInfinityPageController {
    // MARK: Lifecycle

    public init(axis: Axis) {
        self.axis = axis

        detect()
    }

    // MARK: Public

    /// Use to control the finalized page index, it will be updated after offset changes
    public private(set) var currentPage = 0

    public func scroll(to index: Int) {
        guard index != currentPage else {
            return
        }

        let isForward = index > currentPage
        let delta = isForward ? 1 : -1
        let startIndex = pivot + delta
        internalIndex = index - delta
        withAnimation {
            self.index = startIndex
        }
    }

    // MARK: Internal

    // MARK: - Constants

    static let maxPage = 50

    let axis: Axis
    let offset = CurrentValueSubject<CGFloat, Never>(.zero)

    /// Use to control the tabView position, it will be used to control page rendering without
    /// animation.
    var index: Int = maxPage / 2

    func makeIndex(offset: Int) -> Int {
        internalIndex + (offset - pivot)
    }

    // MARK: Private

    private let pivot = maxPage / 2

    /// Use to control the currentPage, this represents a zero-based index
    private var internalIndex = 0

    private var cancelable = Set<AnyCancellable>()

    private func detect() {
        offset
            .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                self?.detectOffsetChange()
            }
            .store(in: &cancelable)
    }

    private func detectOffsetChange() {
        let indexOffset = index - pivot
        internalIndex += indexOffset
        currentPage = internalIndex
        index = pivot
    }
}
