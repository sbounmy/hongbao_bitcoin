# frozen_string_literal: true

require "rails_helper"

RSpec.describe SavedHongBaosController, type: :controller do
  let(:user) { users(:satoshi) }
  let(:saved_hong_bao) { saved_hong_baos(:hodl) }

  before do
    session_record = Session.create!(user: user, user_agent: "Test", ip_address: "127.0.0.1")
    cookies.signed[:session_id] = session_record.id
  end

  describe "PATCH #update" do
    context "when updating status to lost" do
      it "updates the status to lost" do
        expect(saved_hong_bao.lost?).to be_falsey

        patch :update, params: { id: saved_hong_bao.id, saved_hong_bao: { status: "lost" } }

        saved_hong_bao.reload
        expect(saved_hong_bao.lost?).to be_truthy
        expect(response).to redirect_to(saved_hong_baos_path)
        expect(flash[:notice]).to eq("Hong Bao updated successfully.")
      end
    end

    context "when updating status to withdrawn" do
      it "updates the status to withdrawn" do
        expect(saved_hong_bao.status).not_to eq("withdrawn")

        patch :update, params: { id: saved_hong_bao.id, saved_hong_bao: { status: "withdrawn" } }

        saved_hong_bao.reload
        expect(saved_hong_bao.status).to eq("withdrawn")
        expect(response).to redirect_to(saved_hong_baos_path)
        expect(flash[:notice]).to eq("Hong Bao updated successfully.")
      end
    end

    context "when updating other attributes" do
      it "updates the notes" do
        patch :update, params: { id: saved_hong_bao.id, saved_hong_bao: { notes: "Updated notes" } }

        saved_hong_bao.reload
        expect(saved_hong_bao.notes).to eq("Updated notes")
        expect(response).to redirect_to(saved_hong_baos_path)
        expect(flash[:notice]).to eq("Hong Bao updated successfully.")
      end
    end

    context "when status transition is valid" do
      it "allows reversible transitions from lost back to hodl" do
        # Lost status CAN transition back to hodl (reversible status changes)
        lost_hong_bao = saved_hong_baos(:withdraw)
        lost_hong_bao.update_column(:status, "lost")

        patch :update, params: { id: lost_hong_bao.id, saved_hong_bao: { status: "hodl" } }

        lost_hong_bao.reload
        expect(lost_hong_bao.hodl?).to be_truthy # Status should now be hodl
        expect(response).to redirect_to(saved_hong_baos_path)
        expect(flash[:notice]).to eq("Hong Bao updated successfully.")
      end
    end
  end

  describe "POST #refresh" do
    it "schedules a balance refresh job" do
      expect {
        post :refresh, params: { id: saved_hong_bao.id }
      }.to have_enqueued_job(RefreshSavedHongBaoBalanceJob).with(saved_hong_bao.id)

      expect(response).to redirect_to(saved_hong_baos_path)
      expect(flash[:notice]).to eq("Balance refresh initiated. Please wait a moment.")
    end
  end

  describe "DELETE #destroy" do
    it "removes the saved hong bao" do
      hong_bao = saved_hong_baos(:withdraw)

      expect {
        delete :destroy, params: { id: hong_bao.id }
      }.to change { SavedHongBao.count }.by(-1)

      expect(response).to redirect_to(saved_hong_baos_path)
      expect(flash[:notice]).to eq("Hong Bao removed from saved list.")
    end
  end
end