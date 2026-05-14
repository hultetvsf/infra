# Secrets Management for Backend API

The backend API supports `gauth.json` refresh-token mode (same pattern as your fakturor project).

## Setup Google Credentials Secret

### Option 1: Using Sealed Secrets (Recommended for GitOps)

1. Install kubeseal CLI:
   ```bash
   brew install kubeseal  # macOS
   # or download from https://github.com/bitnami-labs/sealed-secrets/releases
   ```

2. Create the secret and seal it:
   ```bash
   kubectl create secret generic hultetvsf-app-google-credentials \
  --from-file=gauth.json=./gauth.json \
     --from-file=google-credentials.json=./google-credentials.json \
     --dry-run=client -o yaml | \
     kubeseal -o yaml > .helm/hultetvsf-app/templates/sealed-secret.yaml
   ```

3. Commit the sealed secret to Git (it's encrypted and safe)

4. Delete the `secret.yaml` template and use sealed secret instead

### Option 2: Manual Secret Creation

Create the secret manually in your cluster:

```bash
kubectl create secret generic hultetvsf-app-google-credentials \
  --from-file=gauth.json=./gauth.json \
  --from-file=google-credentials.json=./google-credentials.json \
  -n <your-namespace>
```

Then update `values.yaml` to disable secret creation:

```yaml
google:
  createSecret: false
```

### Option 3: External Secrets Operator

Use External Secrets Operator to sync from cloud secret managers:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: hultetvsf-app-google-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: hultetvsf-app-google-credentials
  data:
    - secretKey: google-credentials.json
      remoteRef:
        key: hultetvsf/google-credentials
```

## GitHub Actions Secrets

For the CI/CD pipeline, add these secrets to your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
   - `GOOGLE_PROJECT_ID`

These will be used to inject credentials during the build process if needed.

## Ingress Configuration for Backend API

The backend API will be exposed at `/hultetvsf/api/*`. Update your ingress to route these requests to the backend service:

```yaml
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  rules:
    - host: hultet-vsf.se
      http:
        paths:
          # Frontend (static files)
          - path: /hultetvsf/(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: hultetvsf-app
                port:
                  name: http
          # Backend API
          - path: /hultetvsf/api/(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: hultetvsf-app
                port:
                  name: api
```

## Testing Locally

To test the backend locally:

1. Ensure `google-credentials.json` exists in the project root
2. Run: `node server.js`
3. Access: `http://localhost:3000/api/fetchMedlemmar`

## Notes

- `gauth.json` mode uses a fixed refresh token, matching the `fakturor.js` pattern.
- `tokens.json` is now fallback mode only.
