class GithubOrgReports::Models::PullRequest < Baza::Model
  has_many [[:PullRequestOrganizationLink, :pull_request_id]]
  
  def scan
    hash = ob.data[:github_org_reports].scan_for_time_and_orgs(self[:text])
    
    
    #Parse organizations.
    hash[:orgs].each do |org|
      link = self.ob.get_or_add(:PullRequestOrganizationLink, {
        :organization_id => org.id,
        :pull_request_id => self.id
      })
    end
    
    
    #Parse time.
    self[:time] = hash[:secs]
    
    
    return nil
  end
end