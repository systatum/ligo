lock "~> 3.19.2"

set :application, "ligo"
set :repo_url, "https://x-access-token:#{ENV['GITHUB_TOKEN']}@github.com/systatum/ligo.git"

if fetch(:stage) == :production
  set :deploy_to, ENV["PROD_PATH"]
  set :branch, ENV["DEPLOY_BRANCH"]
  set :deploy_env, "prod"
else
  set :deploy_to, ENV["STAGE_PATH"]
  set :branch, ENV["DEPLOY_BRANCH"]
  set :deploy_env, "stage"
end
