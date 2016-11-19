module Gamera
  class PathJoiner
    # This is a utility method to clean up URLs formed by concatenation since we
    # sometimes ended up with "//" in the middle of URLs which broke the
    # url_matcher checks.
    #
    # @param elements [String] duck types
    # @return [String] of elements joined by single "/" characters.
    def self.path_join(*elements)
      "/#{elements.join('/')}".gsub(%r{//+}, '/')
    end
  end
end
