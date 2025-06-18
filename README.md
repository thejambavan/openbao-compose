# Docker Compose for test/dev OpenBao service

This will generate TLS certs for you and will configure RAFT, so it's a reasonably good approximation of what runs in Prod. It has an HAProxy frontend proxy, also with its own TLS cert.

1. Bring up with `docker compose `

```
docker compose -f openbao-cluster.yaml -p openbao up --remove-orphans --build
```

2. Initialise/Unseal

Because I couldn't get the docker `entrypoint` to fire correctly on bringup, you can do this manually instead 🙂

```
docker exec -it secrets01 sh -c '/openbao/tls/auto-init.sh $HOSTNAME; echo $HOSTNAME'
docker exec -it secrets02 sh -c '/openbao/tls/auto-init.sh $HOSTNAME; echo $HOSTNAME'
docker exec -it secrets03 sh -c '/openbao/tls/auto-init.sh $HOSTNAME; echo $HOSTNAME'

```

