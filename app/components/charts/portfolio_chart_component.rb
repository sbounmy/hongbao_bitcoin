# frozen_string_literal: true

module Charts
  class PortfolioChartComponent < ApplicationComponent
    attr_reader :saved_hong_baos

    def initialize(saved_hong_baos:, height: "450px")
      @saved_hong_baos = saved_hong_baos
      @height = height
      @service = BitcoinPortfolioService.new(saved_hong_baos)
      @data = @service.call
    end

    private

    def height
      @height
    end

    def chart_config
      {
        chart: {
          type: "line",
          height: @height.gsub("px", "").to_i
        },
        xAxis: {
          type: "datetime"
        },
        yAxis: [
          {
            title: false
          },
          {
            title: false,
            opposite: true
          }
        ],
        tooltip: {
          crosshairs: true,
          shared: true,
          useHTML: true,
          backgroundColor: "transparent",
          borderWidth: 0,
          shadow: false,
          padding: 0
        },
        plotOptions: {
          series: {
            turboThreshold: 0  # Disable threshold to handle large datasets
          },
          line: {
            marker: {
              enabled: false  # Disable by default, individual points will override
            }
          },
          area: {
            fillOpacity: 0.2,
            marker: { enabled: false }
          }
        },
        series: [
          {
            name: "Bitcoin Price",
            data: @data[:btc_prices_with_markers],
            type: "line",
            yAxis: 1,
            color: "#f7931a",
            marker: { enabled: false },
            lineWidth: 2
          },
          {
            name: "HongBao Value",
            data: @data[:portfolio],
            type: "area",
            yAxis: 0,
            color: "#10b981",
            fillOpacity: 0.2
          },
          {
            name: "HongBao Spent",
            data: @data[:net_deposits],
            type: "line",
            yAxis: 0,
            color: "#991b1b",
            dashStyle: "LongDash",
            lineWidth: 1
          }
        ],
        responsive: {
          rules: [
            {
              condition: {
                maxWidth: 768  # Mobile breakpoint
              },
              chartOptions: {
                chart: {
                  height: 300  # Reduced height for mobile (from 450px)
                },
                yAxis: [
                  {
                    labels: {
                      enabled: false  # Hide left y-axis labels on mobile
                    }
                  },
                  {
                    labels: {
                      enabled: false  # Hide right y-axis labels on mobile
                    }
                  }
                ],
                legend: {
                  enabled: false  # Optional: also hide legend on mobile for more space
                },
                plotOptions: {
                  series: {
                    marker: {
                      radius: 3  # Smaller markers on mobile
                    },
                    lineWidth: 1  # Thinner lines on mobile
                  }
                }
              }
            }
          ]
        }
      }
    end
  end
end
