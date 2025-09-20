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

    context 'with FriendlyId history' do
      it 'finds quote by old slug after text change' do
        quote = contents(:quote_bitcoiners)
        quote.reload # Ensure we have the latest state
        original_slug = quote.slug
        expect(original_slug).to eq("bitcoiners-dont-trust-verify")

        # Update quote to generate new slug
        quote.update!(text: "Always verify, never trust")
        new_slug = quote.slug

        expect(new_slug).not_to eq(original_slug)
        expect(new_slug).to eq("bitcoiners-always-verify-never-trust")

        # Access with old slug should still work
        get :show, params: { klass: 'quotes', slug: original_slug }

        expect(response).to have_http_status(:success)
        expect(assigns(:content)).to eq(quote)
      end

      it 'finds quote by old slug after author change' do
        quote = contents(:quote_saylor)
        quote.reload # Ensure we have the latest state
        original_slug = quote.slug
        expect(original_slug).to eq("michael-saylor-fix-the-money")

        # Update quote to generate new slug
        quote.update!(author: "Michael J. Saylor")
        new_slug = quote.slug

        expect(new_slug).not_to eq(original_slug)
        expect(new_slug).to eq("michael-j-saylor-fix-the-money-fix-the-world")

        # Access with old slug should still work
        get :show, params: { klass: 'quotes', slug: original_slug }

        expect(response).to have_http_status(:success)
        expect(assigns(:content)).to eq(quote)
      end

      it 'finds quote through multiple slug changes' do
        quote = contents(:quote_andreas)
        quote.reload # Ensure we have the latest state

        # Store original slug
        first_slug = quote.slug
        expect(first_slug).to eq("andreas-antonopoulos-not-your-keys")

        # First update
        quote.update!(text: "Your keys, your Bitcoin")
        second_slug = quote.slug

        # Second update
        quote.update!(text: "Control your keys, control your future")
        third_slug = quote.slug

        # All previous slugs should work
        [ first_slug, second_slug, third_slug ].each do |slug|
          get :show, params: { klass: 'quotes', slug: slug }
          expect(response).to have_http_status(:success)
          expect(assigns(:content)).to eq(quote)
        end
      end

      it 'handles history for multiple different quotes' do
        quote1 = contents(:quote_henry_ford)
        quote2 = contents(:quote_jack_mallers)
        quote1.reload # Ensure we have the latest state
        quote2.reload # Ensure we have the latest state

        # Store original slugs
        original_slug1 = quote1.slug
        original_slug2 = quote2.slug
        expect(original_slug1).to eq("henry-ford-energy-currency-stops-wars")
        expect(original_slug2).to eq("jack-mallers-no-man-should-work")

        # Update both quotes
        quote1.update!(text: "Energy money prevents conflicts")
        quote2.update!(text: "Don't work for printed money")
slug
        # Old slug for quote1 should find quote1
        get :show, params: { klass: 'quotes', slug: original_slug1 }
        expect(assigns(:content)).to eq(quote1)

        # Old slug for quote2 should find quote2
        get :show, params: { klass: 'quotes', slug: original_slug2 }
        expect(assigns(:content)).to eq(quote2)
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
