# Bitcoin Hong Bao

###### [🌐 Live Demo](https://hongbaob.tc) · [💬 Discussions](https://github.com/sbounmy/hongbao/discussions) · [🤝 Contributing](CONTRIBUTING.md)


[![CI](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/ci.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/ci.yml)
[![Deploy](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/deploy.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/deploy.yml)
[![Playwright Tests](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/playwright.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/playwright.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Bitcoin Hong Bao is a modern web application that lets you create and print beautiful Bitcoin bills with QR codes, designed specifically for traditional red envelopes (Hong Bao 红包). Perfect for gifting Bitcoin during Chinese New Year or special occasions, our platform combines traditional customs with digital currency.

![Bitcoin Hong Bao Demo](/app/assets/images/readme/demo.gif)

## 🚀 Features

- **AI Design**: Create Bitcoin paper wallets optimized for red envelopes size
- **Offline mode**: All the keys are generated in the browser using [bitcoinlib-js](https://github.com/bitcoinjs/bitcoinjs-lib)
- **Top up**: Top-up the paper wallets with € via [Mt pelerin](https://developers.mtpelerin.com/integration-guides/web-integration) or public address via any wallet (Ledger, Trezor, Sparrow etc)
- **Verify Balance / Transfer funds**: Direcly from the Scan button on the homepage
## 🛠️ Quick Start

### Prerequisites

- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) (recommended)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Install

1. Clone and open in VS Code/Cursor:
```bash
git clone https://github.com/sbounmy/hongbao.git
cd hongbao
code .  # or `cursor .`
```

2. When prompted, click "Reopen in Container" - this will automatically:
   - Set up all dependencies
   - Configure the development environment
   ![Run dev container](/app/assets/images/readme/run-dev-container.jpg)

3. Setup the app
```bash
# Copy environment configuration
cp .env.example .env

# Set up credentials (choose one):
# Option 1: Request master.key from Stephane
# Option 2: Create your own from credentials.yml.example:
EDITOR="nano --wait" bin/rails credentials:edit

# Seed the database with some data from [seed.yml](db/seeds.rb.rb)
bin/rails db:seed

# Start the development server
bin/dev
```
3. Visit http://localhost:3001 to see your local instance!


## 💻 Development

### Local Development

```bash
bin/dev  # Start the development server
```

### Remote Development

When working with webhooks locally we recommend to create a  tunnel to your localhost:

```bash
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token {token}
```

[📚 Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)

## 🧪 Testing

We use RSpec for model,controller, service testing and Playwright for frontend testing.

### RSpec Tests
```bash
bin/rspec spec/
```

### Playwright Tests
```bash
npm install              # Install dependencies
npx playwright test     # Run tests headless
npx playwright test --ui # Run tests with UI
```

## 🔄 Recent Updates

TODO

## 💬 FAQ

<details>
<summary>How do I test emails in development?</summary>

Emails are caught by Letter Opener:
- Auto-preview in new tab
- Dashboard at http://localhost:3000/letter_opener
</details>

<details>
<summary>How do I add JavaScript dependencies?</summary>

Use ImportMaps with [JSPM](https://jspm.io/):
1. Visit [JSPM Generator](https://generator.jspm.io/)
2. Search and select package
3. Copy import URL
4. Add to `config/importmap.rb`
</details>

<details>
<summary>PDF issues in Chrome/Arc?</summary>

- Issue: "No enabled plugin supports this MIME type"
- Only affects localhost
- Solution: Use Safari for local PDF testing
- [Track Issue #39](https://github.com/sbounmy/hongbao_bitcoin/issues/39)
</details>

## 🤝 Contributing

We love your input! Check out our [Contributing Guidelines](CONTRIBUTING.md) for ways to get started.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.