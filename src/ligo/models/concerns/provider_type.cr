# OAuth providers supported by the multi_auth shard Ligo's OAuth flow is
# built on. FACEBOOK keeps value 0 to stay compatible with existing data;
# the rest just mirror multi_auth's own provider list.
enum ProviderType
  FACEBOOK = 0
  GOOGLE   = 1
  GITHUB   = 2
  GITLAB   = 3
  VK       = 4
  TWITTER  = 5
end
