Handle multiple git identities with a single config file:

```
[includeIf "hasconfig:remote.*.url:<placeholder>"]
[user]
  email = <placeholder>

```
