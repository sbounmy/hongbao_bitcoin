import { Controller } from "@hotwired/stimulus"
import Swiper from 'swiper/bundle';

// Connects to data-controller="gallery"
export default class extends Controller {
  static targets = [ "main", "thumbs" ]

  connect() {
    this.thumbsSwiper = new Swiper(this.thumbsTarget, {
      direction: 'vertical',
      spaceBetween: 10,
      slidesPerView: 4,
      freeMode: true,
      watchSlidesProgress: true,
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
      pagination: {el: ".carousel-pagination", clickable: true}
    });
  }
  disconnect() {
    this.mainSwiper.destroy();
    this.thumbsSwiper.destroy();
  }
}