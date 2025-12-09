#!/bin/bash
# Run this script from gitops-repo directory

cd ~/OneDrive/Desktop/devops-cicd-project/gitops-repo

# Create directory structure
mkdir -p helm-charts/todo-app/templates
mkdir -p helm-charts/todo-app/values

# ======================
# 1. Chart.yaml
# ======================
cat > helm-charts/todo-app/Chart.yaml << 'EOF'
apiVersion: v2
name: todo-app
description: A Helm chart for Todo Application
type: application
version: 1.0.0
appVersion: "1.0.0"
maintainers:
  - name: Piyush Bajpai
    email: your-email@example.com
EOF

# ======================
# 2. values.yaml (default)
# ======================
cat > helm-charts/todo-app/values.yaml << 'EOF'
# Default values for todo-app
replicaCount: 2

image:
  repository: 098347674973.dkr.ecr.ap-south-1.amazonaws.com/todo-app
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: LoadBalancer
  port: 3000
  targetPort: 3000

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

env:
  - name: NODE_ENV
    value: "production"
EOF

# ======================
# 3. values-dev.yaml
# ======================
cat > helm-charts/todo-app/values-dev.yaml << 'EOF'
# Development environment values
replicaCount: 1

image:
  repository: 098347674973.dkr.ecr.ap-south-1.amazonaws.com/todo-app
  tag: "dev"

service:
  type: ClusterIP

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

env:
  - name: NODE_ENV
    value: "development"
EOF

# ======================
# 4. values-staging.yaml
# ======================
cat > helm-charts/todo-app/values-staging.yaml << 'EOF'
# Staging environment values
replicaCount: 2

image:
  repository: 098347674973.dkr.ecr.ap-south-1.amazonaws.com/todo-app
  tag: "staging"

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 150m
    memory: 192Mi
  requests:
    cpu: 75m
    memory: 96Mi

env:
  - name: NODE_ENV
    value: "staging"
EOF

# ======================
# 5. values-prod.yaml
# ======================
cat > helm-charts/todo-app/values-prod.yaml << 'EOF'
# Production environment values
replicaCount: 3

image:
  repository: 098347674973.dkr.ecr.ap-south-1.amazonaws.com/todo-app
  tag: "prod"

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  - name: NODE_ENV
    value: "production"
EOF

# ======================
# 6. templates/_helpers.tpl
# ======================
cat > helm-charts/todo-app/templates/_helpers.tpl << 'EOF'
{{/*
Expand the name of the chart.
*/}}
{{- define "todo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "todo-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "todo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "todo-app.labels" -}}
helm.sh/chart: {{ include "todo-app.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "todo-app.selectorLabels" -}}
EOF

# ======================
# 7. templates/deployment.yaml
# ======================
cat > helm-charts/todo-app/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todo-app.fullname" . }}
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "todo-app.selectorLabels" . | nindent 6 }}
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        env:
          {{- toYaml .Values.env | nindent 10 }}
EOF

# ======================
# 8. templates/service.yaml
# ======================
cat > helm-charts/todo-app/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "todo-app.fullname" . }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "todo-app.selectorLabels" . | nindent 4 }}
EOF

echo "✅ All Helm chart files created successfully!"
echo ""
echo "File structure:"
tree helm-charts/ 2>/dev/null || find helm-charts/ -type f
echo "1. Review the files"
echo "2. Run: git add ."
echo "3. Run: git commit -m 'Add complete Helm chart structure'"
echo "4. Run: git push"
echo ""
echo "Next steps:"
    metadata:
      labels:
        {{- include "todo-app.selectorLabels" . | nindent 8 }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
spec:
app.kubernetes.io/name: {{ include "todo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

