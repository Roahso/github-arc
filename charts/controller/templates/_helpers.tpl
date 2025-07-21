{{/*
Expand the name of the chart.
*/}}
{{- define "github-runner-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "github-runner-controller.fullname" -}}
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
{{- define "github-runner-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "github-runner-controller.labels" -}}
helm.sh/chart: {{ include "github-runner-controller.chart" . }}
{{ include "github-runner-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "github-runner-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "github-runner-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "github-runner-controller.serviceAccountName" -}}
{{- if .Values.controller.serviceAccount.create }}
{{- default (include "github-runner-controller.fullname" .) .Values.controller.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.controller.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the webhook service account to use
*/}}
{{- define "github-runner-controller.webhookServiceAccountName" -}}
{{- if .Values.webhook.serviceAccount.create }}
{{- default (printf "%s-webhook" (include "github-runner-controller.fullname" .)) .Values.webhook.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.webhook.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the metrics service account to use
*/}}
{{- define "github-runner-controller.metricsServiceAccountName" -}}
{{- if .Values.metrics.serviceAccount.create }}
{{- default (printf "%s-metrics" (include "github-runner-controller.fullname" .)) .Values.metrics.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.metrics.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name for the webhook.
*/}}
{{- define "github-runner-controller.webhook.fullname" -}}
{{- printf "%s-webhook" (include "github-runner-controller.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for the metrics.
*/}}
{{- define "github-runner-controller.metrics.fullname" -}}
{{- printf "%s-metrics" (include "github-runner-controller.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the secret for GitHub App private key
*/}}
{{- define "github-runner-controller.githubAppSecretName" -}}
{{- printf "%s-github-app-private-key" (include "github-runner-controller.fullname" .) }}
{{- end }} 