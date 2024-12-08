# Bitcoin Hong Bao

Create and print beautiful Bitcoin bills with QR codes to pack inside traditional red envelopes (Hong Bao 红包).

🌐 **Live Website**: [https://hongbaob.tc](https://hongbaob.tc)

## Dependencies

This project relies on a fork of [bitcoin-ruby](https://github.com/sbounmy/bitcoin-ruby) that supports mnemonic and openssl 3 for Bitcoin private/public key generation.

## Development

### Setup

```bash
# Install dependencies
bin/bundle install

# Setup database
bin/rails db:setup

# Start the server
bin/rails server
```

### Email Testing

In development, emails are caught by Letter Opener and displayed in your browser instead of being sent. This makes it easy to preview and debug email templates.

You can view sent emails in two ways:

1. **Automatic Preview**: When an email is sent (e.g., magic link), it automatically opens in a new browser tab

2. **Email Dashboard**: Visit http://localhost:3000/letter_opener to see all emails sent during your development session

Example of testing the magic link flow:
1. Click "Sign in" and enter your email
2. A new tab will open showing the email with the magic link
3. Click the link to complete the authentication

Note: This only works in development environment. In production, real emails will be sent.
