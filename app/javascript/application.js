// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"

// Chartkick and Highcharts setup
import Chartkick from "chartkick"
import Highcharts from "highcharts"

Chartkick.use(Highcharts)
window.Chartkick = Chartkick

