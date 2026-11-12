# Opsolete Helm charts

```sh
helm repo add opsolete https://opsolete.github.io/Helm-charts
helm install opsolete opsolete/opsolete -f my-values.yaml
# or, as an OCI artifact:
helm install opsolete oci://ghcr.io/opsolete/charts/opsolete -f my-values.yaml
```

| Chart | Description |
|---|---|
| [opsolete](charts/opsolete) | Opsolete app + runners ([docs](https://github.com/Opsolete/Opsolete)) |

## Upgrading

- **opsolete chart 0.3.0 (app 0.8.0):** runners have their own registered tokens. The chart keeps the `RUNNER_TOKEN` secret key and registers it as runner `runner.name` (default `k8s`) in `runner.pool` (default `default`) with an init container before the app starts, so nothing changes for a single runner Deployment. For several pools, run a release per pool with its own `RUNNER_TOKEN`, `runner.name` and `runner.pool`, and pick the pool in each project's settings.

## Development

- CI (`.github/workflows/charts.yml`) runs `ct lint`, kubeconform and `ct install` on kind (with a throwaway Postgres) for every PR, using each chart's `ci/*-values.yaml`.
- Bump `version` in `Chart.yaml` on every chart change (CI enforces it on PRs). A merge to `main` publishes new versions as GitHub releases and updates `index.yaml` on the `gh-pages` branch, and pushes them to `oci://ghcr.io/opsolete/charts`.

Locally: `ct lint --config ct.yaml --all` and `ct install --config ct.yaml --all` against a kind cluster.
