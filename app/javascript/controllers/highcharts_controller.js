import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"
import SavedHongBaoTooltipRenderer from "./charts/tooltips/saved_hong_bao_controller"

export default class extends Controller {
  static values = {
    config: Object,
    tooltipRenderer: String
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

    // Initialize tooltip renderer if configured
    if (options.tooltip) {
      this.initTooltipRenderer()

      const controller = this
      options.tooltip.formatter = function() {
        return controller.renderTooltip(this.points, this.x)
      }
    }

    try {
      this.chart = Highcharts.chart(this.element, options)
      console.log("Chart created successfully")
    } catch (error) {
      console.error("Error creating chart:", error)
    }
  }

  initTooltipRenderer() {
    // Get tooltip template
    const template = this.element.parentElement.querySelector('[data-tooltip-template]')
    if (!template) {
      console.error('Tooltip template not found')
      return
    }

    // Initialize renderer (default to SavedHongBaoTooltipRenderer for now)
    // In the future, this could be configurable via tooltipRendererValue
    this.tooltipRenderer = new SavedHongBaoTooltipRenderer(template)
  }

  renderTooltip(points, timestamp) {
    if (!this.tooltipRenderer) {
      console.error('Tooltip renderer not initialized')
      return ''
    }

    // Extract extra data from the first point (generic approach)
    // Different chart types can attach different data to their points
    const extraData = points[0]?.point?.extraData

    // Delegate to the tooltip renderer
    return this.tooltipRenderer.render(points, timestamp, extraData)
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