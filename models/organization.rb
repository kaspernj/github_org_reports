class GithubOrgReports::Models::Organization < Baza::Model
  def name
    name_str = self[:name].to_s.strip
    name_str = self[:name_short].to_s.strip if name_str.empty?
    name_str = "[no name]" if name_str.empty?
    
    return name_str
  end
end