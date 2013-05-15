class GithubOrgReports::Models::CommitOrganizationLink < Baza::Model
  has_one :Organization
  has_one :Commit
end