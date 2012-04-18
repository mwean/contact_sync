class Name < Element
  attr_accessor :name_prefix, :first_name, :middle_name, :last_name, :name_suffix

  def initialize(node)
    initialize_attrs_and_children
    @name_prefix[:tag] = 'gd:namePrefix'
    @first_name[:tag] = 'gd:givenName'
    @middle_name[:tag] = 'gd:additionalName'
    @last_name[:tag] = 'gd:familyName'
    @name_suffix[:tag] = 'gd:nameSuffix'
    node = super
    find_attrs_and_children(node)
  end
  
  def full_name
    [@first_name[:value], @last_name[:value]].compact.join(' ')
  end

  def children
    %w{ name_prefix first_name middle_name last_name name_suffix }.map { |child| '@' + child }
  end

  def tag
    'gd:name'
  end
end