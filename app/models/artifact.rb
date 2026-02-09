class Artifact < ApplicationRecord
  belongs_to :project
  belongs_to :parent, class_name: "Artifact", optional: true
  has_many :children, class_name: "Artifact", foreign_key: :parent_id, dependent: :nullify

  enum :artifact_type, { idea: "idea", backlog_item: "backlog_item", epic: "epic", prd: "prd" }
  enum :status, { draft: "draft", refined: "refined", approved: "approved", implemented: "implemented", archived: "archived" }

  validates :title, presence: true
  validates :artifact_type, presence: true

  def content
    jsonb_document["content"]
  end

  def content=(value)
    self.jsonb_document["content"] = value
  end

  scope :by_type, ->(type) { where(artifact_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position) }
end
