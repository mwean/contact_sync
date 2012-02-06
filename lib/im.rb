class Im < Element
  # attr_accessor :address, :label, :type, :protocol, :primary

  def initialize(node)
    initialize_attrs_and_children
    node = super
    @address[:tag] = 'address'
    @label[:tag] = 'label'
    @rel[:tag] = 'rel'
    @primary[:tag] = 'primary'
    @protocol[:tag] = 'protocol'
    find_attrs_and_children(node)
  end

  def tag
    'gd:im'
  end

  def attrs
    %w{ address label primary rel protocol }.map { |child| '@' + child }
  end

  # def write_attributes
  #   im_array = ["<#{TAG}"]
  #
  #   ATTRIBUTES.each do |attr|
  #     attr_val = instance_variable_get("@#{attr}")
  #     im_array << %{#{attr}='#{attr_val}'} if attr_val && !attr_val.empty?
  #   end
  #
  #   im_array << "rel=" + REL + @rel
  #
  #   # if [:home, :netmeeting, :work].include?(@type)
  #   #   im_array << %{rel="http://schemas.google.com/g/2005##{@type.to_s}"}
  #   #   im_array << %{label="#{@label}"} if @label
  #   # else
  #   #   im_array << %{label="#{@type.to_s}" rel="http://schemas.google.com/g/2005#other}
  #   # end
  #   #
  #   # im_array << %{protocol="http://schemas.google.com/g/2005##{@protocol.upcase}"} if @protocol
  #   # im_array << %{address="#{@address}"}
  #   # im_array << %{primary="true"} if @primary
  #   im_array << "/>"
  #
  #   im_array.join(' ')
  # end
end
