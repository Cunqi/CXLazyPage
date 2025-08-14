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
        @ViewBuilder page: @escaping (Int) -> Page
    ) {
        _controller = .init(initialValue: CXInfinityPageController(axis: axis))
        _currentPage = currentPage
        _scrollEnabled = scrollEnabled
        self.page = page
    }

    // MARK: Public

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
                                    value: CXInfinityPage.makeScrollOffset(
                                        frame: geometry.frame(in: .scrollView),
                                        axis: controller.axis
                                    )
                                )
                        }
                    }
                    .onPreferenceChange(ScrollOffsetKey.self) {
                        controller.offset.send($0)
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

    static var rotationDegree: Double { 90 }

    @Binding var currentPage: Int
    @Binding var scrollEnabled: Bool

    // MARK: Private

    @State private var controller: CXInfinityPageController

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

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat {
        .zero
    }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
