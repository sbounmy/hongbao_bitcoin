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
          height: (@height.gsub("px", "").to_i + 100)  # Add 100px for navigator
        },
        rangeSelector: {
          selected: 5,  # Default to "All"
          inputEnabled: false,  # Disable date inputs, use buttons instead
          buttonTheme: {
            fill: "none",
            stroke: "#e5e7eb",
            "stroke-width": 1,
            r: 4,
            padding: 8,
            style: {
              color: "#374151",
              fontWeight: "500"
            },
            states: {
              hover: {
                fill: "#f3f4f6",
                style: {
                  color: "#111827"
                }
              },
              select: {
                fill: "#10b981",
                stroke: "#10b981",
                style: {
                  color: "#ffffff",
                  fontWeight: "600"
                }
              }
            }
          },
          buttons: [
            {
              type: "month",
              count: 1,
              text: "1m"
            },
            {
              type: "month",
              count: 3,
              text: "3m"
            },
            {
              type: "month",
              count: 6,
              text: "6m"
            },
            {
              type: "ytd",
              text: "YTD"
            },
            {
              type: "year",
              count: 1,
              text: "1y"
            },
            {
              type: "all",
              text: "All"
            }
          ]
        },
        navigator: {
          enabled: true,
          height: 40,
          maskFill: "rgba(247, 147, 26, 0.2)"  # Bitcoin orange with 20% opacity
        },
        scrollbar: {
          enabled: false
        },
        xAxis: {
          type: "datetime",
          dateTimeLabelFormats: {
            millisecond: "%H:%M:%S.%L",
            second: "%H:%M:%S",
            minute: "%H:%M",
            hour: "%H:%M",
            day: "%e %b",
            week: "%e %b",
            month: "%b '%y",
            year: "%Y"
          }
        },
        yAxis: [
          {
            title: false,
            labels: {
              enabled: false  # Hide left axis labels
            }
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
                  height: 350  # Increased from 300px to accommodate navigator
                },
                legend: {
                  enabled: false  # Hide legend on mobile for more space
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
