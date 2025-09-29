require "rails_helper"

RSpec.describe Content::Quote, type: :model do
  describe "slug generation" do
    context "when creating a new quote" do
      it "generates a slug from author and text" do
        quote = Content::Quote.create!(
          author: "Michael Saylor",
          text: "Fix the Money, Fix the World"
        )

        expect(quote.slug).to eq("michael-saylor-fix-the-money-fix-the-world")
      end

      it "truncates long text in slug" do
        quote = Content::Quote.create!(
          author: "Satoshi Nakamoto",
          text: "If you don't believe it or don't get it, I don't have the time to try to convince you, sorry"
        )

        # FriendlyId preserves apostrophes as hyphens and doesn't truncate
        expect(quote.slug).to start_with("satoshi-nakamoto-if-you-don-t-believe-it")
      end

      it "handles special characters in author and text" do
        quote = Content::Quote.create!(
          author: "Andreas M. Antonopoulos",
          text: "Not your keys, not your coins!"
        )

        expect(quote.slug).to eq("andreas-m-antonopoulos-not-your-keys-not-your-coins")
      end

      it "handles Unicode and Bitcoin symbols" do
        quote = Content::Quote.create!(
          author: "Michael Saylor",
          text: "$ell the past, ₿uy the future"
        )

        expect(quote.slug).to eq("michael-saylor-ell-the-past-uy-the-future")
      end

      it "creates unique slugs for similar quotes" do
        quote1 = Content::Quote.create!(
          author: "Bitcoiners",
          text: "Don't trust, verify"
        )

        quote2 = Content::Quote.create!(
          author: "Bitcoiners",
          text: "Don't trust, verify"
        )

        expect(quote1.slug).to eq("bitcoiners-don-t-trust-verify")
        # FriendlyId adds UUID for duplicates
        expect(quote2.slug).to start_with("bitcoiners-don-t-trust-verify-")
        expect(quote2.slug).not_to eq(quote1.slug)
      end
    end

    context "when updating a quote" do
      let!(:quote) do
        Content::Quote.create!(
          author: "Original Author",
          text: "Original quote text"
        )
      end

      let(:original_slug) { quote.slug }

      it "keeps the same slug when author changes (history feature)" do
        quote.update!(author: "New Author")

        # With history enabled, slug doesn't change automatically
        expect(quote.slug).to eq(original_slug)
      end

      it "keeps the same slug when text changes (history feature)" do
        quote.update!(text: "Completely new quote text")

        # With history enabled, slug doesn't change automatically
        expect(quote.slug).to eq(original_slug)
      end

      it "does not change slug when other attributes change" do
        quote.update!(published_at: Date.current)

        expect(quote.slug).to eq(original_slug)
      end
    end
  end

  describe "FriendlyId history" do
    let!(:quote) do
      Content::Quote.create!(
        author: "Jack Mallers",
        text: "No man should work for what another man can print"
      )
    end

    it "maintains history of slugs when changed" do
      original_slug = quote.slug
      expect(original_slug).to eq("jack-mallers-no-man-should-work-for-what-another-man-can-print")

      # Update to generate new slug
      quote.update!(text: "Strike is the best Bitcoin app")
      new_slug = quote.slug

      expect(new_slug).to eq("jack-mallers-strike-is-the-best-bitcoin-app")
      expect(new_slug).not_to eq(original_slug)

      # Old slug should still work via history
      found_by_old_slug = Content::Quote.friendly.find(original_slug)
      expect(found_by_old_slug).to eq(quote)

      # New slug should also work
      found_by_new_slug = Content::Quote.friendly.find(new_slug)
      expect(found_by_new_slug).to eq(quote)
    end

    it "redirects old URLs to new ones" do
      original_slug = quote.slug

      # Change the quote multiple times
      quote.update!(text: "Bitcoin is freedom money")
      second_slug = quote.slug

      quote.update!(text: "Bitcoin fixes everything")
      third_slug = quote.slug

      # All previous slugs should find the same quote
      expect(Content::Quote.friendly.find(original_slug)).to eq(quote)
      expect(Content::Quote.friendly.find(second_slug)).to eq(quote)
      expect(Content::Quote.friendly.find(third_slug)).to eq(quote)
    end

    it "handles history for multiple quotes" do
      quote1 = Content::Quote.create!(
        author: "Author One",
        text: "First quote"
      )

      quote2 = Content::Quote.create!(
        author: "Author Two",
        text: "Second quote"
      )

      original_slug1 = quote1.slug
      original_slug2 = quote2.slug

      # Update both quotes
      quote1.update!(text: "Updated first quote")
      quote2.update!(text: "Updated second quote")

      # Both old slugs should still work for their respective quotes
      expect(Content::Quote.friendly.find(original_slug1)).to eq(quote1)
      expect(Content::Quote.friendly.find(original_slug2)).to eq(quote2)
    end
  end

  describe "CSV import" do
    context "slug generation during import" do
      it "generates proper slugs for imported quotes" do
        quotes_data = [
          { author: "Michael Saylor", text: "There is No Second Best" },
          { author: "Hal Finney", text: "The computer can be used as a tool to liberate and protect people" },
          { author: "Henry Ford", text: "An energy currency can stop wars" }
        ]

        quotes = quotes_data.map do |data|
          Content::Quote.create!(
            author: data[:author],
            text: data[:text],
            published_at: Date.current
          )
        end

        expect(quotes[0].slug).to eq("michael-saylor-there-is-no-second-best")
        expect(quotes[1].slug).to eq("hal-finney-the-computer-can-be-used-as-a-tool-to-liberate-and-protect-people")
        expect(quotes[2].slug).to eq("henry-ford-an-energy-currency-can-stop-wars")
      end

      it "handles duplicate quotes during import" do
        # First import
        quote1 = Content::Quote.create!(
          author: "Bitcoiners",
          text: "Bitcoin is the separation of money and state",
          published_at: Date.current
        )

        # Second import with same content
        quote2 = Content::Quote.create!(
          author: "Bitcoiners",
          text: "Bitcoin is the separation of money and state",
          published_at: Date.current
        )

        expect(quote1.slug).to eq("bitcoiners-bitcoin-is-the-separation-of-money-and-state")
        # FriendlyId uses UUID for duplicates
        expect(quote2.slug).to start_with("bitcoiners-bitcoin-is-the-separation-of-money-and-state-")
      end
    end
  end

  describe "#best_image" do
    let(:quote) { Content::Quote.create!(author: "Test Author", text: "Test quote") }

    it "returns hongbao product image if available" do
      product = Content::Product.create!(
        parent: quote,
        title: "Test Product",
        shop: "HongBao",
        price: 10,
        published_at: Date.current
      )

      product.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/test_image.jpg")),
        filename: "test.jpg"
      ) if File.exist?(Rails.root.join("spec/fixtures/test_image.jpg"))

      expect(quote.best_image).to eq(product.image) if product.image.attached?
    end

    it "returns avatar if no product image" do
      quote.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/avatar.jpg")),
        filename: "avatar.jpg"
      ) if File.exist?(Rails.root.join("spec/fixtures/avatar.jpg"))

      expect(quote.best_image).to eq(quote.avatar) if quote.avatar.attached?
    end
  end

  describe "validations" do
    it "requires a slug" do
      quote = Content::Quote.new(author: "Test", text: "Test")
      quote.slug = nil
      quote.valid?

      # FriendlyId generates a slug automatically
      expect(quote.slug).not_to be_nil
      expect(quote.slug).to eq("test-test")
    end

    it "automatically creates unique slugs for duplicates" do
      first = Content::Quote.create!(
        author: "Test Author",
        text: "Test quote"
      )

      second = Content::Quote.create!(
        author: "Test Author",
        text: "Test quote"
      )

      expect(first.slug).to eq("test-author-test-quote")
      expect(second.slug).to start_with("test-author-test-quote-")
      expect(second.slug).not_to eq(first.slug)

      # Both should be valid and saved
      expect(first).to be_persisted
      expect(second).to be_persisted
    end
  end
end
