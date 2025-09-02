server ENV["AZURE_IP"], user: ENV["AZURE_USER"], roles: %w{app db web}, primary: true

set :ssh_options, {
  keys: [File.expand_path('~/.ssh/deploy_key')],
  forward_agent: false,
  auth_methods: %w(publickey),
}
