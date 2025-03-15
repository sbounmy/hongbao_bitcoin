# Bitcoin Hong Bao

[![CI](https://github.com/username/hongbao/actions/workflows/ci.yml/badge.svg)](https://github.com/username/hongbao/actions/workflows/ci.yml)
[![Deploy](https://github.com/username/hongbao/actions/workflows/deploy.yml/badge.svg)](https://github.com/username/hongbao/actions/workflows/deploy.yml)

Create and print beautiful Bitcoin bills with QR codes to pack inside traditional red envelopes (Hong Bao 红包).

🌐 **Live Website**: [https://hongbaob.tc](https://hongbaob.tc)

## Preview

![Bitcoin Hong Bao Demo](/app/assets/images/readme/demo.gif)

## Development

```bash
# Install dependencies
bin/bundle install

# Setup credentials
# The credentials.yml.enc file is encrypted and can't be directly edited
# Use Rails credentials editor to set up your credentials:
EDITOR="nano --wait" bin/rails credentials:edit

# When the editor opens, refer to config/credentials.yml.example
# for the required structure and keys
# Note: Make sure to keep your `master.key` file secure and never commit it to version control.

# Setup database
bin/rails db:setup

# Start the server
bin/rails server
```

Tunnel to local server

https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/

```bash
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token {token}

```

## Testing

### Install
```bash
npx install
```

### Run tests
```bash
# make sure bin/dev is running before
npx playwright test --ui ## UI MODE
npx playwright test ## Headless MODE
```



### Run in terminal
```bash
bin/rails test
```


## FAQ


<details>
<summary>How do I test emails in development?</summary>

Emails are caught by Letter Opener and displayed in your browser:
- Automatic Preview: Opens in new tab when email is sent
- Email Dashboard: Visit http://localhost:3000/letter_opener
</details>

<details>
<summary>How do I add JavaScript dependencies?</summary>

We use ImportMaps with [JSPM](https://jspm.io/):
1. Visit [JSPM Generator](https://generator.jspm.io/)
2. Search and select your package
3. Copy the generated import URL
4. Add to `config/importmap.rb`
</details>

<details>
<summary>Arc/Chrome: PDF iframe blob not displaying with error `No enabled plugin supports this MIME type`</summary>

- Chrome shows "No enabled plugin supports this MIME type"
- Only affects localhost environment
- Workaround: Use Safari for local PDF testing
- [Issue #39](https://github.com/sbounmy/hongbao_bitcoin/issues/39)
</details>