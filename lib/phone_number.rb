class PhoneNumber < Element
  # AVAILABLE_RELS = %w{ home main mobile other work fax assistant }

  def initialize(node)
    initialize_attrs_and_children
    node = super
    @label[:tag] = 'label'
    @primary[:tag] = 'primary'
    @rel[:tag] = 'rel'
    @number = node.text
    find_attrs_and_children(node)
  end

  def tag
    'gd:phoneNumber'
  end

  def attrs
    %w{ label primary rel }.map { |child| '@' + child }
  end

  def value
    @number
  end
end