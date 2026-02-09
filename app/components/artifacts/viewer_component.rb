class Artifacts::ViewerComponent < ViewComponent::Base
  include MarkdownHelper
  delegate :turbo_frame_tag, to: :helpers

  def initialize(artifact:)
    @artifact = artifact
  end
end
