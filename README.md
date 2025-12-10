# 🧭 Todo App - GitOps Configuration Repository

[![CI Pipeline](https://github.com/Piyushbajpai11/todo-app-cicd/actions/workflows/ci-cd-pipeline.yml/badge.svg?branch=main)](https://github.com/Piyushbajpai11/todo-app-cicd/actions/workflows/ci-cd-pipeline.yml)  
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm)  
![Argo CD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=Argo&logoColor=white)  

This repository contains the **Kubernetes manifests** and **Helm charts** for deploying the Todo application across multiple environments using **GitOps** with **ArgoCD**.[web:43]

---

## 📋 Overview

This is the **GitOps configuration repository** that acts as the **single source of truth** for all Kubernetes deployments of the Todo app.[web:43]  
ArgoCD continuously monitors this repository and synchronizes the desired state from Git with the actual state in the Kubernetes clusters.[web:43]

---

## 🏁 Quick Start

1. Install ArgoCD on your Kubernetes cluster (refer to official docs).[web:46]  
2. Fork or clone this repository:
git clone https://github.com/Piyushbajpai11/todo-app-gitops.git
cd todo-app-gitops

text
3. Create the required namespaces:
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

text
4. Apply ArgoCD Application manifests:
kubectl apply -f argocd-apps/ -n argocd

text

---

## 🏗️ Repository Structure

```bash
.
├── helm-charts/
│ └── todo-app/
│ ├── Chart.yaml
│ ├── values.yaml
│ ├── values-dev.yaml
│ ├── values-staging.yaml
│ ├── values-prod.yaml
│ └── templates/
│ ├── deployment.yaml
│ ├── service.yaml
│ └── _helpers.tpl
├── argocd-apps/
│ ├── todo-app-dev.yaml
│ ├── todo-app-staging.yaml
│ └── todo-app-prod.yaml
└── README.md
```

text

This structure separates **chart logic** (templates) from **environment-specific configuration** (values-*.yaml), which follows Helm best practices for reusable charts.[web:44]

---

## 🌍 Environment Configuration

### Development Environment

| Parameter     | Value                                      |
|--------------|---------------------------------------------|
| Namespace    | `dev`                                      |
| Replicas     | 1                                          |
| Service Type | `ClusterIP` (internal only)                |
| Resources    | Minimal (50m CPU, 64Mi RAM)                |
| Auto-Sync    | Enabled                                    |
| Image Tag    | Updated automatically by CI pipeline       |

**values-dev.yaml**

replicaCount: 1
image:
tag: "dev"
service:
type: ClusterIP
resources:
limits:
cpu: 100m
memory: 128Mi

text

---

### Staging Environment

| Parameter     | Value                                      |
|--------------|---------------------------------------------|
| Namespace    | `staging`                                  |
| Replicas     | 2                                          |
| Service Type | `LoadBalancer` (public)                    |
| Resources    | Medium (75m CPU, 96Mi RAM)                 |
| Auto-Sync    | Enabled                                    |
| Image Tag    | Manually promoted from dev                 |

**values-staging.yaml**

replicaCount: 2
image:
tag: "staging"
service:
type: LoadBalancer
resources:
limits:
cpu: 150m
memory: 192Mi

text

---

### Production Environment

| Parameter      | Value                                      |
|----------------|---------------------------------------------|
| Namespace      | `prod`                                     |
| Replicas       | 3 (HPA: 3–10)                              |
| Service Type   | `LoadBalancer` (public)                    |
| Resources      | Full (100m CPU, 128Mi RAM)                 |
| Auto-Sync      | Disabled (manual approval)                 |
| Auto-Scaling   | Enabled (70% CPU utilization target)       |
| Image Tag      | Manually promoted from staging             |

**values-prod.yaml**

replicaCount: 3
image:
tag: "prod"
service:
type: LoadBalancer
autoscaling:
enabled: true
minReplicas: 3
maxReplicas: 10
resources:
limits:
cpu: 200m
memory: 256Mi

text

---

## 🔄 GitOps Workflow

### Automatic Deployment (Development)

Code Push → GitHub Actions → Build Image → Push to ECR
→ Update values-dev.yaml → ArgoCD Auto-Sync → Deployed!

text

Development is fully automated: any merge to `main` in the app repo triggers the CI/CD workflow, which builds and pushes a new image, updates the dev values file, and lets ArgoCD sync it into the `dev` namespace.[web:49]

### Manual Promotion to Staging

1. Test dev environment
kubectl get pods -n dev

2. Promote tested version to staging
sed -i 's/tag: ".*"/tag: "abc1234"/' helm-charts/todo-app/values-staging.yaml
git add helm-charts/todo-app/values-staging.yaml
git commit -m "Promote abc1234 to staging"
git push

3. ArgoCD auto-syncs staging
4. Verify staging deployment
kubectl get pods -n staging

text

### Manual Promotion to Production

1. Test staging environment
curl http://<staging-lb>:3000

2. Promote to production
sed -i 's/tag: ".*"/tag: "abc1234"/' helm-charts/todo-app/values-prod.yaml
git add helm-charts/todo-app/values-prod.yaml
git commit -m "Promote abc1234 to production"
git push

3. Manually sync in ArgoCD UI (safety gate)
4. Monitor rollout
kubectl rollout status deployment/todo-app-prod -n prod

text

This pipeline gives fast feedback in dev while enforcing manual approval before production changes.

---

## 🎯 ArgoCD Application Configuration

### Dev Application (Auto-Sync Enabled)

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: todo-app-dev
namespace: argocd
spec:
project: default
source:
repoURL: https://github.com/Piyushbajpai11/todo-app-gitops.git
targetRevision: main
path: helm-charts/todo-app
helm:
valueFiles:
- values-dev.yaml
destination:
server: https://kubernetes.default.svc
namespace: dev
syncPolicy:
automated:
prune: true
selfHeal: true

text

### Staging Application (Auto-Sync Enabled

Same as dev, but with `values-staging.yaml` and `namespace: staging`.

### Production Application (Manual Sync)

Production Application snippet
syncPolicy:
syncOptions:
- CreateNamespace=true

No automated sync block → manual approval via ArgoCD UI
text

ArgoCD Applications declare which Git path, Helm values file, and target namespace should be used for each environment.[web:43]

---

## 🔐 Security Considerations

### Image Pull Secrets

kubectl create secret docker-registry ecr-secret
--docker-server=098347674973.dkr.ecr.ap-south-1.amazonaws.com
--docker-username=AWS
--docker-password=$(aws ecr get-login-password --region ap-south-1)
--namespace=<namespace>

text

Create separate secrets per namespace (`dev`, `staging`, `prod`) or use imagePullSecrets at the ServiceAccount level for better reuse.[web:44]

### GitOps Principles

- ✅ Single Source of Truth in Git  
- ✅ Versioned, auditable changes  
- ✅ Declarative configuration for all environments  
- ✅ Automated reconciliation by ArgoCD  
- ✅ Clear promotion history between dev → staging → prod  

---

## 📊 Monitoring Deployments

### Check Application Status

All ArgoCD applications
kubectl get applications -n argocd

Specific application details
kubectl describe application todo-app-dev -n argocd

text

### Check Pod Status

kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n prod

text

### View Deployment History

Git history for dev values
git log --oneline helm-charts/todo-app/values-dev.yaml

text

Git logs provide a full audit trail for configuration changes, while the ArgoCD UI shows sync and health history per Application.[web:43]

---

## 🚨 Rollback Procedures

### Rollback via Git (Preferred)

Identify the commit to roll back to
git log --oneline helm-charts/todo-app/values-prod.yaml

Revert to a previous version
git revert <commit-hash>
git push

text

ArgoCD will reconcile the cluster back to the reverted Git state, keeping Git and cluster in sync.[web:43]

### Rollback via ArgoCD UI

1. Open the ArgoCD dashboard.  
2. Select the target application.  
3. Open **History and Rollback**.  
4. Choose a previous revision and click **Rollback**.

### Emergency Rollback

kubectl rollout undo deployment/todo-app-prod -n prod

text

After an emergency rollback, update Git to match the rolled-back state to keep Git as the single source of truth.[web:43]

---

## 🔧 Helm Chart Customization

### Render / Test Values Locally

helm template todo-app ./helm-charts/todo-app
-f helm-charts/todo-app/values-dev.yaml

text

### Manual Installation (Bypassing ArgoCD)

helm install todo-app ./helm-charts/todo-app
-f helm-charts/todo-app/values-staging.yaml
-n staging

text

### Validate Charts

helm lint helm-charts/todo-app
helm install --dry-run --debug todo-app ./helm-charts/todo-app

text

Linting and dry runs help catch template errors before pushing changes that ArgoCD will consume.[web:44]

---

## 📈 Best Practices Implemented

- ✅ Separation of concerns: app code vs. environment config  
- ✅ Single Helm chart with environment-specific values files  
- ✅ Immutable image tags (e.g., Git SHA) for traceability  
- ✅ Progressive delivery: dev → staging → prod promotions  
- ✅ Manual approval gate for production syncs  
- ✅ Resource requests/limits and autoscaling for reliability  
- ✅ Health checks configured via Kubernetes probes  

---

## 🔗 Related Links

- **Application Repository:** [todo-app-cicd](https://github.com/Piyushbajpai11/todo-app-cicd)  
- **ArgoCD Documentation:** https://argo-cd.readthedocs.io/[web:46]  
- **Helm Documentation:** https://helm.sh/docs/[web:44]  

---

## 📝 Maintenance Tasks

### Update Base Image

- Update the application Dockerfile in `todo-app-cicd`.  
- Let the CI pipeline build and push the new image.  
- Ensure the correct image tag is referenced in the corresponding values file(s).

### Update Helm Chart

git add helm-charts/
git commit -m "Update Helm chart to v2.0.0"
git push

text

ArgoCD detects chart or values changes and reconciles the target environments to the new desired state.[web:43]

---

## 👤 Author

**Piyush Bajpai**  
GitHub: [@Piyushbajpai11](https://github.com/Piyushbajpai11)  

> This repository is part of a complete DevOps project demonstrating **GitOps principles** with **ArgoCD**.