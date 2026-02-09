class Project < ApplicationRecord
  has_many :artifacts, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :project_dir, presence: true

  validate :project_dir_under_projects

  scope :active, -> { where(active: true) }

  private

  def project_dir_under_projects
    return if project_dir.blank?

    unless project_dir.start_with?("projects/")
      errors.add(:project_dir, "must be under projects/")
    end
  end
end
