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
        axis: Axis,
        currentPage: Binding<Int> = .constant(0),
        scrollEnabled: Binding<Bool> = .constant(true),
        pageWillChange: @escaping PageWillChange = { },
        @ViewBuilder page: @escaping PageContent
    ) {
        _controller = .init(initialValue: CXInfinityPageController(axis: axis))
        _currentPage = currentPage
        _scrollEnabled = scrollEnabled
        self.pageWillChange = pageWillChange
        self.page = page
    }

    // MARK: Public

    public typealias PageWillChange = () -> Void
    public typealias PageContent = (Int) -> Page

    public var body: some View {
        makePageContainer { geometry in
            ForEach(0 ..< CXInfinityPageController.maxPage) { index in
                page(controller.makeIndex(offset: index))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: ScrollOffset(index: index, offset: CXInfinityPage.makeScrollOffset(
                                        frame: geometry.frame(in: .scrollView),
                                        axis: controller.axis
                                    ))
                                )
                        }
                    }
                    .onPreferenceChange(ScrollOffsetKey.self) { offset in
                        guard offset.index == controller.index else {
                            return
                        }
                        if offset.offset < 0, abs(offset.offset) > CXInfinityPage.threshold {
                            pageWillChange()
                        }
                        controller.offset.send(offset.offset)
                    }
            }
        }
        .onChange(of: controller.currentPage) { _, newValue in
            currentPage = newValue
        }
        .onChange(of: currentPage) { _, newValue in
            controller.scroll(to: newValue)
        }
    }

    // MARK: Internal

    static var threshold: CGFloat  { 80 }
    static var rotationDegree: Double { 90 }

    @Binding var currentPage: Int
    @Binding var scrollEnabled: Bool

    // MARK: Private

    @State private var controller: CXInfinityPageController

    private let page: PageContent

    private let pageWillChange: PageWillChange

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
            switch controller.axis {
            case .horizontal:
                TabView(selection: $controller.index) {
                    container(geometry)
                        .contentShape(.rect)
                        .gesture(scrollEnabled ? nil : DragGesture())
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .coordinateSpace(.scrollView(axis: .horizontal))

            case .vertical:
                TabView(selection: $controller.index) {
                    container(geometry)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .rotationEffect(.degrees(-CXInfinityPage.rotationDegree))
                        .contentShape(.rect)
                        .gesture(scrollEnabled ? nil : DragGesture())
                }
                .frame(width: geometry.size.height, height: geometry.size.width)
                .rotationEffect(
                    .degrees(CXInfinityPage.rotationDegree),
                    anchor: .topLeading
                )
                .offset(x: geometry.size.width)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .coordinateSpace(.scrollView(axis: .vertical))
            }
        }
    }
}

// MARK: - ScrollOffsetKey

struct ScrollOffset: Equatable {
    let index: Int
    let offset: CGFloat

    static var zero: ScrollOffset {
        ScrollOffset(index: 0, offset: 0)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: ScrollOffset {
        .zero
    }

    static func reduce(value: inout ScrollOffset, nextValue: () -> ScrollOffset) {
        if value == .zero {
            value = nextValue()
        } else {
            value = ScrollOffset(
                index: value.index,
                offset: value.offset + nextValue().offset
            )
        }
    }
}
