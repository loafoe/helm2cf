# helm2cf

The goal of this tool is to reuse as much of a project's Helm magic to (ideally) extract working Cloud foundry `manifest.yml` files which can be used as a starting point to deploy the charts to a Cloud foundry environment. 

# rationale and expectations

There are a lot of similarities and differences between Kubernetes and Cloud foundry runtime environments. Generated `manifest` files in many cases cannot be used without further tweaking! There's probably a nice AI/ML project hidden in here if we'd want to get flawless conversion between Helm and CF. Focus of the project is currently to map `Deployment` resources to CF apps.
Many of the Kubernetes resource types do not map or are not relevant in Cloud foundry.

With that said, this project can save you massive amounts of time when tasked with turning a Helm chart into a set of CF app manifests. Unintentionally, it might fill a gap in the CF world, namely the lack of nice templating and deployment definition tool: Helm 🙈

# usage

```
$ mkdir -p generated-manifests
$ docker run --rm -it \
    -v /path/to/your-helm:/helm 
    -v $(pwd)/generated-manifests:/manifests 
    helm2cf:latest --values /helm/my.values.yaml
```

## volume mounts

| path | description |
|------|-------------|
| /helm | mount your helm chart on this path |
| /manifests | any CF manifests will be saved at this location |

## parameters
Parameters passed to docker run will be appended to the `helm template` rendering command inside the container. Typically you pass a `--values` yaml which contains your configuration or global overrides.

# todo
- Make the CF `manifest.yml` template a parameter. Currently hardcoded
- Convert `StatefulSets` and `DaemonSets`. Currently only `Deployments` are evaluated.
- Generic search and replace map for known wrong values
- Generate network policies commands based on Helm structure
- Generate route config based on Ingress discovered annotations

## discussion

### ingress
since k8s ingress is usually configured by annotation it's a challenge to figure this out programmatically from the Helm directly. It would be very cool though if we can deduce a reverse proxy setting based on at least the `nginx` ingress controller.

### networking
Network policies are required for container-to-container networking in Cloud foundry. These should be generated based on the Helm charts.

### persistent volumes
Workloads which rely heavily on persistent volumes will be hard to convert as Cloud foundry deployments typically do not support volume attachments.

# author

- Andy Lo-A-Foe <andy.lo-a-foe@philips.com>

# license

License is MIT
