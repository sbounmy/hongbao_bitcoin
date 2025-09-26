# Shopify Integration Setup

## 1. Configure Shopify Credentials

Add your Shopify store credentials:

```bash
rails credentials:edit
```

Add the following structure:

```yaml
shopify:
  shop_domain: your-store.myshopify.com
  access_token: shpat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 2. Get Your Access Token

### Option A: Create a Custom App (Recommended)

1. Go to your Shopify Admin
2. Navigate to Settings → Apps and sales channels
3. Click "Develop apps"
4. Click "Create an app"
5. Name it (e.g., "HongBao Integration")
6. In the Configuration tab, configure Admin API scopes:
   - `read_products`
   - `write_products` (if needed)
   - `read_orders`
7. Click "Install app"
8. Copy the Admin API access token (starts with `shpat_`)

### Option B: Create a Private App (Legacy)

Private apps are deprecated but still work if you have them enabled.

## 3. Test the Connection

```bash
# In Rails console
Shopify::Product.all

# Or test with rake task
rails shopify:test_connection  # (if we create this task)
```

## Usage

```ruby
# Fetch all products
products = Shopify::Product.all(limit: 50)

# In controllers
@shopify_products = Shopify::Product.all
```

## Architecture

The integration uses a clean domain-driven design:

```
app/services/shopify/
├── base.rb              # Base class with error handling
├── product.rb           # Product facade (Shopify::Product)
└── product/
    └── all.rb          # GraphQL query for fetching products
```

This provides a clean interface: `Shopify::Product.all` that internally uses GraphQL for efficient data fetching.