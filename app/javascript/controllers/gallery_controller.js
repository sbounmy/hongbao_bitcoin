import { Controller } from "@hotwired/stimulus"
import Swiper from 'swiper/bundle';

// Connects to data-controller="gallery"
export default class extends Controller {
  static targets = [ "main", "thumbs" ]

  connect() {
    this.thumbsSwiper = new Swiper(this.thumbsTarget, {
      spaceBetween: 10,
      slidesPerView: 4,
      freeMode: true,
      watchSlidesProgress: true,
      // Enable clicking on thumbnails
      slideToClickedSlide: true,
      // Responsive breakpoints for mobile
      breakpoints: {
        320: {
          slidesPerView: 3,
          spaceBetween: 5
        },
        640: {
          slidesPerView: 4,
          spaceBetween: 10
        },
        768: {
          slidesPerView: 4,
          spaceBetween: 10
        }
      }
    });

    this.mainSwiper = new Swiper(this.mainTarget, {
      slidesPerView: 'auto',
      spaceBetween: 10,
      navigation: {
        nextEl: ".carousel-next",
        prevEl: ".carousel-prev",
      },
      clickable: true,
      thumbs: {
        swiper: this.thumbsSwiper,
      },
      // Listen to slide changes
      on: {
        slideChange: () => {
          this.centerActiveThumb();
        }
      }
    });

    // Also center thumb when clicking on thumbnails
    this.thumbsSwiper.on('click', (swiper) => {
      const clickedIndex = swiper.clickedIndex;
      if (clickedIndex !== undefined) {
        this.mainSwiper.slideTo(clickedIndex);
        this.centerActiveThumb();
      }
    });
  }

  centerActiveThumb() {
    if (!this.thumbsSwiper || !this.mainSwiper) return;

    const activeIndex = this.mainSwiper.activeIndex;
    const thumbsPerView = this.thumbsSwiper.params.slidesPerView;
    const totalThumbs = this.thumbsSwiper.slides.length;

    // Calculate the optimal slide to show
    // We want to keep the active thumb centered when possible
    let targetSlide = activeIndex - Math.floor(thumbsPerView / 2);

    // Ensure we don't go below 0
    targetSlide = Math.max(0, targetSlide);

    // Ensure we don't go beyond the last possible position
    const maxSlide = Math.max(0, totalThumbs - thumbsPerView);
    targetSlide = Math.min(targetSlide, maxSlide);

    // Slide to the calculated position with animation
    this.thumbsSwiper.slideTo(targetSlide, 300);
  }

  disconnect() {
    if (this.mainSwiper) {
      this.mainSwiper.destroy();
    }
    if (this.thumbsSwiper) {
      this.thumbsSwiper.destroy();
    }
  }
}