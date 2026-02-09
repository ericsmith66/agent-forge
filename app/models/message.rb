class Message < ApplicationRecord
  belongs_to :task

  enum :role, { user: "user", assistant: "assistant", system: "system", tool: "tool" }

  validates :role, presence: true
  validates :content, presence: true

  scope :ordered, -> { order(:created_at) }
end
