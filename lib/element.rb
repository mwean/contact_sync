class Element
  def initialize(node)
    WrappedNode.new(node)
  end

  def initialize_attrs_and_children
    (children + attrs).each do |child|
      instance_variable_set(child, {})
    end
  end

  def find_attrs_and_children(node)
    (children + attrs).each do |child|
      child = instance_variable_get(child)
      child[:value] = node.find(child[:tag])
    end
  end

  def write(xml)
    # xml.send(tag) do
      children.each do |child|
        child = instance_variable_get(child)
        xml.send(child[:tag], child[:value]) if child[:value]
      end
    # end
  end

  def attribute_hash
    attr_hash = {}
    attrs.each do |attribute|
      attrib = instance_variable_get(attribute)
      attr_hash[attrib[:tag]] = attrib[:value] if attrib[:value]
    end
    attr_hash
  end

  def value
    nil
  end

  def children
    []
  end

  def attrs
    []
  end

  def has_content?
    false
  end

  def attributes
    nil
  end
end