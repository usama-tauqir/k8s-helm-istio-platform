{{/*
common.name: chart ka naam, 63 characters tak
*/}}
{{- define "common.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
common.fullname: fullnameOverride ho to woh, warna chart ka naam.
Release ka naam jaan bujh kar NAHI joda, kyunki app "db" aur "redis" naam hardcoded dhoondhti hai.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "common.name" . -}}
{{- end -}}
{{- end }}

{{/*
common.selectorLabels: sirf woh labels jo kabhi nahi badalte. version yahan KABHI nahi.
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
common.labels: poore labels (selector labels + baqi)
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
common.securityContext: container ki security. readOnlyRootFilesystem values se aata hai.
*/}}
{{- define "common.securityContext" -}}
{{- $sc := .Values.securityContext | default dict -}}
runAsNonRoot: true
allowPrivilegeEscalation: false
readOnlyRootFilesystem: {{ $sc.readOnlyRootFilesystem | default false }}
capabilities:
  drop: ["ALL"]
{{- end }}
