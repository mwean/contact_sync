class Email < Element
  # attr_accessor :address, :primary, :label, :display_name, :rel
  #
  # AVAILABLE_RELS = %w{ home work }

  def initialize(node)
    initialize_attrs_and_children
    node = super
    @address[:tag] = 'address'
    @primary[:tag] = 'primary'
    @label[:tag] = 'label'
    @rel[:tag] = 'rel'
    @display_name[:tag] = 'displayName'
    find_attrs_and_children(node)
  end

  def tag
    'gd:email'
  end

  def attrs
    %w{ address primary label rel display_name }.map { |child| '@' + child }
  end
end