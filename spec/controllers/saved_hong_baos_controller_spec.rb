# frozen_string_literal: true

require "rails_helper"

RSpec.describe SavedHongBaosController, type: :controller do
  let(:user) { users(:satoshi) }
  let(:saved_hong_bao) { saved_hong_baos(:hodl) }

  before do
    session_record = Session.create!(user: user, user_agent: "Test", ip_address: "127.0.0.1")
    cookies.signed[:session_id] = session_record.id
  end

  describe "POST #create" do
    context "with file attachment" do
      it "creates a saved hong bao with file" do
        file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

        expect {
          post :create, params: {
            saved_hong_bao: {
              name: "Test Hong Bao",
              address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
              notes: "Test notes",
              file: file
            }
          }
        }.to change { SavedHongBao.count }.by(1)

        new_hong_bao = SavedHongBao.last
        expect(new_hong_bao.file.attached?).to be true
        expect(new_hong_bao.file.filename.to_s).to eq("test.pdf")
        expect(response).to redirect_to(saved_hong_baos_path)
      end
    end

    context "without file attachment" do
      it "creates a saved hong bao without file" do
        expect {
          post :create, params: {
            saved_hong_bao: {
              name: "Test Hong Bao",
              address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
              notes: "Test notes"
            }
          }
        }.to change { SavedHongBao.count }.by(1)

        new_hong_bao = SavedHongBao.last
        expect(new_hong_bao.file.attached?).to be false
        expect(response).to redirect_to(saved_hong_baos_path)
      end
    end
  end


  describe "GET #edit" do
    it "renders the edit form" do
      get :edit, params: { id: saved_hong_bao.id }

      expect(response).to be_successful
      expect(assigns(:saved_hong_bao)).to eq(saved_hong_bao)
    end
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

    context "when updating with file attachment" do
      it "attaches a file during update" do
        file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

        patch :update, params: { id: saved_hong_bao.id, saved_hong_bao: { file: file } }

        saved_hong_bao.reload
        expect(saved_hong_bao.file.attached?).to be true
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

  describe "DELETE #destroy_file" do
    before do
      # Attach a file first
      saved_hong_bao.file.attach(
        io: StringIO.new("test content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
    end

    it "removes the attached file" do
      expect(saved_hong_bao.file.attached?).to be true

      delete :destroy_file, params: { id: saved_hong_bao.id }

      saved_hong_bao.reload
      expect(saved_hong_bao.file.attached?).to be false
      expect(response).to render_template(:edit)
      expect(flash[:notice]).to eq("File removed successfully.")
    end
  end

  describe "GET #download" do
    context "when file is attached" do
      before do
        saved_hong_bao.file.attach(
          io: StringIO.new("test content"),
          filename: "test.pdf",
          content_type: "application/pdf"
        )
      end

      it "redirects to the file download" do
        get :download, params: { id: saved_hong_bao.id }

        expect(response).to be_redirect
        expect(response.location).to include("test.pdf")
      end
    end

    context "when no file is attached" do
      it "redirects back with alert" do
        get :download, params: { id: saved_hong_bao.id }

        expect(response).to redirect_to(saved_hong_baos_path)
        expect(flash[:alert]).to eq("No file attached.")
      end
    end
  end
end
