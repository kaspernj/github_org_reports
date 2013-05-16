require "rubygems"
require "github_api"
require "baza"

class GithubOrgReports
  attr_reader :db, :ob, :repos
  
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
    str.to_s.scan(/!(\{(.+?)\})!/) do |match|
      json_str = match[0]
      
      
      #Fix missing quotes in 'time' and 'orgs' to make it easier to write.
      json_str.gsub!(/time:\s*([\d+:]+)/, "\"time\": \"\\1\"")
      
      if orgs_match = json_str.match(/orgs:\s*\[(.+?)\]/)
        orgs_str = orgs_match[1]
        orgs_str.gsub!(/\s*(^|\s*,\s*)([A-z_\d]+)/, "\\1\"\\2\"")
        
        json_str.gsub!(orgs_match[0], "\"orgs\": [#{orgs_str}]")
      end
      
      
      #Parse the JSON and yield it.
      begin
        yield JSON.parse(json_str)
      rescue JSON::ParserError => e
        $stderr.puts e.inspect
        #$stderr.puts e.backtrace
      end
    end
  end
  
  def scan
    @repos.each do |repo|
      gh_args = {}
      gh_args[:login] = repo.args[:login] if repo.args[:login]
      gh_args[:password] = repo.args[:password] if repo.args[:password]
      
      gh = ::Github.new(gh_args)
      
      commits = gh.repos.commits.all(repo.args[:user], repo.args[:name])
      commits.each do |commit_data|
        commit = init_commit_from_data(commit_data)
      end
      
      prs = gh.pull_requests.list(repo.args[:user], repo.args[:name])
      prs.each do |pr_data|
        text = pr_data.body_text
        
        user = @ob.get_or_add(:User, {
          :name => pr_data.user
        })
        
        github_id = pr_data.id.to_i
        raise "Invalid github-ID: '#{github_id}'." if github_id <= 0
        pr = @ob.get_or_add(:PullRequest, {
          :github_id => github_id
        })
        
        pr[:user_id] = user.id
        pr[:text] = pr_data.body_text
        pr[:html] = pr_data.body_html
        
        pr.scan
        
        commits = gh.pull_requests.commits(:repo => repo.args[:name], :user => repo.args[:user], :number => pr_data.number, :login => repo.args[:login], :password => repo.args[:password])
        commits.each do |commit_data|
          commit = init_commit_from_data(commit_data)
          commit[:pull_request_id] = pr.id
        end
      end
    end
  end
  
  def scan_for_time_and_orgs(str)
    res = {:secs => 0, :orgs => [], :orgs_time => {}}
    
    self.scan_hash(str) do |hash|
      #Parse time.
      if hash["time"] and match_time = hash["time"].to_s.match(/^(\d{1,2}):(\d{1,2})$/)
        secs = 0
        secs += match_time[1].to_i * 3600
        secs += match_time[2].to_i * 60
        
        res[:secs] += secs
        
        #Parse organizations.
        if orgs = hash["orgs"]
          orgs = [orgs] if !orgs.is_a?(Hash)
          orgs.each do |org_name_short|
            org_name_short_dc = org_name_short.to_s.downcase
            next if org_name_short_dc.strip.empty?
            
            org = self.ob.get_or_add(:Organization, {:name_short => org_name_short_dc})
            
            res[:orgs] << org unless res[:orgs].include?(org)
            
            res[:orgs_time][org.id] = {:secs => 0} unless res[:orgs_time].key?(org.id)
            res[:orgs_time][org.id][:secs] += secs
          end
        end
      end
    end
    
    return res
  end
  
  private
  
  def init_commit_from_data(commit_data)
    sha = commit_data.sha
    raise "Invalid SHA: '#{sha}' (#{commit_data.to_hash})." if sha.to_s.strip.empty?
    
    commit = @ob.get_or_add(:Commit, {
      :sha => sha
    })
    raise "Commit didnt get added right '#{commit[:sha]}', '#{sha}'." if sha != commit[:sha]
    
    commit[:text] = commit_data.commit
    
    
    date = Time.parse(commit_data.commit.committer.date)
    raise "Invalid date: '#{date}' (#{commit_data.commit.to_hash})" if !date
    
    commit[:date] = date
    
    if commit_data.author
      user = @ob.get_or_add(:User, {
        :name => commit_data.author.login
      })
      commit[:user_id] = user.id
    else
      commit[:user_id] = 0
    end
    
    commit.scan
    
    return commit
  end
end