# helm2cf

The goal of this tool is to reuse as much of a project's Helm magic to (ideally) extract working Cloud foundry `manifest.yml` files which can be used as a starting point to deploy the charts to a Cloud foundry environment.

# expectations and rationale

There are a lot of similarities but also differences between Kubernetes and Cloud foundry runtime environments. The generated `manifest` files in most cases cannot be used without tweaking first! There's probably a nice AI/ML project hidden in here if we'd want to get flawless conversion between Helm and CF. The more Kubernetes specific constructs you use, the more tweaking youll have to do. 

With that said, this project can save you massive amounts of time when tasked with converting a Helm chart to a semi-usable set of CF manifests. You also get to use existing Helm templates and logic.

Unintentionally it might fill a gap in the CF world, namely the lack of nice templating and deployment definition, Helm :)

# usage

```
$ docker run --rm -it \
    -v $(pwd)/helm:/helm 
    -v $(pwd)/manifests:/manifests 
    helm2cf:latest --values /helm/my.values.yaml
```

## volume mounts

| path | description |
|------|-------------|
| /helm | mount your helm chart on this path |
| /manifests | any CF manifests will be saved at this location |


# todo

- Make the CF `manifest.yml` template a parameter. Currently hardcoded
- Generic search and replace map for known wrong values
- Generate network policies commands based on Helm structure
- Generate route config based on Ingress discovered annotations

## discussion

### ingress
since k8s ingress is usually configured by annotation it's a challenge to figure this out programmatically from the Helm directly. It would be very cool though if we can deduce a reverse proxy setting based on at least the `nginx` ingress controller.

### networking
Network policies are required for container-to-container networking in Cloud foundry. These should be generated based on the Helm charts.

# author

- Andy Lo-A-Foe <andy.lo-a-foe@philips.com>

# license

License is MIT
