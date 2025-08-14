//
//  CXInfinityPage.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 8/13/25.
//

import Combine
import Observation
import SwiftUI

// MARK: - CXInfinityPage

public struct CXInfinityPage<Page: View>: View {
    // MARK: Lifecycle

    public init(
        axis: Axis = .horizontal,
        currentPage: Binding<Int> = .constant(.zero),
        @ViewBuilder page: @escaping (Int) -> Page
    ) {
        _coordinator = State(initialValue: InfinityPageCoordinator(axis: axis))
        _currentPage = currentPage
        self.page = page
    }

    // MARK: Public

    public var body: some View {
        makePageContainer { geometry in
            ForEach(0 ..< InfinityPageCoordinator.maxPage) { index in
                page(coordinator.makeIndex(offset: index))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: CXInfinityPage.makeScrollOffset(
                                        frame: geometry.frame(in: .scrollView),
                                        axis: coordinator.axis
                                    )
                                )
                        }
                    }
                    .onPreferenceChange(ScrollOffsetKey.self) {
                        coordinator.offset.send($0)
                    }
            }
        }
        .onChange(of: coordinator.currentPage) { _, newValue in
            currentPage = newValue
        }
        .onChange(of: currentPage) { _, newValue in
            coordinator.scroll(to: newValue)
        }
    }

    // MARK: Internal

    @Binding var currentPage: Int

    // MARK: Private

    @State private var coordinator: InfinityPageCoordinator

    private let page: (Int) -> Page

    private static func makeScrollOffset(frame: CGRect, axis: Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            -frame.origin.x
        case .vertical:
            -frame.origin.y
        }
    }

    private func makePageContainer(@ViewBuilder container: @escaping (GeometryProxy) -> some View)
        -> some View {
        GeometryReader { geometry in
            switch coordinator.axis {
            case .horizontal:
                TabView(selection: $coordinator.index) {
                    container(geometry)
                        .contentShape(.rect)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .coordinateSpace(.scrollView(axis: .horizontal))

            case .vertical:
                TabView(selection: $coordinator.index) {
                    container(geometry)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .rotationEffect(.degrees(-InfinityPageCoordinator.rotationDegree))
                        .contentShape(Rectangle())
                }
                .frame(width: geometry.size.height, height: geometry.size.width)
                .rotationEffect(
                    .degrees(InfinityPageCoordinator.rotationDegree),
                    anchor: .topLeading
                )
                .offset(x: geometry.size.width)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .coordinateSpace(.scrollView(axis: .vertical))
            }
        }
    }
}

// MARK: - InfinityPageCoordinator

@Observable
final class InfinityPageCoordinator {
    // MARK: Lifecycle

    init(axis: Axis) {
        self.axis = axis
        offset = .init(.zero)

        detect()
    }

    // MARK: Internal

    // MARK: - Constants

    static let maxPage = 50
    static let rotationDegree: Double = 90

    let axis: Axis
    let offset: CurrentValueSubject<CGFloat, Never>

    // MARK: - Page indexes

    let pivot = maxPage / 2
    var index: Int = maxPage / 2
    var currentPage = 0

    func makeIndex(offset: Int) -> Int {
        currentPage + (offset - pivot)
    }

    func scroll(to index: Int) {
        guard index != currentPage else {
            return
        }
        withAnimation {
            self.index = pivot
            self.currentPage = index
        }
    }

    // MARK: Private

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
        currentPage += indexOffset
        index = pivot
    }
}

// MARK: - ScrollOffsetKey

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat {
        .zero
    }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
