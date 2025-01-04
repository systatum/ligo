require "./project"

Marten.start
Envy.from_file ".env.yml", perm: 0o400
