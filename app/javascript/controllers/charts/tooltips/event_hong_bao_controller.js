export default class EventHongBaoTooltipRenderer {
  constructor(templateElement) {
    this.templateElement = templateElement
  }

  render(points, timestamp, extraData) {
    if (!points || !Array.isArray(points)) {
      return ''
    }

    // Format date
    const date = this.formatDate(timestamp)

    // Format points data
    const pointsData = points.map(p => ({
      name: p.series.name,
      value: p.y,
      color: p.color || p.series.color
    }))

    // Clone and populate the template
    return this.populateTemplate(date, pointsData, extraData)
  }

  formatDate(timestamp) {
    // Use Highcharts date formatter if available globally
    if (window.Highcharts) {
      return window.Highcharts.dateFormat('%B %e, %Y', timestamp)
    }
    // Fallback to native formatting
    return new Date(timestamp).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  populateTemplate(date, points, extraData) {
    const clone = this.templateElement.content.cloneNode(true)
    const container = document.createElement('div')
    container.appendChild(clone)

    // Set date
    const dateElement = container.querySelector('[data-tooltip-date]')
    if (dateElement) dateElement.textContent = date

    // Get nested templates
    const eventTemplate = this.getTemplate('[data-event-item-template]')
    const pointsTemplate = this.getTemplate('[data-tooltip-point-template]')

    // Handle chart data points
    this.renderPoints(container, pointsTemplate, points)

    // Handle event data section
    this.renderEventData(container, eventTemplate, extraData)

    return container.innerHTML
  }

  getTemplate(selector) {
    return this.templateElement.parentElement.querySelector(selector)
  }

  renderPoints(container, template, points) {
    const pointsContainer = container.querySelector('[data-tooltip-points-container]')

    if (template && pointsContainer) {
      points.forEach(point => {
        const pointClone = template.content.cloneNode(true)
        const pointDiv = document.createElement('div')
        pointDiv.appendChild(pointClone)

        const bullet = pointDiv.querySelector('[data-point-bullet]')
        if (bullet) bullet.style.color = point.color

        const nameElement = pointDiv.querySelector('[data-point-name]')
        if (nameElement) nameElement.textContent = point.name

        const valueElement = pointDiv.querySelector('[data-point-value]')
        if (valueElement) {
          valueElement.textContent = point.value.toLocaleString('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          })
        }

        pointsContainer.appendChild(pointDiv.firstElementChild)
      })
    }
  }

  renderEventData(container, template, extraData) {
    const eventSection = container.querySelector('[data-tooltip-event-section]')
    if (!eventSection) return

    if (extraData && extraData.length > 0 && template) {
      const eventContainer = container.querySelector('[data-tooltip-event-container]')

      extraData.forEach((item) => {
        const itemClone = template.content.cloneNode(true)
        const itemWrapper = document.createElement('div')
        itemWrapper.appendChild(itemClone)

        // Get the actual element (first child of wrapper)
        const itemEl = itemWrapper.firstElementChild

        // Event emoji
        const emojiEl = itemEl.querySelector('[data-event-emoji]')
        if (emojiEl) emojiEl.textContent = item.event_emoji

        // Event title
        const titleEl = itemEl.querySelector('[data-event-title]')
        if (titleEl) titleEl.textContent = item.name

        // Gift amount
        const giftAmountEl = itemEl.querySelector('[data-event-gift-amount]')
        if (giftAmountEl) giftAmountEl.textContent = `$${item.initial_usd}`

        // BTC price
        const btcPriceEl = itemEl.querySelector('[data-event-btc-price]')
        if (btcPriceEl) {
          btcPriceEl.textContent = `$${item.initial_price.toLocaleString('en-US', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
          })}`
        }

        // Sats amount
        const satsEl = itemEl.querySelector('[data-event-sats]')
        if (satsEl) {
          satsEl.textContent = item.initial_sats.toLocaleString('en-US')
        }

        // Current value
        const currentValueEl = itemEl.querySelector('[data-event-current-value]')
        if (currentValueEl && item.current_usd) {
          currentValueEl.textContent = `$${item.current_usd.toLocaleString('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          })}`
        }

        // Change badge
        const changeBadgeEl = itemEl.querySelector('[data-event-change-badge]')
        if (changeBadgeEl && item.change_percent !== undefined) {
          const changeSign = item.change_percent >= 0 ? '+' : ''
          const changeClass = item.change_percent >= 0 ? 'badge-success' : 'badge-error'
          changeBadgeEl.className = `badge badge-sm ${changeClass}`
          changeBadgeEl.textContent = `${changeSign}${item.change_percent.toFixed(1)}%`
        }

        eventContainer.appendChild(itemEl)
      })
    } else {
      eventSection.remove()
    }
  }
}