require 'rails_helper'

RSpec.describe Activable, type: :concern do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
        t.boolean :active, default: true, null: false
      end
    end

    class Post < ActiveRecord::Base
      include Activable
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table(:posts, if_exists: true)
    Object.send(:remove_const, :Post) if Object.const_defined?(:Post)
  end

  let(:post) { Post.create! }

  describe '.active' do
    it 'returns only active records' do
      active = Post.create!(active: true)
      inactive = Post.create!(active: false)

      expect(Post.active).to include(active)
      expect(Post.active).not_to include(inactive)
    end
  end

  describe '.inactive' do
    it 'returns only inactive records' do
      active = Post.create!(active: true)
      inactive = Post.create!(active: false)

      expect(Post.inactive).to include(inactive)
      expect(Post.inactive).not_to include(active)
    end
  end
end
