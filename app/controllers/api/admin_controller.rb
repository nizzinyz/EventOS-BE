module Api
  class AdminController < ApplicationController
    before_action :require_admin!

    def users
      users = User.order(created_at: :desc)
      users = users.where("email ILIKE ?", "%#{params[:query]}%") if params[:query].present?
      render json: users.limit(100).map(&:api_attributes)
    end

    def update_user_role
      user = User.find_by!(public_id: params[:id])
      role = params.require(:user).require(:platform_role)
      raise ActionController::BadRequest, "Invalid platform role" unless %w[user admin].include?(role)
      raise ActionController::BadRequest, "You cannot remove your own admin access" if user == current_user && role != "admin"
      user.update!(platform_role: role)
      audit!("user.role_updated", user, platform_role: role)
      render json: user.api_attributes
    end

    def verification_submissions
      submissions = VenueVerificationSubmission.includes(:venue, :submitted_by, :reviewed_by).order(created_at: :asc)
      submissions = submissions.where(status: params[:status]) if params[:status].present?
      render json: submissions.map { |submission| submission_attributes(submission) }
    end

    def review_verification
      submission = VenueVerificationSubmission.find(params[:id])
      decision = params.require(:review).require(:decision)
      raise ActionController::BadRequest, "Invalid decision" unless %w[approved rejected suspended].include?(decision)
      reason = params.require(:review).require(:reason).to_s.strip
      raise ActionController::BadRequest, "A decision reason is required" if reason.blank?
      submission.with_lock do
        submission.update!(status: decision == "approved" ? "approved" : "rejected", reviewed_by: current_user, reviewed_at: Time.current, decision_reason: reason)
        submission.venue.update!(verification_status: decision == "approved" ? "verified" : decision)
        audit!("venue.verification_#{decision}", submission.venue, submission_id: submission.id, reason: reason)
      end
      render json: submission_attributes(submission.reload)
    end

    private

    def submission_attributes(submission)
      { id: submission.id.to_s, status: submission.status, venue: submission.venue.api_attributes,
        submittedBy: submission.submitted_by.api_attributes, legalName: submission.legal_name,
        contactName: submission.contact_name, contactEmail: submission.contact_email, contactPhone: submission.contact_phone,
        documents: submission.documents, notes: submission.notes, decisionReason: submission.decision_reason,
        reviewedAt: submission.reviewed_at, createdAt: submission.created_at }
    end

    def audit!(action, target, metadata = {})
      AdminAuditLog.create!(actor: current_user, action: action, target_type: target.class.name, target_id: target.id, metadata: metadata)
    end
  end
end
