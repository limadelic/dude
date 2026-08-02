module StatusLineHelpers
  def verify_status_section_empty(section_name, section)
    msg = "Expected empty section, got '#{section.cleaned}'"
    raise msg unless section.cleaned.strip.empty?
  end
end
