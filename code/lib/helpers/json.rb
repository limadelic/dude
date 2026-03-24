require 'json'
require_relative '../helpers'

module Helpers::Json
  def read_json(path)
    (JSON.parse(@fs.read(path)) rescue nil)
  end

  def read_icon(path)
    return nil unless @fs.exist?(path)
    @fs.read(path)[/^---\s*\n(.*?\n)---\s*\n/m, 1]&.[](/^icon:\s*(.+)/, 1)&.strip
  end
end
