require "rails_helper"

# https://fractaledmind.github.io/2023/09/12/enhancing-rails-sqlite-array-columns/
RSpec.describe ArrayColumns, type: :concern do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
        t.json :tags, null: false, default: []
        t.json :author_ids, null: false, default: []
        t.check_constraint "JSON_TYPE(tags) = 'array'", name: 'post_tags_is_array'
        t.check_constraint "JSON_TYPE(author_ids) = 'array'", name: 'post_author_ids_is_array'
      end
    end

    class Post < ActiveRecord::Base
      include ArrayColumns
      array_columns :tags, :author_ids
    end
  end

  let!(:post_1) { Post.create!(tags: %w[a b c d]) }
  let!(:post_2) { Post.create!(tags: %w[c d e f]) }
  let!(:post_3) { Post.create! }

  describe ".unique_tags" do
    it "returns unique tags" do
      expect(Post.unique_tags).to match_array(%w[a b c d e f])
    end
  end

  describe ".tags_cloud" do
    it "returns tags cloud" do
      expect(Post.tags_cloud).to eq({ 'a' => 1, 'b' => 1, 'c' => 2, 'd' => 2, 'e' => 1, 'f' => 1 })
    end
  end

  describe ".with_tags" do
    it "returns posts with tags" do
      collection = Post.with_tags
      expect(collection).to include(post_1, post_2)
      expect(collection).not_to include(post_3)
    end
  end

  describe ".without_tags" do
    it "returns posts without tags" do
      collection = Post.without_tags
      expect(collection).not_to include(post_1, post_2)
      expect(collection).to include(post_3)
    end
  end

  describe ".with_any_tags" do
    it "with unique argument" do
      collection = Post.with_any_tags('a')
      expect(collection).to include(post_1)
      expect(collection).not_to include(post_2, post_3)
    end

    it "with shared argument" do
      collection = Post.with_any_tags('c')
      expect(collection).to include(post_1, post_2)
      expect(collection).not_to include(post_3)
    end

    it "with non-existent argument" do
      expect(Post.with_any_tags('z')).to be_empty
    end
  end

  describe ".with_all_tags" do
    it "with unique arguments" do
      collection = Post.with_all_tags('a', 'b')
      expect(collection).to contain_exactly(post_1)
    end

    it "with shared arguments" do
      collection = Post.with_all_tags('c', 'd')
      expect(collection).to contain_exactly(post_1, post_2)
    end

    it "with split arguments" do
      expect(Post.with_all_tags('a', 'f')).to be_empty
    end
  end

  describe ".without_any_tags" do
    it "with a unique argument" do
      collection = Post.without_any_tags('a')
      expect(collection).to contain_exactly(post_2, post_3)
    end

    it "with a shared argument" do
      collection = Post.without_any_tags('c')
      expect(collection).to contain_exactly(post_3)
    end

    it "with split arguments" do
      collection = Post.without_any_tags('a', 'f')
      expect(collection).to contain_exactly(post_3)
    end
  end

  describe ".without_all_tags" do
    it "with unique arguments" do
      collection = Post.without_all_tags('a', 'b')
      expect(collection).to contain_exactly(post_2, post_3)
    end

    it "with shared arguments" do
      collection = Post.without_all_tags('c', 'd')
      expect(collection).to contain_exactly(post_3)
    end

    it "with split arguments" do
      collection = Post.without_all_tags('a', 'f')
      expect(collection).to contain_exactly(post_1, post_2, post_3)
    end
  end

  describe "#has_any_tags?" do
    it "with unique argument" do
      expect(post_1.has_any_tags?('a')).to be true
      expect(post_2.has_any_tags?('a')).to be false
    end

    it "with shared argument" do
      expect(post_1.has_any_tags?('c')).to be true
      expect(post_2.has_any_tags?('c')).to be true
    end

    it "with split arguments" do
      expect(post_1.has_any_tags?('a', 'f')).to be true
      expect(post_2.has_any_tags?('a', 'f')).to be true
    end
  end

  describe "#has_all_tags?" do
    it "with unique arguments" do
      expect(post_1.has_all_tags?('a', 'b')).to be true
      expect(post_2.has_all_tags?('a', 'b')).to be false
    end

    it "with shared arguments" do
      expect(post_1.has_all_tags?('c', 'd')).to be true
      expect(post_2.has_all_tags?('c', 'd')).to be true
    end

    it "with split arguments" do
      expect(post_1.has_all_tags?('a', 'f')).to be false
      expect(post_2.has_all_tags?('a', 'f')).to be false
    end
  end

  describe "integer array support" do
    let!(:post_with_authors) { Post.create!(author_ids: [ 1, 2, 3 ]) }
    let!(:post_with_more_authors) { Post.create!(author_ids: [ 2, 3, 4 ]) }
    let!(:post_without_authors) { Post.create! }

    describe "type preservation" do
      it "preserves integer types in arrays" do
        post = Post.create!(author_ids: [ 1, 2, 3 ])
        post.reload
        expect(post.author_ids).to eq([ 1, 2, 3 ])
        expect(post.author_ids.first).to be_a(Integer)
      end

      it "removes duplicates while preserving type" do
        post = Post.create!(author_ids: [ 1, 2, 2, 3, 1 ])
        post.reload
        expect(post.author_ids).to eq([ 1, 2, 3 ])
      end

      it "work on update" do
        post = Post.create!(author_ids: [ 1, 2, 3 ])
        post.update(author_ids: [ 1, 2, 3, 4 ])
        expect(post.author_ids).to eq([ 1, 2, 3, 4 ])
      end
    end

    describe ".with_any_author_ids" do
      it "finds posts with any of the given author ids" do
        collection = Post.with_any_author_ids(1)
        expect(collection).to include(post_with_authors)
        expect(collection).not_to include(post_with_more_authors, post_without_authors)
      end

      it "works with multiple author ids" do
        collection = Post.with_any_author_ids(1, 4)
        expect(collection).to include(post_with_authors, post_with_more_authors)
        expect(collection).not_to include(post_without_authors)
      end
    end

    describe ".with_all_author_ids" do
      it "finds posts with all of the given author ids" do
        collection = Post.with_all_author_ids(2, 3)
        expect(collection).to include(post_with_authors, post_with_more_authors)
        expect(collection).not_to include(post_without_authors)
      end

      it "returns empty when no posts have all ids" do
        expect(Post.with_all_author_ids(1, 4)).to be_empty
      end
    end

    describe "#has_any_author_ids?" do
      it "checks if post has any of the given author ids" do
        expect(post_with_authors.has_any_author_ids?(1)).to be true
        expect(post_with_authors.has_any_author_ids?(4)).to be false
        expect(post_with_authors.has_any_author_ids?(1, 4)).to be true
      end
    end

    describe "#has_all_author_ids?" do
      it "checks if post has all of the given author ids" do
        expect(post_with_authors.has_all_author_ids?(1, 2)).to be true
        expect(post_with_authors.has_all_author_ids?(1, 4)).to be false
        expect(post_with_more_authors.has_all_author_ids?(2, 3)).to be true
      end
    end
  end
end
