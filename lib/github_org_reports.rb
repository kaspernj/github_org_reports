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
      :class_path => "#{File.dirname(__FILE__)}/../models"
    )
  end
  
  def add_repo(repo)
    raise "Invalid class: '#{repo.class.name}'." unless repo.is_a?(GithubOrgReports::Repo)
    @repos << repo
  end
  
  def scan
    @repos.each do |repo|
      gh = ::Github.new
      prs = gh.pull_requests.list(repo.user, repo.name)
      
      count = 0
      prs.each do |pr|
        count += 1
        puts "Pull #{count} keys: #{pr.keys}"
        
        text = pr.body_text
        
      end
    end
  end
end