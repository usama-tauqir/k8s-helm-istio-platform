{{/*
common.name: chart ka naam, 63 characters tak
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
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

{{/*
common.podLabels: pod ke labels = selector labels + version.
Istio/Kiali "version" label se v1/v2 pehchante hain (DestinationRule subsets, graph).
*/}}
{{- define "common.podLabels" -}}
{{ include "common.selectorLabels" . }}
version: {{ .Values.version | default "v1" | quote }}
{{- end }}

{{/*
common.serviceAccountName: har workload ki apni identity.
Istio AuthorizationPolicy isi se pehchanti hai: cluster.local/ns/<ns>/sa/<naam>
*/}}
{{- define "common.serviceAccountName" -}}
{{- $sa := .Values.serviceAccount | default dict -}}
{{- default (include "common.fullname" .) $sa.name -}}
{{- end }}

{{/*
common.serviceAccount: poora ServiceAccount resource. App ko Kubernetes API nahi chahiye,
isliye token mount band (Istio sidecar ka apna alag token hota hai).
*/}}
{{- define "common.serviceAccount" -}}
{{- $sa := .Values.serviceAccount | default dict -}}
{{- if (hasKey $sa "create" | ternary $sa.create true) }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
automountServiceAccountToken: false
{{- end }}
{{- end }}
