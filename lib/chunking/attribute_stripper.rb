module Chunking
  class AttributeStripper
    def self.call(node)
      node.attributes.each_key do |name|
        node.remove_attribute(name) unless allow_list(node.name).include?(name)
      end
    end

    def self.allow_list(node_name)
      ALLOW_LISTS[node_name] || []
    end
    private_class_method :allow_list

    ALLOW_LISTS = {
      "a" => %w[href],
      "abbr" => %w[title],
    }.freeze
    private_constant :ALLOW_LISTS
  end
end
