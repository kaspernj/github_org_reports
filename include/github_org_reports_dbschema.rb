class GithubOrgReports::Dbschema
  SCHEMA = {
    :tables => {
      :Organization => {
        :columns => [
          {:name => :id, :type => :int, :autoincr => true, :primarykey => true},
          {:name => :name, :type => :varchar}
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
          {:name => :pull_request_id, :type => :int}
        ]
      }
    }
  }
end