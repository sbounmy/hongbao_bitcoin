export default class SavedHongBaoTooltipRenderer {
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
      color: p.color
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
    const extraTemplate = this.getTemplate('[data-tooltip-extra-template]')
    const pointsTemplate = this.getTemplate('[data-tooltip-point-template]')

    // Handle chart data points
    this.renderPoints(container, pointsTemplate, points)

    // Handle extra data section (Hong Baos)
    this.renderExtraData(container, extraTemplate, extraData)

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

  renderExtraData(container, template, extraData) {
    const extraSection = container.querySelector('[data-tooltip-extra-section]')
    if (!extraSection) return

    if (extraData && extraData.length > 0 && template) {
      const extraContainer = container.querySelector('[data-tooltip-extra-container]')

      console.log('Rendering extraData:', extraData)

      extraData.forEach((item) => {
        console.log('Processing item:', item)
        const itemClone = template.content.cloneNode(true)
        const itemWrapper = document.createElement('div')
        itemWrapper.appendChild(itemClone)

        // Get the actual element (first child of wrapper)
        const itemEl = itemWrapper.firstElementChild

        // Title (recipient name)
        const titleEl = itemEl.querySelector('[data-extra-title]')
        if (titleEl) titleEl.textContent = item.recipient

        // Subtitle (address)
        const subtitleEl = itemEl.querySelector('[data-extra-subtitle]')
        if (subtitleEl) subtitleEl.textContent = item.address

        // Status badge
        this.renderStatusBadge(itemEl, item.status)

        // Value info
        this.renderValueInfo(itemEl, item)

        // Avatar
        this.renderAvatar(itemEl, item.avatarUrl)

        extraContainer.appendChild(itemEl)
      })
    } else {
      extraSection.remove()
    }
  }

  renderStatusBadge(container, status) {
    const badgeEl = container.querySelector('[data-extra-badge]')
    if (!badgeEl) return

    badgeEl.textContent = status

    // Apply badge styles based on status
    const badges = {
      'HODL': 'bg-warning/30 text-warning-content',
      'WITHDRAWN': 'bg-error/30 text-error-content',
      'DEFAULT': 'bg-success/30 text-success-content'
    }

    const classes = badges[status] || badges['DEFAULT']
    badgeEl.className = `text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wide ${classes}`
  }

  renderValueInfo(container, item) {
    const valueInfoEl = container.querySelector('[data-extra-value]')
    if (!valueInfoEl) return

    if (item.status === 'HODL') {
      const changeClasses = item.priceChangePercent >= 0 ? 'text-success' : 'text-error'
      const changeSign = item.priceChangePercent >= 0 ? '+' : ''
      const initialValueStr = item.initialValue.toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      })
      const currentValueStr = item.currentValue.toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      })
      valueInfoEl.innerHTML = `${item.btc.toFixed(8)} BTC <span class="text-base-content/60">($${initialValueStr})</span> → <span class="${changeClasses}">$${currentValueStr} (${changeSign}${item.priceChangePercent}%)</span>`
    } else if (item.status === 'WITHDRAWN') {
      valueInfoEl.innerHTML = `<span class="text-base-content/60">Withdrew ${item.initialBtc.toFixed(8)} BTC</span>`
    } else {
      valueInfoEl.innerHTML = `${item.btc.toFixed(8)} BTC`
    }
  }

  renderAvatar(container, avatarUrl) {
    const avatarEl = container.querySelector('[data-extra-avatar]')
    console.log('renderAvatar called', { avatarEl, avatarUrl })

    if (!avatarEl) {
      console.error('Avatar element not found')
      return
    }

    if (!avatarUrl) {
      console.error('Avatar URL is missing')
      return
    }

    // Create an img element with the avatar URL
    const img = document.createElement('img')
    img.src = avatarUrl
    img.className = 'rounded-full w-7 h-7'
    img.alt = 'Avatar'

    avatarEl.appendChild(img)
    console.log('Avatar rendered successfully')
  }
}
