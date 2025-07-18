# Hong₿ao Bitcoin

###### [🌐 Live Demo](https://hongbaob.tc) · [💬 Discussions](https://github.com/sbounmy/hongbao_bitcoin/discussions) · [🤝 Contributing](CONTRIBUTING.md)


[![Spec](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/spec.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/spec.yml)
[![E2E](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/e2e.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/e2e.yml)
[![Deploy](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/deploy.yml/badge.svg)](https://github.com/sbounmy/hongbao_bitcoin/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Hong₿ao is an open-source browser-based Bitcoin paper wallet generator. It is specifically designed for traditional red envelopes (红包, hóngbāo). Perfect for introducing friends and family to Bitcoin during Chinese New Year, weddings or any gift-giving occasion.

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
      <br><a href="https://www.ruby-lang.org/">Ruby 3.2</a>
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-original-wordmark.svg" width="48" height="48" alt="Rails" />
      <br><a href="https://rubyonrails.org/">Rails 8</a>
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/sqlite/sqlite-original.svg" width="48" height="48" alt="SQLite" />
      <br><a href="https://www.sqlite.org/">SQLite</a>
    </td>
    <td align="center" width="96">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/tailwindcss/tailwindcss-original.svg" width="48" height="48" alt="Tailwind" />
      <br><a href="https://tailwindcss.com/">Tailwind</a>
    </td>
  </tr>
  <tr>
    <td align="center" width="96">
      <img src="app/assets/images/readme/hotwired.svg" width="48" height="48" alt="Hotwire" />
      <br><a href="https://hotwired.dev/">Hotwire</a>
    </td>
    <td align="center" width="96">
      <img src="app/assets/images/readme/mise.jpeg" width="48" height="48" alt="mise" />
      <br><a href="https://mise.jdx.dev/">mise</a>
    </td>
    <td align="center" width="96">
      <img src="https://playwright.dev/img/playwright-logo.svg" width="48" height="48" alt="Playwright" />
      <br><a href="https://playwright.dev/">Playwright</a>
    </td>
    <td align="center" width="96">
      <img src="https://rspec.info/images/logo.png" width="48" height="48" alt="RSpec" />
      <br><a href="https://rspec.info/">RSpec</a>
    </td>
  </tr>
</table>

### Key Dependencies
- 🔒 **[bitcoinjs-lib](https://github.com/bitcoinjs/bitcoinjs-lib)** - Bitcoin JavaScript library
- 💳 **[Mt Pelerin](https://www.mtpelerin.com/)** - Fiat to crypto integration
- 🎨 **[ChatGPT (gpt-image-1)](https://platform.openai.com/docs/guides/image-generation?image-generation-model=gpt-image-1)** - AI image generation
- 🧪 **[Playwright](https://playwright.dev/)** - E2E testing
- 📦 **[SolidQueue](https://github.com/rails/solid_queue)** - Background jobs

## 🛠️ Quick Start

### Prerequisites

- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) (recommended)
- [mise](https://mise.jdx.dev) - Dev env manager (like docker without the pain)
- libvips - Image processing library
  ```bash
  # macOS
  brew install vips

  # Debian/Ubuntu
  sudo apt-get update && sudo apt install libvips-dev
  ```

### Install

1. Install mise:
```bash
# macOS with Homebrew
brew install mise

# Linux/macOS without Homebrew
curl https://mise.run | sh
```

2. Activate mise in your shell:
```bash
# For bash
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Refresh
source ~/.bashrc

```

3. Clone and setup the project:
```bash
git clone https://github.com/sbounmy/hongbao.git
git submodule update --init --recursive
cd hongbao
# Install Ruby and Node.js from mise.toml
mise install

# Install dependencies
bundle install
yarn install

# Copy environment configuration
cp .env.example .env

# Set up credentials (choose one):
# Option 1: Request master.key from Stephane
# Option 2: Create your own from credentials.yml.example:
EDITOR="nano --wait" bin/rails credentials:edit

# Setup database
bin/rails db:setup

# Start the development server
bin/dev
```

3. Setup the app:
```bash
# Copy environment configuration
cp .env.example .env

# Set up credentials (choose one):
# Option 1: Request master.key from Stephane
# Option 2: Create your own from credentials.yml.example:
EDITOR="nano --wait" bin/rails credentials:edit

# Seed the database
bin/rails db:seed

# Start the development server
bin/dev
```

4. Visit http://localhost:3001 to see your local instance!


## 💻 Development

### Local Development

```bash
bin/dev  # Start the development server
```

### Remote Development

When working with webhooks locally we recommend to create a  tunnel to your localhost:

```bash
# MacOS
docker brew install cloudflared &&
sudo cloudflared service install {token}


# Debian / linux
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&
sudo dpkg -i cloudflared.deb &&
sudo cloudflared service install {token}
```

[📚 Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)

## 🧪 Testing

We use RSpec for model,controller, service testing and Playwright for frontend testing.

### RSpec Tests
```bash
bin/rspec spec/
```

### Playwright E2E Tests

To run the end-to-end test suite, use the `bin/e2e` script:

```bash
# Run all tests with 4 parallel workers (default)
bin/e2e

# Run a specific test file
bin/e2e e2e/playwright/e2e/visual_editor.spec.js

# Run all tests with a specific number of parallel workers
bin/e2e --parallel[8]

# Combine both options
bin/e2e --parallel[2] e2e/playwright/e2e/visual_editor.spec.js
```

For debugging, you can still use the standard Playwright commands:
```bash
npx playwright test --ui # Run tests with UI
```

If you use VSCode / Cursor you can install [Playwright Test for VSCode](https://marketplace.cursorapi.com/items?itemName=ms-playwright.playwright) extension

Then you can
- Select the Testing Tab (1)
- Run test from the testing panel (2)
- Run test from the source code (3)
- Automatically run test when changes are detected (4)

![playwright-vscode-cursor-testing](/app/assets/images/readme/playwright-vscode-cursor-extension.jpg)

## 🔄 Recent Updates

TODO

## 💬 FAQ

<details>
<summary>How do I test emails in development?</summary>

Emails are caught by Letter Opener:
- Auto-preview in new tab
- Dashboard at http://localhost:3001/letter_opener
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

<details>
<summary>StripeCLI Expired API Key provided<summary>

- open ~/.config/stripe/config.toml https://docs.stripe.com/stripe-cli/keys#where-keys-are-stored
- replace test_mode_api_key by stripe.secret_key in `rails credentials:show`
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