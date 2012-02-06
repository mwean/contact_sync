class Address < Element
  def initialize(node)
    initialize_attrs_and_children
    node = super
    @street[:tag] = 'gd:street'
    @city[:tag] = 'gd:city'
    @state[:tag] = 'gd:region'
    @zipcode[:tag] = 'gd:postcode'
    @country[:tag] = 'gd:country'
    @formatted_address[:tag] = 'gd:formattedAddress'
    @po_box[:tag] = 'gd:pobox'

    @label[:tag] = 'label'
    @rel[:tag] = 'rel'
    find_attrs_and_children(node)
  end

  def tag
    'gd:structuredPostalAddress'
  end

  def children
    %w{ street city state zipcode country formatted_address po_box }.map { |child| '@' + child }
  end

  def attrs
    %w{ label rel }.map { |child| '@' + child }
  end
end