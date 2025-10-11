import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"

export default class extends Controller {
  static values = {
    config: Object
  }

  connect() {
    console.log("Highcharts controller connected")
    this.initChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  initChart() {
    console.log("Initializing chart with config:", this.configValue)

    // Merge default options with provided config
    const defaultOptions = {
      chart: {
        renderTo: this.element,
        backgroundColor: 'transparent'
      },
      credits: {
        enabled: false
      },
      title: {
        text: null
      }
    }

    const options = this.deepMerge(defaultOptions, this.configValue)

    try {
      this.chart = Highcharts.chart(this.element, options)
      console.log("Chart created successfully")
    } catch (error) {
      console.error("Error creating chart:", error)
    }
  }

  deepMerge(target, source) {
    const output = Object.assign({}, target)
    if (this.isObject(target) && this.isObject(source)) {
      Object.keys(source).forEach(key => {
        if (this.isObject(source[key])) {
          if (!(key in target))
            Object.assign(output, { [key]: source[key] })
          else
            output[key] = this.deepMerge(target[key], source[key])
        } else {
          Object.assign(output, { [key]: source[key] })
        }
      })
    }
    return output
  }

  isObject(item) {
    return item && typeof item === 'object' && !Array.isArray(item)
  }
}