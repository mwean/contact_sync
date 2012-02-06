class Organization < Element
  TAG = 'gd:organization'

  TITLE_TAG = 'gd:orgTitle'
  JOB_DESCRIPTION_TAG = 'gd:orgJobDescription'
  NAME_TAG = 'gd:orgName'

  ATTRIBUTES = %w{ label }

  def initialize(node)
    node = super
    @title           = node.find(TITLE_TAG)
    @job_description = node.find(JOB_DESCRIPTION_TAG)
    @name            = node.find(NAME_TAG)
    @label           = node.find('label')
  end
end
