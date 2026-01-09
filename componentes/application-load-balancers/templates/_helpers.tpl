{{/*
Expand the name of the chart.
*/}}
{{- define "load-balancers.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "load-balancers.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "load-balancers.labels" -}}
helm.sh/chart: {{ include "load-balancers.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for a specific load balancer
*/}}
{{- define "load-balancers.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}-lb-dummy
app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end }}
