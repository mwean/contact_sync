class Organization < Element
  TAG = 

  TITLE_TAG = 'gd:orgTitle'
  JOB_DESCRIPTION_TAG = 'gd:orgJobDescription'
  NAME_TAG = 'gd:orgName'

  ATTRIBUTES = %w{ label }

  def initialize(node)
    initialize_attrs_and_children
    node = super
    
    @name[:tag] = 'gd:orgName'
    @title[:tag] = 'gd:orgTitle'
    @job_description[:tag] = 'gd:orgJobDescription'
    @department[:tag] = 'gd:orgDepartment'
    @where[:tag] = 'gd:where'

    @label[:tag] = 'label'
    @rel[:tag] = 'rel'
    @primary[:tag] = 'primary'
    
    find_attrs_and_children(node)
  end
  
  def tag
    'gd:organization'
  end
  
  def children
    %w{ name title job_description department where }.map { |child| '@' + child }
  end
  
  def attrs
    %w{ label rel primary }.map { |child| '@' + child }
  end
end