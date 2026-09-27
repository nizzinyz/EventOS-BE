module Api
  class VenueVerificationSubmissionsController < ApplicationController
    before_action :set_venue

    def show
      submission = @venue.venue_verification_submissions.order(created_at: :desc).first
      raise ActiveRecord::RecordNotFound, "Verification submission not found" unless submission
      render json: attributes_for(submission)
    end

    def create
      raise ActionController::BadRequest, "Venue is already verified" if @venue.verification_status == "verified"
      submission = @venue.venue_verification_submissions.create!(submission_params.merge(submitted_by: current_user, status: "submitted"))
      @venue.update!(verification_status: "pending_review")
      render json: attributes_for(submission), status: :created
    end

    private

    def set_venue
      @venue = Venue.where(owner: current_user).find(params[:venue_id])
    end

    def submission_params
      params.require(:submission).permit(:legal_name, :contact_name, :contact_email, :contact_phone, :notes, documents: [:name, :url, :type])
    end

    def attributes_for(submission)
      { id: submission.id.to_s, status: submission.status, legalName: submission.legal_name, contactName: submission.contact_name,
        contactEmail: submission.contact_email, contactPhone: submission.contact_phone, documents: submission.documents,
        notes: submission.notes, decisionReason: submission.decision_reason, reviewedAt: submission.reviewed_at, createdAt: submission.created_at }
    end
  end
end
