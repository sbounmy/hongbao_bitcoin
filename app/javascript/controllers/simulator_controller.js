import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js"

export default class extends Controller {
  static targets = [
    "birthday", "ageDisplay",
    "birthdayAmount", "birthdayTotal", "birthdayCalc",
    "christmasAmount", "christmasTotal", "christmasCalc",
    "cnyAmount", "cnyTotal", "cnyCalc",
    "btcTotal", "totalValue", "btcPrice",
    "chart"
  ]

  connect() {
    this.chart = null
    this.calculate()
  }

  calculate() {
    if (!this.birthdayTarget.value) return

    const birthday = new Date(this.birthdayTarget.value)
    const today = new Date()

    // Calculate age
    let age = today.getFullYear() - birthday.getFullYear()
    const monthDiff = today.getMonth() - birthday.getMonth()
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthday.getDate())) {
      age--
    }

    if (age > 0) {
      this.ageDisplayTarget.textContent = `Age: ${age} years old`

      // Calculate totals
      const birthdayAmount = parseFloat(this.birthdayAmountTarget.value) || 0
      const christmasAmount = parseFloat(this.christmasAmountTarget.value) || 0
      const cnyAmount = parseFloat(this.cnyAmountTarget.value) || 0
      const btcPrice = parseFloat(this.btcPriceTarget.textContent) || 43000

      const birthdayTotal = age * birthdayAmount
      const christmasTotal = age * christmasAmount
      const cnyTotal = age * cnyAmount
      const totalEuros = birthdayTotal + christmasTotal + cnyTotal
      const totalBtc = totalEuros / btcPrice

      // Update displays
      this.birthdayTotalTarget.textContent = `€${birthdayTotal.toLocaleString()}`
      this.christmasTotalTarget.textContent = `€${christmasTotal.toLocaleString()}`
      this.cnyTotalTarget.textContent = `€${cnyTotal.toLocaleString()}`
      this.birthdayCalcTarget.textContent = `${age} years × €${birthdayAmount}`
      this.christmasCalcTarget.textContent = `${age} years × €${christmasAmount}`
      this.cnyCalcTarget.textContent = `${age} years × €${cnyAmount}`
      this.btcTotalTarget.textContent = `${totalBtc.toFixed(8)} BTC`
      this.totalValueTarget.textContent = `Total Value: €${totalEuros.toLocaleString()}`

      this.updateChart(age, birthdayAmount, christmasAmount, cnyAmount, btcPrice)
    }
  }

  updateChart(age, birthdayAmount, christmasAmount, cnyAmount, btcPrice) {
    const data = []
    for (let year = 1; year <= age; year++) {
      const yearlyTotal = (birthdayAmount + christmasAmount + cnyAmount) * year
      data.push({
        year,
        euros: yearlyTotal,
        btc: yearlyTotal / btcPrice
      })
    }

    if (this.chart) {
      this.chart.destroy()
    }

    const ctx = this.chartTarget.getContext('2d')
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.map(d => `Year ${d.year}`),
        datasets: [
          {
            label: 'Euros',
            data: data.map(d => d.euros),
            borderColor: '#FFB636',
            yAxisID: 'y'
          },
          {
            label: 'Bitcoin',
            data: data.map(d => d.btc),
            borderColor: '#F04747',
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            grid: {
              color: 'rgba(255, 182, 54, 0.1)'
            },
            ticks: {
              color: '#FFB636'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            grid: {
              drawOnChartArea: false,
              color: 'rgba(240, 71, 71, 0.1)'
            },
            ticks: {
              color: '#F04747'
            }
          }
        },
        plugins: {
          legend: {
            labels: {
              color: '#FFFFFF'
            }
          }
        }
      }
    })
  }
}