// This is a patched version of the carousel_controller.dart file from the carousel_slider package
// to avoid naming conflicts with Flutter's CarouselController

import 'package:flutter/material.dart';

/// A controller for [CarouselSlider].
///
/// A page controller lets you manipulate which page is visible in a [CarouselSlider].
/// In addition to being able to control the pixel offset of the content inside
/// the [CarouselSlider], a [PatchedCarouselController] also lets you control the offset in terms
/// of pages, i.e. which page is centered in the viewport.
class PatchedCarouselController {
  /// Creates a controller for [CarouselSlider].
  ///
  /// The [initialPage], [keepPage], and [viewportFraction] arguments must not be null.
  PatchedCarouselController({
    this.initialPage = 0,
    this.keepPage = true,
    this.viewportFraction = 0.8,
    this.initialScrollOffset = 0.0,
  });

  /// The page to show when first creating the [CarouselSlider].
  final int initialPage;

  /// Save the current [page] with [PageStorage] and restore it if
  /// this controller's scrollable is recreated.
  ///
  /// If this property is set to false, the current [page] is never saved
  /// and [initialPage] is always used to initialize the scroll offset.
  /// If true (the default), the initial page is used the first time the
  /// controller's scrollable is created, since there's isn't a page to
  /// restore yet. Subsequently the saved page is restored and
  /// [initialPage] is ignored.
  final bool keepPage;

  /// The fraction of the viewport that each page should occupy.
  ///
  /// Defaults to 0.8, which means each page fills 80% of the viewport.
  final double viewportFraction;

  /// Specifies the initial scroll offset.
  ///
  /// Defaults to 0.0.
  final double initialScrollOffset;

  /// Animates the controlled [CarouselSlider] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> nextPage({required Duration duration, required Curve curve}) async {
    _nextPage?.call(duration: duration, curve: curve);
    return Future.value();
  }

  /// Animates the controlled [CarouselSlider] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> previousPage({required Duration duration, required Curve curve}) async {
    _previousPage?.call(duration: duration, curve: curve);
    return Future.value();
  }

  /// Animates the controlled [CarouselSlider] to the specified page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> animateToPage(int page, {required Duration duration, required Curve curve}) async {
    _animateToPage?.call(page, duration: duration, curve: curve);
    return Future.value();
  }

  /// Changes which page is displayed in the controlled [CarouselSlider].
  ///
  /// Jumps the page position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToPage(int page) {
    _jumpToPage?.call(page);
  }

  /// Registers methods that will be called when jumpToPage is called
  void setJumpToPage(void Function(int) jumpToPage) {
    _jumpToPage = jumpToPage;
  }

  /// Registers methods that will be called when animateToPage is called
  void setAnimateToPage(void Function(int, {Duration duration, Curve curve}) animateToPage) {
    _animateToPage = animateToPage;
  }

  /// Registers methods that will be called when nextPage is called
  void setNextPage(void Function({Duration duration, Curve curve}) nextPage) {
    _nextPage = nextPage;
  }

  /// Registers methods that will be called when previousPage is called
  void setPreviousPage(void Function({Duration duration, Curve curve}) previousPage) {
    _previousPage = previousPage;
  }

  void Function(int)? _jumpToPage;
  void Function(int, {Duration duration, Curve curve})? _animateToPage;
  void Function({Duration duration, Curve curve})? _nextPage;
  void Function({Duration duration, Curve curve})? _previousPage;
} 