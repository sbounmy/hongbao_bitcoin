require 'rails_helper'

RSpec.describe Likeable do
  let(:paper) { papers(:dollar) }
  let(:user) { users(:satoshi) }
  let(:another_user) { users(:lagarde) }

  describe '#like!' do
    it 'adds user id to liker_ids' do
      expect { paper.like!(user) }.to change { paper.reload.liker_ids }
        .from([])
        .to([ user.id ])
    end

    it 'increments likes_count' do
      expect { paper.like!(user) }.to change { paper.reload.likes_count }
        .from(0)
        .to(1)
    end

    it 'does not add duplicate likes from same user' do
      paper.like!(user)
      expect { paper.like!(user) }.not_to change { paper.reload.likes_count }
    end

    it 'handles multiple users liking' do
      paper.like!(user)
      paper.like!(another_user)

      expect(paper.reload.liker_ids).to contain_exactly(user.id, another_user.id)
      expect(paper.reload.likes_count).to eq(2)
    end
  end

  describe '#unlike!' do
    before do
      paper.like!(user)
      paper.like!(another_user)
    end

    it 'removes user id from liker_ids' do
      expect { paper.unlike!(user) }.to change { paper.reload.liker_ids }
        .from([ user.id, another_user.id ])
        .to([ another_user.id ])
    end

    it 'decrements likes_count' do
      expect { paper.unlike!(user) }.to change { paper.reload.likes_count }
        .from(2)
        .to(1)
    end

    it 'does nothing if user has not liked' do
      new_user = create(:user)
      expect { paper.unlike!(new_user) }.not_to change { paper.reload.likes_count }
    end
  end

  describe '#liked_by?' do
    it 'returns false when user has not liked' do
      expect(paper.liked_by?(user)).to be false
    end

    it 'returns true when user has liked' do
      paper.like!(user)
      expect(paper.liked_by?(user)).to be true
    end

    it 'returns false for nil user' do
      expect(paper.liked_by?(nil)).to be false
    end
  end

  describe '#like_toggle!' do
    it 'likes when not liked' do
      expect { paper.like_toggle!(user) }.to change { paper.reload.likes_count }
        .from(0)
        .to(1)
    end

    it 'unlikes when already liked' do
      paper.like!(user)
      expect { paper.like_toggle!(user) }.to change { paper.reload.likes_count }
        .from(1)
        .to(0)
    end
  end

  describe '#likers' do
    it 'returns users who liked' do
      paper.like!(user)
      paper.like!(another_user)

      expect(paper.likers).to contain_exactly(user, another_user)
    end

    it 'returns empty relation when no likes' do
      expect(paper.likers).to be_empty
    end
  end
end
