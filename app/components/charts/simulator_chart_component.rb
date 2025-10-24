# frozen_string_literal: true

module Charts
  class SimulatorChartComponent < ApplicationComponent
    attr_reader :event_hong_baos

    def initialize(event_hong_baos:, height: "450px")
      @event_hong_baos = event_hong_baos
      @height = height
      # Generate chart data using our simulator service
      simulator_service = BitcoinGiftingSimulatorService.new(
        years: calculate_years_range,
        average_gift: calculate_average_gift,
        events: extract_event_types
      )
      # We already have the event_hong_baos, just need the chart data
      @data = simulator_service.send(:generate_chart_data, event_hong_baos)
    end

    private

    def height
      @height
    end

    def calculate_years_range
      return 1 unless event_hong_baos.any?
      oldest_year = event_hong_baos.map { |hb| hb.gifted_at.year }.min
      Date.current.year - oldest_year + 1
    end

    def calculate_average_gift
      return 100 unless event_hong_baos.any?
      (event_hong_baos.sum(&:initial_usd) / event_hong_baos.size.to_f).round(2)
    end

    def extract_event_types
      event_hong_baos.map(&:event_type).uniq
    end

    def chart_config
      {
        chart: {
          type: "line",
          height: @height.gsub("px", "").to_i
        },
        title: {
          text: "Bitcoin Gifting Portfolio Over Time",
          style: {
            fontSize: "18px",
            fontWeight: "bold"
          }
        },
        xAxis: {
          type: "datetime",
          title: {
            text: "Date"
          }
        },
        yAxis: [
          {
            title: {
              text: "Portfolio Value (USD)",
              style: {
                color: "#10b981"
              }
            },
            labels: {
              format: "${value:,.0f}",
              style: {
                color: "#10b981"
              }
            }
          },
          {
            title: {
              text: "Bitcoin Price (USD)",
              style: {
                color: "#f7931a"
              }
            },
            labels: {
              format: "${value:,.0f}",
              style: {
                color: "#f7931a"
              }
            },
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
          padding: 0,
          formatter: nil  # We'll use pointFormatter for custom tooltips
        },
        plotOptions: {
          series: {
            turboThreshold: 0,  # Disable threshold to handle large datasets
            point: {
              events: {
                mouseOver: nil  # We'll handle this with formatter
              }
            }
          },
          line: {
            marker: {
              enabled: false  # Disable by default, individual points will override
            }
          },
          area: {
            fillOpacity: 0.2,
            marker: { enabled: false }
          },
          scatter: {
            marker: {
              enabled: true,
              radius: 8,
              states: {
                hover: {
                  enabled: true,
                  radius: 10
                }
              }
            }
          }
        },
        legend: {
          enabled: true,
          layout: "horizontal",
          align: "center",
          verticalAlign: "bottom"
        },
        series: [
          {
            name: "Bitcoin Price",
            data: @data[:btc_prices_with_markers],
            type: "line",
            yAxis: 1,
            color: "#f7931a",
            marker: { enabled: false },
            lineWidth: 2,
            zIndex: 1
          },
          {
            name: "Gift worth",
            data: @data[:portfolio],
            type: "area",
            yAxis: 0,
            color: "#10b981",
            fillOpacity: 0.2,
            lineWidth: 3,
            zIndex: 2
          },
          {
            name: "Gift spFent",
            data: @data[:net_deposits],
            type: "line",
            yAxis: 0,
            color: "#991b1b",
            dashStyle: "LongDash",
            lineWidth: 2,
            zIndex: 1
          },
          {
            name: "Gift Events",
            data: event_markers_data.map do |point|
              {
                x: point[:x],
                y: point[:y],
                marker: {
                  enabled: true,
                  radius: 8,
                  fillColor: point[:marker][:fillColor] || "#f7931a",
                  lineWidth: 2,
                  lineColor: "#FFFFFF",
                  symbol: "circle"
                },
                extraData: [ point ]  # Wrap in array for tooltip renderer
              }
            end,
            type: "scatter",
            yAxis: 1,
            color: "#f7931a",
            tooltip: {
              pointFormatter: nil  # Will use custom formatter
            },
            zIndex: 3,
            showInLegend: true
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
                  height: 350  # Reduced height for mobile
                },
                title: {
                  style: {
                    fontSize: "14px"
                  }
                },
                yAxis: [
                  {
                    labels: {
                      enabled: false  # Hide left y-axis labels on mobile
                    },
                    title: {
                      text: nil
                    }
                  },
                  {
                    labels: {
                      enabled: false  # Hide right y-axis labels on mobile
                    },
                    title: {
                      text: nil
                    }
                  }
                ],
                legend: {
                  enabled: false  # Hide legend on mobile for more space
                }
              }
            }
          ]
        }
      }
    end

    def event_markers_data
      @data[:event_markers] || []
    end
  end
end
