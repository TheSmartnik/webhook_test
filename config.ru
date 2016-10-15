require 'rack/app'
require 'httparty'
require 'logger'
require 'pry'

class App < Rack::App

  LOGIN = ENV['GITHUB_LOGIN']
  TOKEN = ENV['GITHUB_TOKEN']
  TEAM_URL = ENV['TEAM_URL']

  desc 'assign_reviewers'
  post '/assign_reviewers' do
    params = JSON.parse(payload)
    pull = params['pull_request']

    if params["action"] == 'labeled' && params['label']['name'] == 'Code Review'
      assignees_count = 2 - pull['assignees'].size

      return if assignees_count <= 0

      creator = pull.dig(*%w(user login))
      # teams_url = params.dig(*%w(repository teams_url))

      team_members = JSON.parse(HTTParty.get(TEAM_URL,
        basic_auth: { user: LOGIN, password: TOKEN },
        headers: { 'User-Agent' => LOGIN }).body)

      logins = team_members.map { |m| m['login'] }
      logins.delete(creator)
      assignees = logins.sample(assignees_count)

      HTTParty.post("#{pull['url'].gsub('pulls', 'issues')}/assignees",
        body: { "assignees": assignees }.to_json,
        basic_auth: { user: LOGIN, password: TOKEN },
        headers: { 'User-Agent' => LOGIN } )
    end
  end

end

run App
