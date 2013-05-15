class GithubOrgReports::Models::Commit < Baza::Model
  has_one :User
  has_one :PullRequest
  
  def scan
    hash = ob.data[:github_org_reports].scan_for_time_and_orgs(self[:text])
    
    
    #Parse organizations.
    hash[:orgs].each do |org|
      link = self.ob.get_or_add(:CommitOrganizationLink, {
        :organization_id => org.id,
        :pull_request_id => self.id
      })
    end
    
    
    #Parse time.
    self[:time] = hash[:secs]
    
    
    return nil
  end
end