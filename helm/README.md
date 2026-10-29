# Helm: voting-app

Poori voting app (vote, result, worker, redis, postgres) ek umbrella Helm chart se deploy hoti hai.

## Chart architecture

```mermaid
flowchart TD
    U["voting-app (umbrella)<br/>global values, Secret, hooks, tests, schema"]
    U --> V["vote<br/>Deployment + Service + HPA"]
    U --> R["result<br/>Deployment + Service"]
    U --> W["worker<br/>Deployment + initContainers"]
    U --> RE["redis<br/>Deployment + Service<br/>condition: redis.enabled"]
    U --> D["db<br/>StatefulSet + Service + headless<br/>condition: db.enabled"]
    C["common (library chart)<br/>name, fullname, labels,<br/>selectorLabels, securityContext"]
    V -.uses.-> C
    R -.uses.-> C
    W -.uses.-> C
    RE -.uses.-> C
    D -.uses.-> C
    D -. import-values: service.port .-> U
```

```
helm/
├── common/                  # library chart (type: library), sirf helpers
├── voting-app/              # umbrella chart
│   ├── Chart.yaml           # 5 dependencies, conditions, import-values
│   ├── values.yaml          # defaults + global.dbSecretName
│   ├── values-dev.yaml      # 1 replica, no persistence, seed on
│   ├── values-prod.yaml     # 3 replicas + HPA, PVC, backup on
│   ├── values.schema.json   # validation (password, replicas, size)
│   ├── templates/
│   │   ├── secret.yaml      # DB credentials (password required)
│   │   ├── seed-job.yaml    # post-install hook: fake votes
│   │   ├── backup-job.yaml  # pre-upgrade hook: pg_dump
│   │   └── tests/           # helm test: vote, result, db
│   └── charts/              # vote, result, worker, redis, db subcharts
└── starters/
    └── microservice-starter # `helm create <name> --starter` template
```

## Install

**1. Local (repo se)**
```bash
cd helm
for c in vote result worker redis db; do helm dependency update voting-app/charts/$c; done
helm dependency update voting-app
helm install voting ./voting-app -n voting --create-namespace \
  -f voting-app/values-dev.yaml --set dbAuth.password=<password>
```

**2. OCI registry (GitHub Container Registry)**
```bash
helm install voting oci://ghcr.io/usama-tauqir/charts/voting-app --version 0.1.0 \
  -n voting --create-namespace --set dbAuth.password=<password>
```

**3. Helm repo (GitHub Pages)**
```bash
helm repo add usama https://usama-tauqir.github.io/helm-charts
helm repo update
helm install voting usama/voting-app -n voting --create-namespace --set dbAuth.password=<password>
```

Chart PGP se signed hai:
```bash
helm pull usama/voting-app --version 0.1.0 --verify --keyring pubring.gpg
```

## Operate

```bash
helm test voting -n voting --logs
helm diff upgrade voting ./voting-app -n voting -f voting-app/values-prod.yaml --set dbAuth.password=<password>
helm upgrade voting ./voting-app -n voting -f voting-app/values-prod.yaml --set dbAuth.password=<password>
helm history voting -n voting
helm rollback voting 1 -n voting
```

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `global.dbSecretName` | `voting-db-secret` | Secret ka naam; result, worker, db sab yahin se credentials lete hain |
| `dbAuth.username` | `postgres` | Postgres user |
| `dbAuth.password` | `""` | **Required**, kam az kam 6 characters (schema) |
| `vote.replicaCount` | `2` | 1 se 10 (schema); HPA on ho to ignore |
| `vote.env.OPTION_A` / `OPTION_B` | `Cats` / `Dogs` | Vote ke do options (required) |
| `vote.autoscaling.enabled` | `false` | HPA (metrics-server chahiye) |
| `redis.enabled` | `true` | Redis subchart on/off |
| `db.enabled` | `true` | Postgres subchart on/off |
| `db.persistence.enabled` | `true` | `false` = emptyDir (data pod ke saath khatam) |
| `db.persistence.size` | `1Gi` | Pattern `^[0-9]+Gi$` (schema) |
| `seed.enabled` | `false` | post-install hook se fake votes |
| `seed.concurrency` | `5` | Ek waqt mein kitni seed requests |
| `backup.enabled` | `false` | pre-upgrade hook se `pg_dump` |
| `backup.existingClaim` | `""` | Backup ke liye PVC; khali = emptyDir |

## Design decisions

- **Library chart (`common`)**: labels, naam aur securityContext ek jagah; har subchart same standard follow karta hai.
- **Selector mein `version` label nahi**: Deployment selector immutable hai, aur Istio canary (v1/v2) ke liye ek Service dono versions ko select kare.
- **`fullnameOverride`**: app code mein hostnames `db` aur `redis` hardcoded hain, isliye Service names fixed.
- **db = StatefulSet**: `volumeClaimTemplates` + headless Service. Persistence on/off badalna `volumeClaimTemplates` badalta hai, jo Kubernetes upgrade par allow nahi karta; `helm diff` yeh pehle dikha deta hai.
- **Hooks**: seed `post-install` (app ban jane ke baad, sirf pehli dafa); backup `pre-upgrade` (badlaav se pehle).

## Known limitations (aage ke phases)

- result/worker code mein DB password hardcoded (`postgres`) hai: Phase 8 mein env/External Secrets.
- Images abhi local (`voting/*:1.0`): Phase 6 CI inhein GHCR par push karegi.
- redis official image root se chalti hai: Kyverno phase mein policy/exception.
