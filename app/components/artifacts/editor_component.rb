class Artifacts::EditorComponent < ViewComponent::Base
  delegate :turbo_frame_tag, to: :helpers
  def initialize(artifact:)
    @artifact = artifact
  end
end
