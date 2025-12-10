[![CI Pipeline](https://github.com/Piyushbajpai11/todo-app-cicd/actions/workflows/ci-cd-pipeline.yml/badge.svg?branch=main)](https://github.com/Piyushbajpai11/todo-app-cicd/actions/workflows/ci-cd-pipeline.yml)[web:21]  
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm)[web:15]  
![Argo CD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=Argo&logoColor=white)[web:7]  

This repository contains the **Kubernetes manifests** and **Helm charts** for deploying the Todo application across multiple environments using **GitOps principles** with **ArgoCD**.

---

## 📋 Overview

This is the **GitOps repository** that serves as the **single source of truth** for all Kubernetes deployments.[web:7]  
ArgoCD continuously monitors this repository and automatically synchronizes the desired state with the actual cluster state.[web:7]  

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

---

## 🌍 Environment Configuration

### Development Environment

| Parameter | Value |
|------------|--------|
| Namespace | `dev` |
| Replicas | 1 |
| Service Type | `ClusterIP` |
| Resources | Minimal (50m CPU, 64Mi RAM) |
| Auto-Sync | Enabled |
| Image Tag | Auto-updated by CI pipeline |

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

| Parameter | Value |
|------------|--------|
| Namespace | `staging` |
| Replicas | 2 |
| Service Type | `LoadBalancer` |
| Resources | Medium (75m CPU, 96Mi RAM) |
| Auto-Sync | Enabled |
| Image Tag | Manually promoted from dev |

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

| Parameter | Value |
|------------|--------|
| Namespace | `prod` |
| Replicas | 3 (HPA: 3–10) |
| Service Type | `LoadBalancer` |
| Resources | Full (100m CPU, 128Mi RAM) |
| Auto-Sync | Disabled (manual approval required) |
| Auto-Scaling | Enabled (70% CPU threshold) |
| Image Tag | Manually promoted from staging |

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

3. Manually sync in ArgoCD UI
4. Monitor rollout
kubectl rollout status deployment/todo-app-prod -n prod

text

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

### Staging Application (Auto-Sync Enabled)

Configuration is similar to dev, using `values-staging.yaml`.

### Production Application (Manual Sync)

syncPolicy:
syncOptions:

- CreateNamespace=true

text

---

## 🔐 Security Considerations

### Image Pull Secrets

kubectl create secret docker-registry ecr-secret
--docker-server=098347674973.dkr.ecr.ap-south-1.amazonaws.com
--docker-username=AWS
--docker-password=$(aws ecr get-login-password --region ap-south-1)
--namespace=<namespace>

text

### GitOps Principles

✅ Single Source of Truth  
✅ Version Control  
✅ Declarative Configuration  
✅ Automated Sync  
✅ Full Audit Trail  

---

## 📊 Monitoring Deployments

Check Application Status:
kubectl get applications -n argocd
kubectl describe application todo-app-dev -n argocd

text

Check Pod Status:
kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n prod

text

View Deployment History:
git log --oneline helm-charts/todo-app/values-dev.yaml

text

---

## 🚨 Rollback Procedures

### Rollback via Git

git log --oneline helm-charts/todo-app/values-prod.yaml
git revert <commit-hash>
git push

text

### Rollback via ArgoCD UI

1. Open ArgoCD Dashboard  
2. Select the application  
3. Go to **History and Rollback**  
4. Select previous revision → **Rollback**

### Emergency Rollback

kubectl rollout undo deployment/todo-app-prod -n prod

text

---

## 🔧 Helm Chart Customization

### Test or Override Values

helm template todo-app ./helm-charts/todo-app -f helm-charts/todo-app/values-dev.yaml

text

### Manual Installation (Bypassing ArgoCD)

helm install todo-app ./helm-charts/todo-app
-f helm-charts/todo-app/values-staging.yaml
-n staging

text

### Validate Changes

helm lint helm-charts/todo-app
helm install --dry-run --debug todo-app ./helm-charts/todo-app

text

---

## 📈 Best Practices Implemented

- ✅ Separation of concerns (code vs config)
- ✅ Environment parity (one chart, multiple values)
- ✅ Immutable image tags using Git SHA
- ✅ Progressive delivery (dev → staging → prod)
- ✅ Safety gates with manual approvals
- ✅ Resource limits and auto-scaling
- ✅ Health checks for resilience

---

## 🔗 Related Links

- **Application Repository:** [todo-app-cicd](https://github.com/Piyushbajpai11/todo-app-cicd)  
- **ArgoCD Documentation:** [https://argo-cd.readthedocs.io/](https://argo-cd.readthedocs.io/)[web:7]  
- **Helm Documentation:** [https://helm.sh/docs/](https://helm.sh/docs/)[web:4]  

---

## 📝 Maintenance Tasks

### Update Base Image

Update Dockerfile in the application repo
CI pipeline will rebuild and push automatically
text

### Update Helm Chart

git add helm-charts/
git commit -m "Update Helm chart to v2.0.0"
git push

text
ArgoCD will detect and sync these changes automatically.[web:7]  

---

## 👤 Author

**Piyush Bajpai**  
GitHub: [@Piyushbajpai11](https://github.com/Piyushbajpai11)  

> This repository is part of a complete DevOps project demonstrating **GitOps principles** with **ArgoCD**.