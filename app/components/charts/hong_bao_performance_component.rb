# frozen_string_literal: true

module Charts
  class HongBaoPerformanceComponent < ApplicationComponent
    attr_reader :hong_bao

    def initialize(hong_bao:, height: 300)
      @hong_bao = hong_bao
      @height = height
      @service = HongBaoPerformanceService.new(hong_bao)
      @data = @service.call
    end

    def metadata
      @data[:metadata]
    end

    private

    def chart_config
      {
        chart: {
          type: "area",
          height: @height,
          backgroundColor: "transparent"
        },
        title: {
          text: nil
        },
        credits: {
          enabled: false
        },
        xAxis: {
          type: "datetime",
          lineColor: "rgba(255,255,255,0.1)",
          tickColor: "rgba(255,255,255,0.1)",
          labels: {
            style: {
              color: "rgba(255,255,255,0.7)"
            }
          }
        },
        yAxis: [
          {
            title: {
              text: "Value (USD)",
              style: {
                color: "rgba(255,255,255,0.7)"
              }
            },
            gridLineColor: "rgba(255,255,255,0.1)",
            labels: {
              style: {
                color: "rgba(255,255,255,0.7)"
              },
              formatter: nil  # Will use default currency format
            }
          },
          {
            title: {
              text: "BTC Price",
              style: {
                color: "rgba(255,255,255,0.5)"
              }
            },
            opposite: true,
            gridLineColor: "transparent",
            labels: {
              style: {
                color: "rgba(255,255,255,0.5)"
              }
            }
          }
        ],
        tooltip: {
          shared: true,
          crosshairs: true,
          backgroundColor: "rgba(0,0,0,0.95)",
          borderColor: "#FFB636",
          borderRadius: 12,
          borderWidth: 2,
          padding: 12,
          shadow: true,
          useHTML: false,
          style: {
            color: "white",
            fontSize: "13px"
          },
          valuePrefix: "$",
          valueDecimals: 2
        },
        plotOptions: {
          area: {
            fillColor: {
              linearGradient: {
                x1: 0,
                y1: 0,
                x2: 0,
                y2: 1
              },
              stops: [
                [ 0, "rgba(255, 182, 54, 0.3)" ],
                [ 1, "rgba(255, 182, 54, 0)" ]
              ]
            },
            lineColor: "#FFB636",
            lineWidth: 2,
            marker: {
              enabled: false
            }
          },
          line: {
            marker: {
              enabled: false
            }
          }
        },
        series: [
          {
            name: "Hong Bao Value",
            data: @data[:hong_bao_value],
            yAxis: 0,
            type: "area",
            color: "#FFB636",
            tooltip: {
              valuePrefix: "$",
              valueDecimals: 2
            }
          },
          {
            name: "Bitcoin Price",
            data: @data[:btc_price],
            yAxis: 1,
            type: "line",
            color: "rgba(255,255,255,0.5)",
            lineWidth: 1,
            marker: {
              enabled: false
            },
            tooltip: {
              valuePrefix: "$",
              valueDecimals: 0,
              valueSuffix: ""
            }
          }
        ],
        responsive: {
          rules: [
            {
              condition: {
                maxWidth: 768
              },
              chartOptions: {
                chart: {
                  height: 250
                },
                yAxis: [
                  {
                    title: {
                      text: nil
                    }
                  },
                  {
                    title: {
                      text: nil
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end
end
