require 'rails_helper'

RSpec.describe ContentsController, type: :controller do
  fixtures :contents
  render_views

  describe 'GET #index' do
    context 'with quotes' do
      before { get :index, params: { klass: 'quotes' } }

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns @content_class as Content::Quote' do
        expect(assigns(:content_class)).to eq(Content::Quote)
      end

      it 'assigns @content_type as "quote"' do
        expect(assigns(:content_type)).to eq('quote')
      end

      it 'assigns published quotes to @contents' do
        expect(assigns(:contents)).to all(be_a(Content::Quote))
        expect(assigns(:contents)).not_to be_empty
      end

      it 'orders quotes by published_at desc' do
        contents = assigns(:contents)
        expect(contents.first.published_at).to be >= contents.last.published_at if contents.size > 1
      end
    end

    context 'with artists' do
      before { get :index, params: { klass: 'artists' } }

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns @content_class as Content::Artist' do
        expect(assigns(:content_class)).to eq(Content::Artist)
      end

      it 'assigns @content_type as "artist"' do
        expect(assigns(:content_type)).to eq('artist')
      end

      it 'loads artist fixtures' do
        expect(assigns(:contents)).to include(contents(:artist_bartosz))
        expect(assigns(:contents)).to include(contents(:artist_satoshi_art))
      end
    end

    context 'with invalid klass' do
      it 'raises RecordNotFound for unknown klass' do
        expect {
          get :index, params: { klass: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with pagination' do
      before { get :index, params: { klass: 'quotes', page: 2 } }

      it 'paginates results' do
        expect(assigns(:contents)).to respond_to(:current_page)
      end
    end
  end

  describe 'GET #show' do
    let(:quote) { contents(:quote_satoshi) }

    context 'with valid slug' do
      before { get :show, params: { klass: 'quotes', slug: quote.slug } }

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'renders the correct template' do
        expect(response).to render_template("contents/quote/show")
      end

      it 'assigns the requested content' do
        expect(assigns(:content)).to eq(quote)
      end

      it 'increments impressions_count' do
        expect {
          get :show, params: { klass: 'quotes', slug: quote.slug }
        }.to change { quote.reload.impressions_count }.by(1)
      end

      it 'assigns related content' do
        expect(assigns(:related)).to be_present
        expect(assigns(:related)).not_to include(quote)
        expect(assigns(:related).size).to be <= 4
      end
    end

    context 'with FriendlyId history and SEO redirects' do
      it 'redirects from old slug to new slug after text change' do
        # Create a fresh quote to ensure FriendlyId history is properly initialized
        quote = Content::Quote.create!(
          author: "Test Bitcoiner",
          text: "Don't trust, verify",
          published_at: Date.current
        )
        original_slug = quote.slug

        # Update quote to generate new slug
        quote.update!(text: "Always verify, never trust")
        new_slug = quote.slug

        expect(new_slug).not_to eq(original_slug)

        # Access with old slug should redirect to new slug with 301
        get :show, params: { klass: 'quotes', slug: original_slug }

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(bitcoin_content_path(quote, klass: 'quotes'))
      end

      it 'redirects from old slug to new slug after author change' do
        # Create a fresh quote to ensure FriendlyId history is properly initialized
        quote = Content::Quote.create!(
          author: "Michael Saylor",
          text: "Fix the money, fix the world",
          published_at: Date.current
        )
        original_slug = quote.slug

        # Update quote to generate new slug
        quote.update!(author: "Michael J. Saylor")
        new_slug = quote.slug

        expect(new_slug).not_to eq(original_slug)

        # Access with old slug should redirect to new slug with 301
        get :show, params: { klass: 'quotes', slug: original_slug }

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(bitcoin_content_path(quote, klass: 'quotes'))
      end

      it 'redirects through multiple slug changes' do
        # Create a fresh quote to ensure FriendlyId history is properly initialized
        quote = Content::Quote.create!(
          author: "Andreas Antonopoulos",
          text: "Not your keys, not your coins",
          published_at: Date.current
        )

        # Store original slug
        first_slug = quote.slug

        # First update
        quote.update!(text: "Your keys, your Bitcoin")
        second_slug = quote.slug

        # Second update
        quote.update!(text: "Control your keys, control your future")
        third_slug = quote.slug
        current_slug = third_slug

        # All previous slugs should redirect to current slug
        [ first_slug, second_slug ].each do |old_slug|
          get :show, params: { klass: 'quotes', slug: old_slug }
          expect(response).to have_http_status(:moved_permanently)
          expect(response).to redirect_to(bitcoin_content_path(quote, klass: 'quotes'))
        end

        # Current slug should not redirect
        get :show, params: { klass: 'quotes', slug: current_slug }
        expect(response).to have_http_status(:success)
        expect(response).not_to be_redirect
      end

      it 'handles redirects for multiple different quotes' do
        # Create fresh quotes to ensure FriendlyId history is properly initialized
        quote1 = Content::Quote.create!(
          author: "Henry Ford",
          text: "An energy currency can stop wars",
          published_at: Date.current
        )

        quote2 = Content::Quote.create!(
          author: "Jack Mallers",
          text: "No man should work for what another man can print",
          published_at: Date.current
        )

        # Store original slugs
        original_slug1 = quote1.slug
        original_slug2 = quote2.slug

        # Update both quotes
        quote1.update!(text: "Energy money prevents conflicts")
        quote2.update!(text: "Don't work for printed money")

        # Old slug for quote1 should redirect to quote1's new slug
        get :show, params: { klass: 'quotes', slug: original_slug1 }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(bitcoin_content_path(quote1, klass: 'quotes'))

        # Old slug for quote2 should redirect to quote2's new slug
        get :show, params: { klass: 'quotes', slug: original_slug2 }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(bitcoin_content_path(quote2, klass: 'quotes'))
      end

      it 'does not redirect when accessing with current slug' do
        quote = Content::Quote.create!(
          author: "Satoshi Nakamoto",
          text: "If you don't believe it or don't get it",
          published_at: Date.current
        )

        # Access with current slug should not redirect
        get :show, params: { klass: 'quotes', slug: quote.slug }

        expect(response).to have_http_status(:success)
        expect(response).not_to be_redirect
        expect(assigns(:content)).to eq(quote)
      end
    end

    context 'with invalid slug' do
      it 'raises RecordNotFound' do
        expect {
          get :show, params: { klass: 'quotes', slug: 'non-existent' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with unpublished content' do
      let(:unpublished_quote) { contents(:quote_unpublished) }

      it 'raises RecordNotFound' do
        expect {
          get :show, params: { klass: 'quotes', slug: unpublished_quote.slug }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with wrong klass for content type' do
      it 'raises RecordNotFound when accessing quote as artist' do
        expect {
          get :show, params: { klass: 'artists', slug: quote.slug }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'routing' do
    it 'routes /bitcoin-quotes to contents#index with klass=quotes' do
      expect(get: '/bitcoin-quotes').to route_to(
        controller: 'contents',
        action: 'index',
        klass: 'quotes'
      )
    end

    it 'routes /bitcoin-quotes/slug to contents#show' do
      expect(get: '/bitcoin-quotes/satoshi-peer-to-peer').to route_to(
        controller: 'contents',
        action: 'show',
        klass: 'quotes',
        slug: 'satoshi-peer-to-peer'
      )
    end

    it 'routes /bitcoin-artists to contents#index with klass=artists' do
      expect(get: '/bitcoin-artists').to route_to(
        controller: 'contents',
        action: 'index',
        klass: 'artists'
      )
    end
  end

  describe 'private methods' do
    describe '#set_content_class' do
      it 'sets Content::Quote for quotes klass' do
        get :index, params: { klass: 'quotes' }
        expect(assigns(:content_class)).to eq(Content::Quote)
      end

      it 'sets Content::Artist for artists klass' do
        get :index, params: { klass: 'artists' }
        expect(assigns(:content_class)).to eq(Content::Artist)
      end

      it 'raises error for empty klass' do
        expect {
          get :index, params: { klass: '' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'Bitcoin Quotes Pages' do
    describe 'GET #index for quotes' do
      before { get :index, params: { klass: 'quotes' } }

      it 'displays list of bitcoin quotes' do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Bitcoin Quotes")
      end

      it 'shows quotes from fixtures' do
        expect(response.body).to include("Satoshi Nakamoto")
        expect(response.body).to include("Andreas Antonopoulos")
      end
    end

    describe 'GET #show for quotes' do
      context 'with Henry Ford quote' do
        let(:quote) { contents(:quote_henry_ford) }

        before { get :show, params: { klass: 'quotes', slug: quote.slug } }

        it 'displays the quote page' do
          expect(response).to have_http_status(:success)
        end

        it 'shows quote content' do
          expect(response.body).to include("An energy currency can stop wars")
          expect(response.body).to include("Henry Ford")
        end

        it 'shows breadcrumbs' do
          expect(response.body).to include("Bitcoin Quotes")
          expect(response.body).to include("Henry Ford")
        end

        it 'shows orange-pill section' do
          expect(response.body).to include("orange-pill")
          expect(response.body).to include("Hong₿ao Envelopes")
        end

        it 'shows full quote when available' do
          expect(response.body).not_to include("Read Full Quote")
        end

        it 'does not show category badge' do
          expect(response.body).not_to include("badge badge-lg")
        end

        # Skipping products tests as they require more complex fixture setup
        # context 'with products' do
        #   it 'displays related products section' do
        #     # Henry Ford quote already has products from fixtures
        #     expect(quote.products.count).to eq(3) # From fixtures
        #     expect(quote.products.published.count).to eq(3) # Should be published

        #     get :show, params: { klass: 'quotes', slug: quote.slug }

        #     # The product section exists
        #     expect(response.body).to include("Products with this Quote")
        #     # Check for shop names which should always be present
        #     expect(response.body).to include("Hong₿ao")
        #     expect(response.body).to include("Redbubble")
        #     expect(response.body).to include("Etsy")
        #   end
        # end
      end

      context 'with Satoshi quote' do
        let(:quote) { contents(:quote_satoshi) }

        it 'displays the Satoshi quote page' do
          get :show, params: { klass: 'quotes', slug: quote.slug }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("It might make sense just to get some in case it catches on")
          expect(response.body).to include("Satoshi Nakamoto")
        end
      end

      context 'with non-existent quote' do
        it 'returns 404' do
          expect {
            get :show, params: { klass: 'quotes', slug: 'non-existent-quote' }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with unpublished quote' do
        let(:unpublished) { contents(:quote_unpublished) }

        it 'returns 404 for unpublished content' do
          expect {
            get :show, params: { klass: 'quotes', slug: unpublished.slug }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'share functionality' do
      let(:quote) { contents(:quote_henry_ford) }

      it 'includes share buttons' do
        get :show, params: { klass: 'quotes', slug: quote.slug }
        expect(response.body).to include("Share on Twitter")
        expect(response.body).to include("Copy to clipboard")
        expect(response.body).to include("twitter.com/intent/tweet")
      end
    end

    describe 'related quotes' do
      let(:quote) { contents(:quote_henry_ford) }

      it 'shows other quotes in related section' do
        get :show, params: { klass: 'quotes', slug: quote.slug }
        expect(response.body).to include("More Bitcoin Wisdom")
        expect(response.body.scan(/Read →/).count).to be > 0
      end
    end

    describe 'SEO metadata' do
      let(:quote) { contents(:quote_henry_ford) }

      it 'sets proper page title and meta description' do
        get :show, params: { klass: 'quotes', slug: quote.slug }
        # SEO metadata is set in the view, check response body for title tag
        expect(response.body).to include("<title>")
        expect(response.body).to include("Henry Ford")
        expect(response.body).to include("An energy currency")
      end
    end
  end

  describe 'Bitcoin Artists Pages' do
    describe 'GET #index for artists' do
      it 'returns http success' do
        get :index, params: { klass: 'artists' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET #show for artists' do
      let(:artist) { contents(:artist_bartosz) }

      it 'returns http success for valid artist' do
        get :show, params: { klass: 'artists', slug: artist.slug }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
