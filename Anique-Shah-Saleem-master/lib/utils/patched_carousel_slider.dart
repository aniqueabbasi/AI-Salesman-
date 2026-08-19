// This is a simplified version of the carousel_slider widget that uses our patched controller
// to avoid naming conflicts

import 'package:flutter/material.dart';
import 'patched_carousel_controller.dart';

class PatchedCarouselSlider extends StatefulWidget {
  /// The widgets to be shown as sliders.
  final List<Widget> items;

  /// Set carousel height and overrides any existing [aspectRatio].
  final double? height;

  /// Aspect ratio is used if no height have been declared.
  ///
  /// Defaults to 16:9 aspect ratio.
  final double aspectRatio;

  /// The fraction of the viewport that each page should occupy.
  ///
  /// Defaults to 0.8, which means each page fills 80% of the viewport.
  final double viewportFraction;

  /// The initial page to show when first creating the [PatchedCarouselSlider].
  /// Defaults to 0.
  final int initialPage;

  /// Called whenever the page in the center of the viewport changes.
  final Function(int index, CarouselPageChangedReason reason)? onPageChanged;

  /// Auto scroll interval.
  /// Do not auto scroll when scrollTime equals to zero.
  final Duration autoPlayInterval;

  /// Whether to automatically rebuild [PatchedCarouselSlider] when receiving a resize event.
  final bool disableCenter;

  /// Whether to enable auto play function.
  ///
  /// Default to false.
  final bool autoPlay;

  /// Controls whether the widget's pages will respond to
  /// [RenderObject.showOnScreen], which will allow for implicit accessibility
  /// scrolling.
  ///
  /// Default to true.
  ///
  /// See also:
  ///
  ///  * [RenderObject.showOnScreen]
  final bool allowImplicitScrolling;

  /// Called whenever the carousel is scrolled
  final ValueChanged<double?>? onScrolled;

  /// Called when the carousel is scrolled.
  final ScrollPhysics? scrollPhysics;

  /// How the carousel should respond to user input.
  ///
  /// For example, determines how the items continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [scrollPhysics].
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  final bool pageSnapping;

  /// If `true`, the auto play function will be paused when user is interacting with
  /// the carousel, and will be resumed when user finish interacting.
  /// Default to true.
  final bool pauseAutoPlayOnTouch;

  /// If `true`, the auto play function will be paused when user is calling
  /// pageController's method.
  /// Default to true.
  final bool pauseAutoPlayOnManualNavigate;

  /// If `true`, the auto play function will be paused when carousel is in the
  /// viewport, and will be resumed when carousel is not in the viewport.
  /// Default to true.
  final bool pauseAutoPlayInFiniteScroll;

  /// Pass a [PatchedCarouselController] to manually control the carousel.
  /// Be aware that using the controller, the onPageChanged function won't be triggered.
  final PatchedCarouselController? controller;

  /// The options for controlling how the carousel should behave.
  ///
  /// See [CarouselOptions] for more details.
  const PatchedCarouselSlider({super.key, 
    required this.items,
    this.height,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 0.8,
    this.initialPage = 0,
    this.onPageChanged,
    this.physics,
    this.scrollPhysics,
    this.pageSnapping = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.disableCenter = false,
    this.autoPlay = false,
    this.allowImplicitScrolling = true,
    this.pauseAutoPlayOnTouch = true,
    this.pauseAutoPlayOnManualNavigate = true,
    this.pauseAutoPlayInFiniteScroll = true,
    this.onScrolled,
    this.controller,
  });

  @override
  PatchedCarouselSliderState createState() => PatchedCarouselSliderState();
}

class PatchedCarouselSliderState extends State<PatchedCarouselSlider> with TickerProviderStateMixin {
  late PageController _pageController;
  late PatchedCarouselController _carouselController;

  /// Timer for auto play
  Timer? _timer;

  /// Current page index
  int _currentPage = 0;

  /// Whether this carousel is currently being dragged
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    
    _carouselController = widget.controller ?? PatchedCarouselController(
      initialPage: widget.initialPage,
      viewportFraction: widget.viewportFraction,
    );
    
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: widget.initialPage,
    );

    _currentPage = widget.initialPage;
    _setupCarouselController();
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _setupCarouselController() {
    _carouselController.setJumpToPage((int page) {
      final index = _getActualIndex(page);
      _pageController.jumpToPage(index);
    });

    _carouselController.setAnimateToPage((int page, {Duration? duration, Curve? curve}) {
      final index = _getActualIndex(page);
      _pageController.animateToPage(
        index,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.linear,
      );
    });

    _carouselController.setNextPage(({Duration? duration, Curve? curve}) {
      final nextPage = _currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.linear,
      );
    });

    _carouselController.setPreviousPage(({Duration? duration, Curve? curve}) {
      final previousPage = _currentPage - 1;
      _pageController.animateToPage(
        previousPage,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopAutoPlay();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, _autoPlayTimerCallback);
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  void _autoPlayTimerCallback(Timer timer) {
    if (!mounted || _isScrolling) return;
    // While the slider sits in an offstage branch (e.g. a bottom-nav
    // IndexedStack) the PageView is never laid out, so the controller has no
    // clients and animateToPage would assert. Skip the tick until it attaches.
    if (!_pageController.hasClients) return;

    final nextPage = _currentPage + 1;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
    );
  }

  int _getActualIndex(int index) {
    // Handle index for infinite scrolling if needed
    return index % widget.items.length;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = widget.height ?? constraints.maxWidth / widget.aspectRatio;
        
        return SizedBox(
          height: height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isScrolling = true;
                if (widget.pauseAutoPlayOnTouch && widget.autoPlay) {
                  _stopAutoPlay();
                }
              } else if (notification is ScrollEndNotification) {
                _isScrolling = false;
                if (widget.pauseAutoPlayOnTouch && widget.autoPlay) {
                  _startAutoPlay();
                }
              } else if (notification is ScrollUpdateNotification) {
                if (widget.onScrolled != null) {
                  widget.onScrolled!(notification.metrics.pixels);
                }
              }
              return false;
            },
            child: PageView.builder(
              physics: widget.physics ?? widget.scrollPhysics,
              controller: _pageController,
              pageSnapping: widget.pageSnapping,
              allowImplicitScrolling: widget.allowImplicitScrolling,
              onPageChanged: (int index) {
                _currentPage = index;
                if (widget.onPageChanged != null) {
                  final actualIndex = _getActualIndex(index);
                  widget.onPageChanged!(actualIndex, CarouselPageChangedReason.timed);
                }
              },
              itemBuilder: (context, index) {
                final actualIndex = _getActualIndex(index);
                return widget.items[actualIndex];
              },
              itemCount: widget.items.length,
            ),
          ),
        );
      },
    );
  }
}

/// The reason why current page changed to another.
enum CarouselPageChangedReason {
  /// Triggered by a controller.
  controller,

  /// Triggered by a swipe.
  manual,
  
  /// Triggered by an auto-scroll.
  timed
}

// Required for compatibility with existing carousel_slider package
class Timer {
  final Duration duration;
  final Function(Timer) callback;
  bool _isActive = false;
  
  Timer.periodic(this.duration, this.callback) {
    _isActive = true;
    // Start a real timer using Flutter's periodic timer
    _startTimer();
  }
  
  void _startTimer() {
    Future.delayed(duration, () {
      if (_isActive) {
        callback(this);
        _startTimer();
      }
    });
  }
  
  bool get isActive => _isActive;
  
  void cancel() {
    _isActive = false;
  }
} 