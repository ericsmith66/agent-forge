class Task < ApplicationRecord
  belongs_to :project
  has_many :messages, dependent: :destroy

  enum :status, { pending: "pending", in_progress: "in_progress", completed: "completed", failed: "failed", timeout: "timeout" }

  validates :status, presence: true
end
