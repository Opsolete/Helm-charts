{{/* The runners' pod template, for the Deployment and the ScaledJob (runner.mode). */}}
{{- define "opsolete.runnerPod" -}}
metadata:
  labels:
    {{- include "opsolete.selectorLabels" (list . "runner") | nindent 4 }}
    {{- with .Values.runner.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
    {{- with .Values.runner.podAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  # Runners hold no identity: cloud credentials come per job from workspace variables.
  serviceAccountName: default
  automountServiceAccountToken: false
  # Service env vars would leak into every Terraform job.
  enableServiceLinks: false
  # The runner must be PID 1 to kill processes a job leaves behind (no shareProcessNamespace).
  shareProcessNamespace: false
  terminationGracePeriodSeconds: {{ .Values.runner.terminationGracePeriodSeconds }}
  {{- if eq .Values.runner.mode "scaledJob" }}
  restartPolicy: Never # a failed pod's job is queued again by the server (lease), not retried here
  {{- end }}
  {{- with .Values.runner.runtimeClassName }}
  runtimeClassName: {{ . }} # e.g. gvisor or kata: module code doesn't run on the node's kernel
  {{- end }}
  securityContext:
    {{- include "opsolete.podSecurityContext" 10001 | nindent 4 }}
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  containers:
    - name: runner
      image: "{{ .Values.runner.image.repository }}:{{ .Values.runner.image.tag | default .Chart.AppVersion }}"
      imagePullPolicy: {{ .Values.runner.image.pullPolicy }}
      securityContext:
        {{- include "opsolete.containerSecurityContext" . | nindent 8 }}
      env:
        - name: OPS_SERVER_URL
          value: {{ printf "http://%s.%s.svc:%v" (include "opsolete.fullname" .) .Release.Namespace .Values.service.port | quote }}
        - name: OPS_RUNNER_TOKEN
          valueFrom:
            secretKeyRef:
              name: {{ include "opsolete.secretName" . }}
              key: RUNNER_TOKEN
        - name: OPS_RUNNER_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        {{- if eq .Values.runner.mode "scaledJob" }}
        - name: OPS_RUNNER_ONCE # one job, then the pod ends
          value: "true"
        {{- end }}
        {{- range $k, $v := .Values.runner.env }}
        - name: {{ $k }}
          value: {{ $v | quote }}
        {{- end }}
      resources:
        {{- toYaml .Values.runner.resources | nindent 8 }}
      volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: plugin-cache
          mountPath: /home/runner/.terraform.d/plugin-cache
  volumes:
    - name: tmp
      emptyDir: {}
    - name: plugin-cache
      {{- with .Values.runner.pluginCache.existingClaim }}
      persistentVolumeClaim:
        claimName: {{ . }}
      {{- else }}
      emptyDir: {}
      {{- end }}
  {{- with .Values.runner.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.runner.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.runner.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
