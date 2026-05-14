{{- /* Common chart helpers */ -}}
{{- define "hultetvsf-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hultetvsf-app.labels" -}}
app.kubernetes.io/name: {{ include "hultetvsf-app.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: Helm
{{- end -}}

{{- define "hultetvsf-app.name" -}}
{{- default .Chart.Name .Chart.Name -}}
{{- end -}}
