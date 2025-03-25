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

## ⚡ Tech Stack

<table>
  <tr>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/ruby/ruby-original.svg" width="48" height="48" alt="Ruby" />
      <br>Ruby 3.2
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-original-wordmark.svg" width="48" height="48" alt="Rails" />
      <br>Rails 8
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/sqlite/sqlite-original.svg" width="48" height="48" alt="SQLite" />
      <br>SQLite
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/tailwindcss/tailwindcss-original.svg" width="48" height="48" alt="Tailwind" />
      <br>Tailwind
    </td>
  </tr>
  <tr>
    <td align="center" width="96">
      <img src="app/assets/images/readme/hotwired.svg" width="48" height="48" alt="Hotwire" />
      <br>Hotwire
    </td>
    <td align="center" width="96">
      <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/docker/docker-original.svg" width="48" height="48" alt="Docker" />
      <br>Docker
    </td>
    <td align="center" width="96">
      <img src="https://playwright.dev/img/playwright-logo.svg" width="48" height="48" alt="Playwright" />
      <br>Playwright
    </td>
    <td align="center" width="96">
      <img src="https://rspec.info/images/logo.png" width="48" height="48" alt="RSpec" />
      <br>RSpec
    </td>
  </tr>
</table>

### Key Dependencies
- 🔒 **[bitcoinjs-lib](https://github.com/bitcoinjs/bitcoinjs-lib)** - Bitcoin JavaScript library
- 💳 **[Mt Pelerin](https://www.mtpelerin.com/)** - Fiat to crypto integration
- 🎨 **[Stable Diffusion](https://stability.ai/)** - AI image generation
- 🧪 **[Playwright](https://playwright.dev/)** - E2E testing
- 📦 **[SolidQueue](https://github.com/rails/solid_queue)** - Background jobs

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

#### Core maintainer
1. Take an issue
2. Create a branch from issue
3. Create the PR

![create-branch-from-issue](/app/assets/images/readme/create-branch-pull-request.jpg)

#### Others
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.