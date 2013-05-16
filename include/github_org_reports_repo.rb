class GithubOrgReports::Repo
  attr_reader :args
  
  def initialize(args)
    @args = args
  end
  
  def name
    return @args[:name]
  end
  
  def user
    return @args[:user]
  end
end