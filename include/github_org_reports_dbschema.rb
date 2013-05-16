class GithubOrgReports::Dbschema
  SCHEMA = {
    :tables => {
      :Commit => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :user_id, :type => :int},
          {:name => :pull_request_id, :type => :int},
          {:name => :sha, :type => :varchar},
          {:name => :date, :type => :datetime},
          {:name => :text, :type => :text},
          {:name => :time, :type => :int}
        ],
        :indexes => [
          :user_id
        ]
      },
      :CommitOrganizationLink => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :commit_id, :type => :int},
          {:name => :organization_id, :type => :int},
          {:name => :time, :type => :int}
        ],
        :indexes => [
          :commit_id,
          :organization_id
        ]
      },
      :Organization => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :name, :type => :varchar},
          {:name => :name_short, :type => :varchar, :maxlength => 5}
        ]
      },
      :User => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :name, :type => :varchar}
        ]
      },
      :PullRequest => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :github_id, :type => :int, :renames => [:pull_request_id]},
          {:name => :user_id, :type => :int},
          {:name => :text, :type => :text},
          {:name => :html, :type => :text},
          {:name => :time, :type => :int}
        ],
        :indexes => [
          :github_id,
          :user_id
        ]
      },
      :PullRequestOrganizationLink => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :pull_request_id, :type => :int},
          {:name => :organization_id, :type => :int},
          {:name => :time, :type => :int}
        ],
        :indexes => [
          :pull_request_id,
          :organization_id
        ]
      }
    }
  }
end