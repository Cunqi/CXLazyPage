//
//  ViewportTrackerContext.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/18/25.
//

import Foundation

// MARK: - ViewportTrackerContext

/// A context object that configures viewport tracking behavior for lazy loading content.
/// Use the builder pattern through `ViewportTrackerContext.Builder` to create instances.
public struct ViewportTrackerContext {
    /// Whether to show the detection area visually for debugging purposes.
    let showDetectArea: Bool

    /// The ratio of the viewport height that should be considered as the detection area (0.0 to 1.0).
    let detectAreaRatio: CGFloat

    /// The vertical offset from the origin of the detection area in points.
    let detectAreaOriginYOffset: CGFloat

    /// The threshold ratio that determines when content is considered within the viewport (0.0 to 1.0).
    let fulfillThreshold: CGFloat

    /// The minimum time interval between viewport detection checks.
    let detectFrequencyBuffer: DispatchQueue.SchedulerTimeType.Stride
}

// MARK: ViewportTrackerContext.Builder

extension ViewportTrackerContext {
    /// A builder class for creating `ViewportTrackerContext` instances with customized configuration.
    public class Builder {
        // MARK: Lifecycle

        init() { }

        init(from context: ViewportTrackerContext) {
            showDetectArea = context.showDetectArea
            detectAreaRatio = context.detectAreaRatio
            detectAreaOriginYOffset = context.detectAreaOriginYOffset
            fulfillThreshold = context.fulfillThreshold
            detectFrequencyBuffer = context.detectFrequencyBuffer
        }

        // MARK: Public

        /// Sets whether to show the detection area visually.
        /// - Parameter showDetectArea: If true, the detection area will be visible for debugging.
        /// - Returns: The builder instance for method chaining.
        public func showDetectArea(_ showDetectArea: Bool) -> Self {
            self.showDetectArea = showDetectArea
            return self
        }

        /// Sets the ratio of viewport height to use as detection area.
        /// - Parameter detectAreaRatio: A value between 0.0 and 1.0, default is 0.8.
        /// - Returns: The builder instance for method chaining.
        public func detectAreaRatio(_ detectAreaRatio: CGFloat) -> Self {
            self.detectAreaRatio = detectAreaRatio
            return self
        }

        /// Sets the vertical offset for the detection area.
        /// - Parameter detectAreaOriginYOffset: Offset in points from the origin, default is 0.0.
        /// - Returns: The builder instance for method chaining.
        public func detectAreaOriginYOffset(_ detectAreaOriginYOffset: CGFloat) -> Self {
            self.detectAreaOriginYOffset = detectAreaOriginYOffset
            return self
        }

        /// Sets the threshold for considering content within viewport.
        /// - Parameter fulfillThreshold: A value between 0.0 and 1.0, default is 0.8.
        /// - Returns: The builder instance for method chaining.
        public func fulfillThreshold(_ fulfillThreshold: CGFloat) -> Self {
            self.fulfillThreshold = fulfillThreshold
            return self
        }

        /// Sets the minimum time interval between viewport detection checks.
        /// - Parameter detectFrequencyBuffer: Time interval as DispatchQueue.SchedulerTimeType.Stride,
        ///                                   default is 100 milliseconds.
        /// - Returns: The builder instance for method chaining.
        public func detectFrequencyBuffer(_ detectFrequencyBuffer: DispatchQueue.SchedulerTimeType
            .Stride
        ) -> Self {
            self.detectFrequencyBuffer = detectFrequencyBuffer
            return self
        }

        public func build() -> ViewportTrackerContext {
            ViewportTrackerContext(
                showDetectArea: showDetectArea,
                detectAreaRatio: detectAreaRatio,
                detectAreaOriginYOffset: detectAreaOriginYOffset,
                fulfillThreshold: fulfillThreshold,
                detectFrequencyBuffer: detectFrequencyBuffer
            )
        }

        // MARK: Private

        private var showDetectArea = false
        private var detectAreaRatio = 0.8
        private var detectAreaOriginYOffset = 0.0
        private var fulfillThreshold = 0.8
        private var detectFrequencyBuffer = DispatchQueue.SchedulerTimeType.Stride.milliseconds(100)
    }
}

extension ViewportTrackerContext {
    // MARK: Public

    /// Returns a default configuration of ViewportTrackerContext.
    /// Default values are:
    /// - showDetectArea: false
    /// - detectAreaRatio: 0.8
    /// - detectAreaOriginYOffset: 0.0
    /// - fulfillThreshold: 0.8
    /// - detectFrequencyBuffer: 100 milliseconds
    public static var `default`: ViewportTrackerContext {
        Builder().build()
    }

    // MARK: Internal

    public var builder: Builder {
        Builder(from: self)
    }
}
