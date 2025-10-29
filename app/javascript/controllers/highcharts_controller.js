import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts/highstock"
import SavedHongBaoTooltipRenderer from "./charts/tooltips/saved_hong_bao_controller"
import EventHongBaoTooltipRenderer from "./charts/tooltips/event_hong_bao_controller"

export default class extends Controller {
  static values = {
    config: Object,
    tooltipRenderer: { type: String, default: "SavedHongBaoTooltipRenderer" },
    tooltipTemplateSelector: { type: String, default: "[data-tooltip-template]" },
    useStock: { type: Boolean, default: false }
  }

  connect() {
    console.log("Highcharts controller connected")

    // Set global Highcharts options for number abbreviation
    Highcharts.setOptions({
      lang: {
        numericSymbols: ['k', 'M', 'B', 'T']
      }
    })

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
      // Use stockChart if useStock is true, otherwise use regular chart
      if (this.useStockValue) {
        this.chart = Highcharts.stockChart(this.element, options)
        console.log("Stock chart created successfully")
      } else {
        this.chart = Highcharts.chart(this.element, options)
        console.log("Chart created successfully")
      }
    } catch (error) {
      console.error("Error creating chart:", error)
    }
  }

  initTooltipRenderer() {
    // Map of available tooltip renderers
    const renderers = {
      'SavedHongBaoTooltipRenderer': SavedHongBaoTooltipRenderer,
      'EventHongBaoTooltipRenderer': EventHongBaoTooltipRenderer
    }

    // Get the configured renderer class
    const RendererClass = renderers[this.tooltipRendererValue]

    if (!RendererClass) {
      console.error(`Tooltip renderer '${this.tooltipRendererValue}' not found`)
      return
    }

    // Use the configured template selector or default based on renderer type
    let templateSelector = this.tooltipTemplateSelectorValue

    // If no custom selector provided, use defaults based on renderer
    if (templateSelector === "[data-tooltip-template]" && this.tooltipRendererValue === 'EventHongBaoTooltipRenderer') {
      templateSelector = '[data-event-tooltip-template]'
    }

    const template = this.element.parentElement.querySelector(templateSelector)

    if (!template) {
      console.error(`Tooltip template not found for selector: ${templateSelector}`)
      return
    }

    // Initialize the configured renderer
    this.tooltipRenderer = new RendererClass(template)
    console.log(`Initialized ${this.tooltipRendererValue} with template: ${templateSelector}`)
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