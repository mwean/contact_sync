class WrappedNode
  def initialize(node)
    @node = node
  end

  def text
    @node.text.strip
  end

  def find(tag)
    result = @node.xpath(tag)[0]
    result = @node.attributes[tag] unless result
    result && result.text
  end
end