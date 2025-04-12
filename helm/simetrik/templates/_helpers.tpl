{{/*
Common labels
*/}}
{{- define "simetrik.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Server labels
*/}}
{{- define "simetrik.server.labels" -}}
{{ include "simetrik.labels" . }}
app.kubernetes.io/name: {{ .Values.server.name }}
{{- end }}

{{/*
Dashboard labels
*/}}
{{- define "simetrik.dashboard.labels" -}}
{{ include "simetrik.labels" . }}
app.kubernetes.io/name: {{ .Values.dashboard.name }}
{{- end }}
