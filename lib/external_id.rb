class ExternalId < Element
  def initialize(node_or_id)
    initialize_attrs_and_children
    @label[:tag] = 'label'
    # @rel[:tag] = 'rel'
    @value[:tag] = 'value'
    if node_or_id.is_a?(String)
      @label[:value] = 'SyncID'
      # @rel[:value] = 'network'
      @value[:value] = node_or_id
    else
      node = super
      find_attrs_and_children(node)
    end
  end

  def id_value
    @value[:value]
  end

  def tag
    'gContact:externalId'
  end

  def attrs
    %w{ label rel value }.map { |child| '@' + child }
  end
end