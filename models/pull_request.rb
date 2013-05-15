class GithubOrgReports::Models::PullRequest < Baza::Model
  has_many [[:PullRequestOrganizationLink, :pull_request_id]]
  
  def scan_hash
    hash = {}
    self[:text].to_s.scan(/!(\{(.+?)\})!/) do |match|
      hash.merge!(JSON.parse(match[1]))
    end
    
    return hash
  end
  
  def scan_time
    hash = self.scan_hash
    secs = 0
    
    if hash["time"] and match = hash["time"].to_s.match(/^(\d{1,2}):(\d{1,2})$/)
      secs += match[1].to_i * 3600
      secs += match[2].to_i * 60
    end
    
    self[:time] = secs
    return nil
  end
  
  def scan_orgs
    hash = self.scan_hash
    
    orgs_found = []
    if orgs = hash["orgs"]
      orgs = [orgs] if !orgs.is_a?(Hash)
      orgs.each do |org_name_short|
        org_name_short_dc = org_name_short.to_s.downcase
        next if org_name_short_dc.strip.empty?
        
        org = self.ob.get_or_add(:Organization, {:name_short => org_name_short_dc})
        
        link = self.ob.get_or_add(:PullRequestOrganizationLink, {
          :organization_id => org.id,
          :pull_request_id => self.id
        })
        
        orgs_found << org.id
      end
    end
  end
end