require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Client::Base do
  # Create a dummy class for testing purposes
  class Client::PokemonApi < Client::Base
    url "https://pokeapi.co/api/v2"

    get "/pokemon/:name", as: :get_pokemon

    get "/pokemon", as: :list_pokemon,
                    key: 'results'

    post "/pokemon", as: :create_pokemon

    private

    def api_key_credential_path
      [ :pokemon_api, :api_key ]
    end
  end

  let(:api_key) { "test_api_key" }
  let(:client) { Client::PokemonApi.new(api_key: api_key) }

  describe "dynamic response objects" do
    let(:pokemon_name) { "pikachu" }
    let(:pokemon_url) { "#{Client::PokemonApi.url_for("/pokemon/#{pokemon_name}")}" }
    let(:pokemon_list_url) { "#{Client::PokemonApi.url_for("/pokemon")}" }

    context "single object response" do
      before do
        stub_request(:get, pokemon_url)
          .to_return(
            status: 200,
            body: { name: pokemon_name, abilities: [ "static", "lightning-rod" ], stats: { hp: 35, attack: 55 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it "converts JSON response to dynamic object" do
        pokemon = client.get_pokemon(pokemon_name)

        # Object attributes can be accessed as methods
        expect(pokemon.name).to eq(pokemon_name)
        expect(pokemon.abilities).to eq([ "static", "lightning-rod" ])

        # Nested attributes become nested objects
        expect(pokemon.stats).to be_a(Client::Object)
        expect(pokemon.stats.hp).to eq(35)
        expect(pokemon.stats.attack).to eq(55)

        # Original hash is still accessible
        expect(pokemon.attributes["name"]).to eq(pokemon_name)
      end
    end

    context "list object response" do
      before do
        stub_request(:get, "#{pokemon_list_url}?limit=2&offset=0")
          .to_return(
            status: 200,
            body: {
              count: 1118,
              results: [
                { name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/" },
                { name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/" }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it "converts array responses to ListObject" do
        pokemon_list = client.list_pokemon(limit: 2, offset: 0)

        # List has enumerable behavior
        expect(pokemon_list).to be_a(Client::ListObject)
        expect(pokemon_list.count).to eq(2)

        # Can access total count metadata
        expect(pokemon_list.total_count).to eq(1118)

        # Can access individual items with array syntax or enumeration
        expect(pokemon_list[0].name).to eq("bulbasaur")
        expect(pokemon_list[1].name).to eq("ivysaur")

        # Can iterate over items
        names = []
        pokemon_list.each { |pokemon| names << pokemon.name }
        expect(names).to eq([ "bulbasaur", "ivysaur" ])

        # Can convert to array
        expect(pokemon_list.to_a.map(&:name)).to eq([ "bulbasaur", "ivysaur" ])
      end
    end
  end

  describe ".url_for" do
    it "returns the correct url for the given path" do
      expect(Client::PokemonApi.url_for("/pokemon/pikachu")).to eq("https://pokeapi.co/api/v2/pokemon/pikachu")
    end
  end

  describe 'access token' do
    class Client::BlockstreamApiTest < Client::Base
      url "https://blockstream.info/api"
      url_dev "https://blockstream.info/api"

      def access_token
        self.class.post "https://login.blockstream.com/realms/blockstream-public/protocol/openid-connect/token",
          body: {
            client_id: Rails.application.credentials.dig(:blockstream, :client_id),
            client_secret: Rails.application.credentials.dig(:blockstream, :client_secret),
            grant_type: "client_credentials",
            scope: "openid"
          }
      end
    end

    let(:client) { Client::BlockstreamApiTest.new }

    it 'returns the correct access token' do
      expect(client.access_token).to eq({
        "access_token": "",
        "expires_in": 300,
        "refresh_expires_in": 0,
        "token_type": "Bearer",
        "id_token": "",
        "not-before-policy": 0,
        "scope": "openid token-portal email"
      })
    end
  end
end
