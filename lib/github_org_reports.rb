require "rubygems"
require "github_api"
require "baza"

class GithubOrgReports
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../include/github_org_reports_#{name.to_s.downcase}.rb"
    raise "Still not defined: '#{name}'." unless GithubOrgReports.const_defined?(name)
    return GithubOrgReports.const_get(name)
  end
  
  def initialize(args = {})
    @args = args
    @repos = []
    
    @db = @args[:db]
    raise "No ':db' was given." unless @db
    Baza::Revision.new.init_db(:db => @db, :schema => GithubOrgReports::Dbschema::SCHEMA)
    
    @ob = Baza::ModelHandler.new(
      :db => @db,
      :class_path => "#{File.dirname(__FILE__)}/../models",
      :class_pre => "",
      :module => GithubOrgReports::Models,
      :require_all => true
    )
    @ob.data[:github_org_reports] = self
  end
  
  def add_repo(repo)
    raise "Invalid class: '#{repo.class.name}'." unless repo.is_a?(GithubOrgReports::Repo)
    @repos << repo
  end
  
  def scan_hash(str)
    hash = {}
    str.to_s.scan(/!(\{(.+?)\})!/) do |match|
      begin
        json_hash = JSON.parse(match[1])
        hash.merge!(json_hash)
      rescue JSON::ParserError => e
        $stderr.puts e.inspect
        $stderr.puts e.backtrace
      end
    end
    
    return hash
  end
  
  def scan
    @repos.each do |repo|
      gh = ::Github.new
      prs = gh.pull_requests.list(repo.user, repo.name)
      
      commits = gh.repos.commits.all(repo.user, repo.name)
      commits.each do |commit_data|
        puts "Commit: #{commit_data.keys}"
        
        commit = @ob.get_or_add(:Commit, {
          :sha => commit_data.sha
        })
        commit[:text] = commit_data.commit
        
        user = @ob.get_or_add(:User, {
          :name => commit_data.committer
        })
        commit[:user_id] = user.id
        
        commit.scan
      end
      
      count = 0
      prs.each do |pr_data|
        count += 1
        puts "Pull #{count} keys: #{pr_data.keys}"
        
        text = pr_data.body_text
        
        user = @ob.get_or_add(:User, {
          :name => pr_data.user
        })
        
        pr = @ob.get_or_add(:PullRequest, {
          :github_id => pr_data.id
        })
        
        pr[:user_id] = user.id
        pr[:text] = pr_data.body_text
        pr[:html] = pr_data.body_html
        
        pr.scan
      end
    end
  end
  
  def scan_for_time_and_orgs(str)
    res = {:secs => 0, :orgs => []}
    hash = self.scan_hash(str)
    
    
    #Parse organizations.
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
        
        res[:orgs] << org
      end
    end
    
    
    #Parse time.
    if hash["time"] and match = hash["time"].to_s.match(/^(\d{1,2}):(\d{1,2})$/)
      res[:secs] += match[1].to_i * 3600
      res[:secs] += match[2].to_i * 60
    end
    
    
    return res
  end
end