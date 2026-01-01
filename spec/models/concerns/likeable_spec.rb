require 'rails_helper'

RSpec.describe Likeable, type: :concern do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :likeable_posts, force: true do |t|
        t.json :liker_ids, null: false, default: []
        t.integer :likes_count, null: false, default: 0
        t.check_constraint "JSON_TYPE(liker_ids) = 'array'", name: 'likeable_post_liker_ids_is_array'
      end
    end

    class LikeablePost < ActiveRecord::Base
      include Likeable
    end
  end

  let(:post) { LikeablePost.create! }
  let(:user) { users(:satoshi) }
  let(:another_user) { users(:lagarde) }

  describe '#like!' do
    it 'adds user id to liker_ids' do
      expect { post.like!(user) }.to change { post.reload.liker_ids }
        .from([])
        .to([ user.id ])
    end

    it 'increments likes_count' do
      expect { post.like!(user) }.to change { post.reload.likes_count }
        .from(0)
        .to(1)
    end

    it 'does not add duplicate likes from same user' do
      post.like!(user)
      expect { post.like!(user) }.not_to change { post.reload.likes_count }
    end

    it 'handles multiple users liking' do
      post.like!(user)
      post.like!(another_user)

      expect(post.reload.liker_ids).to contain_exactly(user.id, another_user.id)
      expect(post.reload.likes_count).to eq(2)
    end
  end

  describe '#unlike!' do
    before do
      post.like!(user)
      post.like!(another_user)
    end

    it 'removes user id from liker_ids' do
      expect { post.unlike!(user) }.to change { post.reload.liker_ids }
        .from([ user.id, another_user.id ])
        .to([ another_user.id ])
    end

    it 'decrements likes_count' do
      expect { post.unlike!(user) }.to change { post.reload.likes_count }
        .from(2)
        .to(1)
    end

    it 'does nothing if user has not liked' do
      new_user = create(:user)
      expect { post.unlike!(new_user) }.not_to change { post.reload.likes_count }
    end
  end

  describe '#liked_by?' do
    it 'returns false when user has not liked' do
      expect(post.liked_by?(user)).to be false
    end

    it 'returns true when user has liked' do
      post.like!(user)
      expect(post.liked_by?(user)).to be true
    end

    it 'returns false for nil user' do
      expect(post.liked_by?(nil)).to be false
    end
  end

  describe '#like_toggle!' do
    it 'likes when not liked' do
      expect { post.like_toggle!(user) }.to change { post.reload.likes_count }
        .from(0)
        .to(1)
    end

    it 'unlikes when already liked' do
      post.like!(user)
      expect { post.like_toggle!(user) }.to change { post.reload.likes_count }
        .from(1)
        .to(0)
    end
  end

  describe '#likers' do
    it 'returns users who liked' do
      post.like!(user)
      post.like!(another_user)

      expect(post.likers).to contain_exactly(user, another_user)
    end

    it 'returns empty relation when no likes' do
      expect(post.likers).to be_empty
    end
  end
end
