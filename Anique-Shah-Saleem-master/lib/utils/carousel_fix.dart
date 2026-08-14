// This utility file re-exports carousel_slider components
// with proper handling for the CarouselController naming conflict

export 'package:carousel_slider/carousel_slider.dart';
export 'package:carousel_slider/carousel_controller.dart' hide CarouselController;
export 'package:carousel_slider/carousel_options.dart';

// Re-export the CarouselController with a safe name to prevent conflicts
import 'package:carousel_slider/carousel_controller.dart' as carousel_slider;

// Create a factory function that can be used across the app
CarouselControllerImpl createCarouselController() {
  return carousel_slider.CarouselController();
}

typedef CarouselControllerImpl = carousel_slider.CarouselController; 