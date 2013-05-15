class GithubOrgReports::Models::Commit < Baza::Model
  has_one :User
  has_one :PullRequest
end