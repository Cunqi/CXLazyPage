# CXLazyPage

## Overview

CXLazyPage is a SwiftUI package that provides a lazy loading mechanism for views. It allows you to load views only when they are needed, improving performance and reducing memory usage.

The machenism relies on `UICollectionView`, which is a powerful and flexible way to manage collections of views in iOS. CXLazyPage leverages this to create a lazy loading experience for SwiftUI views.

## Core Components

### CXLazyPage

`CXLazyPage` is the main component of the package. It is a SwiftUI view that implements `UIViewControllerRepresentable` to wrap a `CXLayzyPageController`. This controller manages the lazy loading of views using a `UICollectionView`.

### CXLazyPageContext

`CXLazyPageContext` provides configuration for a lazy-loading paging component.
This struct describes the axis (horizontal or vertical) along which the pages are laid out, and whether paging is enabled. With the inner `Builder` class, you can flexibly configure and construct the desired paging context.

### CXLazyPageController

CXLazyPageViewController is a generic UIViewController subclass responsible for efficiently managing and displaying lazily loaded page content using a UICollectionView. It is designed to support SwiftUI-based page views, allowing infinite or very large numbers of pages while maintaining smooth scrolling and low memory usage.

#### Core Responsibilities:
• Hosts a UICollectionView with a custom layout to display pages either horizontally or vertically, based on the provided context.
• Uses a very large (effectively “infinite”) page count, starting at a center anchor, to allow seamless scrolling both forward and backward.
• Lazily provides SwiftUI view content for each page using a closure. Views are only created when needed for display.
• Manages the current page index as the single source of truth and offers a callback to notify clients when the page changes.
• Handles fast scrolling scenarios to ensure correct view updates and optimize performance.
• Provides public APIs for programmatically scrolling to a specific page while maintaining correct state and UI updates.
• Adapts scrolling and layout behavior based on the configuration in CXLazyPageContext, such as axis and paging enabled state.

Typical Usage Context:
This controller is typically wrapped by a SwiftUI component (such as `CXLazyPage`) using UIViewControllerRepresentable, allowing you to integrate efficient, infinite, and lazily loaded paging in SwiftUI interfaces.
