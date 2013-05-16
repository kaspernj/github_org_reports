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
  
  it "should be able to parse special json strings" do
    str = "!{time: 00:30, orgs: [knjit, gfish]}!\n"
    str << "!{time: 00:15, orgs: [knjit]}!"
    
    db_path = "#{Dir.tmpdir}/github_org_reports.sqlite3"
    db = Baza::Db.new(:type => :sqlite3, :path => db_path, :index_append_table_name => true)
    
    login_info = JSON.parse(File.read("#{File.dirname(__FILE__)}/spec_info.txt").to_s.strip)
    
    begin
      gor = GithubOrgReports.new(:db => db)
      
      res = gor.scan_for_time_and_orgs(str)
      
      org_knjit = gor.ob.get_by(:Organization, :name_short => "knjit")
      org_gfish = gor.ob.get_by(:Organization, :name_short => "gfish")
      
      res[:orgs_time][org_knjit.id][:secs].should eql(2700)
      res[:orgs_time][org_gfish.id][:secs].should eql(1800)
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise e
    end
  end
  
  it "should be able to convert seconds to time strings" do
    GithubOrgReports.secs_to_time(1800).should eql("0:30")
    GithubOrgReports.secs_to_time(2700).should eql("0:45")
  end
end
