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

    // Set custom tooltip formatter
    if (options.tooltip) {
      const controller = this
      options.tooltip.formatter = function() {
        // 'this' in the formatter context is the tooltip, not the controller
        // so we use the controller reference from the closure
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

  renderTooltip(points, timestamp) {
    if (!points || !Array.isArray(points)) {
      return ''
    }

    // Find Bitcoin Price point to check for Hong Bao data
    const bitcoinPoint = points.find(p => p.series.name === 'Bitcoin Price')
    const hongBaos = bitcoinPoint?.point?.hongBaos

    // Format date
    const date = Highcharts.dateFormat('%B %e, %Y', timestamp)

    // Format points data
    const pointsData = points.map(p => ({
      name: p.series.name,
      value: p.y,
      color: p.color
    }))

    // Get the template from the parent element (sibling of chart div)
    const template = this.element.parentElement.querySelector('[data-tooltip-template]')
    if (!template) {
      console.error('Tooltip template not found', this.element.parentElement)
      return ''
    }

    // Clone and populate the template
    return this.populateTemplate(template, date, pointsData, hongBaos)
  }

  populateTemplate(template, date, points, hongBaos) {
    const clone = template.content.cloneNode(true)
    const container = document.createElement('div')
    container.appendChild(clone)

    // Set date
    const dateElement = container.querySelector('[data-tooltip-date]')
    if (dateElement) dateElement.textContent = date

    // Get nested templates from parent element (not from cloned content)
    const hongBaoTemplate = this.element.parentElement.querySelector('[data-tooltip-hongbao-template]')
    const pointsTemplate = this.element.parentElement.querySelector('[data-tooltip-point-template]')

    // Handle chart data points
    const pointsContainer = container.querySelector('[data-tooltip-points-container]')

    if (pointsTemplate && pointsContainer) {
      points.forEach(point => {
        const pointClone = pointsTemplate.content.cloneNode(true)
        const pointDiv = document.createElement('div')
        pointDiv.appendChild(pointClone)

        const bullet = pointDiv.querySelector('[data-point-bullet]')
        if (bullet) bullet.style.color = point.color

        const nameElement = pointDiv.querySelector('[data-point-name]')
        if (nameElement) nameElement.textContent = point.name

        const valueElement = pointDiv.querySelector('[data-point-value]')
        if (valueElement) valueElement.textContent = point.value.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})

        pointsContainer.appendChild(pointDiv.firstElementChild)
      })
    }

    // Handle Hong Bao section
    const hongBaoSection = container.querySelector('[data-tooltip-hongbao-section]')
    if (hongBaoSection) {
      if (hongBaos && hongBaos.length > 0 && hongBaoTemplate) {
        const hongBaoContainer = container.querySelector('[data-tooltip-hongbao-container]')

        hongBaos.forEach((hb) => {
          const hbClone = hongBaoTemplate.content.cloneNode(true)
          const hbDiv = document.createElement('div')
          hbDiv.appendChild(hbClone)

          // Recipient name
          hbDiv.querySelector('[data-hb-recipient]').textContent = hb.recipient

          // Address (shortened)
          hbDiv.querySelector('[data-hb-address]').textContent = hb.address

          // Status badge
          const statusBadge = hbDiv.querySelector('[data-hb-status-badge]')
          statusBadge.textContent = hb.status

          if (hb.status === 'HODL') {
            statusBadge.style.backgroundColor = '#fef3c7'
            statusBadge.style.color = '#92400e'
          } else if (hb.status === 'WITHDRAWN') {
            statusBadge.style.backgroundColor = '#fee2e2'
            statusBadge.style.color = '#991b1b'
          } else {
            statusBadge.style.backgroundColor = '#d1fae5'
            statusBadge.style.color = '#065f46'
          }

          // Value info - only show relevant information
          const valueInfo = hbDiv.querySelector('[data-hb-value-info]')
          if (hb.status === 'HODL') {
            const changeColor = hb.priceChangePercent >= 0 ? '#059669' : '#dc2626'
            const changeSign = hb.priceChangePercent >= 0 ? '+' : ''
            const initialValueStr = hb.initialValue.toLocaleString('en-US', {minimumFractionDigits: 0, maximumFractionDigits: 0})
            const currentValueStr = hb.currentValue.toLocaleString('en-US', {minimumFractionDigits: 0, maximumFractionDigits: 0})
            valueInfo.innerHTML = `${hb.btc.toFixed(8)} BTC <span style="color: #78716c;">($${initialValueStr})</span> → <span style="color: ${changeColor};">$${currentValueStr} (${changeSign}${hb.priceChangePercent}%)</span>`
          } else if (hb.status === 'WITHDRAWN') {
            valueInfo.innerHTML = `<span style="color: #78716c;">Withdrew ${hb.initialBtc.toFixed(8)} BTC</span>`
          } else {
            valueInfo.innerHTML = `${hb.btc.toFixed(8)} BTC`
          }

          hongBaoContainer.appendChild(hbDiv.firstElementChild)
        })
      } else {
        hongBaoSection.remove()
      }
    }

    return container.innerHTML
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