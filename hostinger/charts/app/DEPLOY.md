# Deployment Guide

## Overview

This deployment includes a single Express.js server that:
- Serves static files (HTML, CSS, JS)
- Provides API endpoints
- Integrates with Google Drive for on-the-fly PDF serving

## Architecture

```
┌─────────────────────────────────────┐
│         Ingress (nginx)             │
├─────────────────────────────────────┤
│  /hultetvsf/*      → Service (3000) │
└─────────────────────────────────────┘
           ↓
    ┌──────────────┐
    │   Service    │
    ├──────────────┤
    │  Port 80     │ → App Container
    └──────────────┘
           ↓
    ┌──────────────────────────────┐
    │         Pod                  │
    ├──────────────────────────────┤
    │  Express Server (3000)       │
    │    ├─ Static files           │
    │    ├─ API endpoints          │
    │    └─ Google Drive proxy     │
    │  Volume: google-creds        │
    └──────────────────────────────┘
```

## Prerequisites

1. **Google OAuth Credentials (gauth pattern)**
   - Prepare `gauth.json` with `client_id`, `client_secret`, `refresh_token`
   - Optional: keep `google-credentials.json` for interactive/local fallback
   - See [SECRETS.md](SECRETS.md) for setup instructions

2. **Kubernetes Cluster**
   - Nginx Ingress Controller installed
   - Sealed Secrets or External Secrets Operator (optional but recommended)

## Deployment Steps

### 1. Set up Google Credentials Secret

**Option A: Using kubectl (quick test)**
```bash
kubectl create secret generic hultetvsf-app-google-credentials \
   --from-file=gauth.json=./gauth.json \
  --from-file=google-credentials.json=./google-credentials.json \
  -n your-namespace
```

**Option B: Using Sealed Secrets (production)**
```bash
kubectl create secret generic hultetvsf-app-google-credentials \
   --from-file=gauth.json=./gauth.json \
  --from-file=google-credentials.json=./google-credentials.json \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > templates/sealed-secret.yaml

# Then delete templates/secret.yaml
rm templates/secret.yaml
```

### 2. Update values.yaml

```yaml
google:
  credentials:
    installed:
      client_id: "your-client-id"
      project_id: "your-project-id"
      client_secret: "your-client-secret"
      redirect_uris: ["http://localhost"]
```

### 3. Deploy with Helm

```bash
# Install
helm install hultetvsf-app . -n your-namespace

# Or upgrade
helm upgrade --install hultetvsf-app . -n your-namespace

# With custom values
helm upgrade --install hultetvsf-app . \
  -f values-production.yaml \
  -n your-namespace
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n your-namespace

# Check logs
kubectl logs -f deployment/hultetvsf-app -c backend -n your-namespace
kubectl logs -f deployment/hultetvsf-app -c frontend -n your-namespace

# Test backend API
kubectl port-forward svc/hultetvsf-app 3000:3000 -n your-namespace
curl http://localhost:3000/health
curl http://localhost:3000/api/fetchMedlemmar
```

## API Endpoints

- `GET /health` - Health check
- `GET /api/fetchMedlemmar` - Fetch medlemmar spreadsheet data
- `GET /drive/*` - Proxy PDFs from Google Drive

## Accessing via Ingress

Once deployed:
- Application: `https://hultet-vsf.se/hultetvsf/`
- API Example: `https://hultet-vsf.se/hultetvsf/api/fetchMedlemmar`
- PDF Example: `https://hultet-vsf.se/hultetvsf/drive/protokoll/årsmöte2025.pdf`

## Troubleshooting

### Container fails to start
```bash
kubectl logs deployment/hultetvsf-app
```
Common issues:
- Missing Google credentials
- Invalid credentials format
- Google Drive API not enabled

### OAuth Refresh Token Invalid
If logs show `invalid_grant`, update the refresh token in `gauth.json` and re-run `./google-creds/deploy-secrets.sh`.

### API returns 404
- Check ingress configuration
- Verify path rewrite rules
- Test service directly with port-forward

## CI/CD

The GitHub Actions workflow will:
1. Build the Express server image
2. Push to GitHub Container Registry
3. Package and push Helm chart
4. Trigger ArgoCD sync (if configured)

Images:
- `ghcr.io/hultetvsf/app-hostinger:latest` - Express server serving static files and API

## Security Considerations

1. **Never commit secrets to Git**
   - Use Sealed Secrets or External Secrets Operator
   - Add `google-credentials.json` to `.gitignore`

2. **Credential Storage**
   - Store `gauth.json` in Kubernetes secret
   - Do not commit plaintext credential files

3. **Network Policies**
   - Consider restricting egress to Google APIs only

4. **Resource Limits**
   - Server has memory/CPU limits configured
   - Adjust based on usage patterns
