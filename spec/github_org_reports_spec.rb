require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require "tmpdir"
require "sqlite3"
require "json"

describe "GithubOrgReports" do
  it "should be able to fill the database" do
    db_path = "#{Dir.tmpdir}/github_org_reports.sqlite3"
    db = Baza::Db.new(:type => :sqlite3, :path => db_path, :index_append_table_name => true)
    
    login_info = JSON.parse(File.read("#{File.dirname(__FILE__)}/spec_info.txt").to_s.strip)
    
    begin
      gor = GithubOrgReports.new(:db => db)
      gor.add_repo GithubOrgReports::Repo.new(:user => "kaspernj", :name => "php4r", :login => login_info["login"], :password => login_info["password"])
      gor.add_repo GithubOrgReports::Repo.new(:user => "kaspernj", :name => "github_org_reports", :login => login_info["login"], :password => login_info["password"])
      gor.scan
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise e
    end
  end
end
