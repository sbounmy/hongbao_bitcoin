# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "html2canvas", to: "https://ga.jspm.io/npm:html2canvas@1.4.1/dist/html2canvas.esm.js" # @1.4.1
pin "jspdf", to: "https://ga.jspm.io/npm:jspdf@2.5.2/dist/jspdf.es.min.js" # @2.5.2

# Add html5-qrcode with ga.jspm.io
pin "qr-scanner", to: "https://ga.jspm.io/npm:qr-scanner@1.4.2/qr-scanner.min.js"
pin "qr-scanner-worker", to: "https://ga.jspm.io/npm:qr-scanner@1.4.2/qr-scanner-worker.min.js"

# jsPDF and its dependencies
pin "@babel/runtime/helpers/typeof", to: "https://ga.jspm.io/npm:@babel/runtime@7.24.0/helpers/typeof.js"
pin "@babel/runtime/helpers/asyncToGenerator", to: "https://ga.jspm.io/npm:@babel/runtime@7.24.0/helpers/asyncToGenerator.js"
pin "@babel/runtime/helpers/classCallCheck", to: "https://ga.jspm.io/npm:@babel/runtime@7.24.0/helpers/classCallCheck.js"
pin "@babel/runtime/helpers/createClass", to: "https://ga.jspm.io/npm:@babel/runtime@7.24.0/helpers/createClass.js"
pin "@babel/runtime/regenerator", to: "https://ga.jspm.io/npm:@babel/runtime@7.24.0/regenerator/index.js"
pin "fflate", to: "https://cdn.jsdelivr.net/npm/fflate@0.8.2/+esm"

# Chart.js and its dependencies
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.1/auto/auto.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
