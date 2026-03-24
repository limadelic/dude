require_relative 'format'

class StatusLine::Context
  include StatusLine::Format

  def initialize(session, context_percentage)
    @session = session
    @context_percentage = context_percentage
  end

  def render
    bar(@context_percentage, '🧠', lo: 33, hi: 66)
  end
end
