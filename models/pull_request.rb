class GithubOrgReports::Models::PullRequest < Baza::Model
  has_many [
    [:PullRequestOrganizationLink, :pull_request_id],
    [:Commit, :pull_request_id]
  ]
  
  def scan
    hash = ob.data[:github_org_reports].scan_for_time_and_orgs(self[:text])
    
    
    #Parse organizations.
    hash[:orgs].each do |org|
      link = self.ob.get_or_add(:PullRequestOrganizationLink, {
        :organization_id => org.id,
        :pull_request_id => self.id,
      })
      
      link[:time] = hash[:orgs_time][org.id][:secs]
    end
    
    
    #Parse time.
    self[:time] = hash[:secs]
    
    
    return nil
  end
  
  def total_time_for_org(args)
    org = args[:org]
    raise "No ':org' was given." if !org
    
    
    #Collect shared time.
    secs = self[:time].to_i
    
    
    #Collect time for the pull-request-organization-links.
    self.pull_request_organization_links(:organization_id => org.id) do |prol|
      secs += prol[:time].to_i
    end
    
    
    #Collect time from commits.
    self.commits do |commit|
      secs += commit[:time].to_i
      
      commit.commit_organization_links(:organization_id => org.id) do |col|
        secs += col[:time].to_i
      end
    end
    
    
    return secs
  end
  
  def title(args = nil)
    title_str = self[:text].to_s.lines.first.to_s.strip
    mlength = (args && args[:maxlength]) ? args[:maxlength] : 15
    
    if title_str.length > mlength
      title_str = title_str.slice(0, mlength).strip
      title_str << "..."
    end
    
    title_str = "[no title]" if title_str.empty?
    
    return title_str
  end
end