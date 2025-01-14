class HistoricalMatch < ApplicationRecord
  enum status: {scoreable: "scoreable", archived: "archived"}

  has_many :pending_notifications, dependent: :nullify

  validates :matched_on, :grouping, presence: true
  validate :at_least_two_members

  scope :older_than, ->(date) { where("created_at::date < '#{date.to_date}'") }
  scope :for_user, ->(user) { where("members @> ?", "{#{user.slack_user_id}}") }

  private

  def at_least_two_members
    if !members.is_a?(Array) || members.size < 2
      errors.add(:members, "must include multiple members")
    end
  end
end
