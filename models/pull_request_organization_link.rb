class GithubOrgReports::Models::PullRequestOrganizationLink < Baza::Model
  has_one :Organization
  has_one :PullRequest
end