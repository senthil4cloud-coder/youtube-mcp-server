# Interactive Cloud Run Deployment

Two interactive deployment scripts are provided to make deploying to Google Cloud Run easier. Choose the one for your operating system.

## Windows Users - PowerShell Script

### Prerequisites
- PowerShell 5.0 or higher
- Google Cloud SDK installed and configured
- Docker installed
- gcloud CLI authenticated (`gcloud auth login`)

### Run the Interactive Deployment

```powershell
# Make sure you're in the project directory
cd C:\code\youtube-mcp-server

# Run the deployment script
.\deploy-cloudrun.ps1
```

The script will interactively ask for:
1. **YouTube API Key** - Your Google API key
2. **Channel ID** - Your YouTube channel ID (format: UC_xxxxx)
3. **GCP Project ID** - Your Google Cloud project (default: emerging-tech-nation)
4. **Service Name** - Cloud Run service name (default: youtube-mcp-server)
5. **Region** - Choose from 5 options (default: us-central1)
6. **Memory** - RAM allocation (default: 512Mi)
7. **CPU** - CPU cores (default: 1)
8. **Timeout** - Request timeout in seconds (default: 3600)
9. **Public Access** - Allow unauthenticated requests (default: yes)

After confirming, it will deploy and show you the service URL.

### Example Output

```
╔════════════════════════════════════════════════════════════╗
║   YouTube MCP Server - Google Cloud Run Deployment         ║
╚════════════════════════════════════════════════════════════╝

YouTube API Key : AIzaSyCaCmIf-8auu0jhVuLUB0tkWqGTK5t4Vsc
YouTube Channel ID (e.g., UC_xxxxx) : UC_uqN7g9WoTcx6mKJugydAQ
GCP Project ID [emerging-tech-nation] : 
Cloud Run Service Name [youtube-mcp-server] : 
...
```

---

## Linux / Mac Users - Bash Script

### Prerequisites
- Bash 4.0 or higher
- Google Cloud SDK installed and configured
- Docker installed
- gcloud CLI authenticated (`gcloud auth login`)

### Run the Interactive Deployment

```bash
# Make sure you're in the project directory
cd /path/to/youtube-mcp-server

# Make script executable (first time only)
chmod +x deploy-cloudrun.sh

# Run the deployment script
./deploy-cloudrun.sh
```

The script will interactively ask for the same information as the PowerShell version.

---

## What the Scripts Do

1. ✅ Validate all inputs (API key format, channel ID format, etc.)
2. ✅ Show a summary of deployment configuration
3. ✅ Ask for confirmation before deploying
4. ✅ Build and push Docker image to Google Container Registry
5. ✅ Deploy to Cloud Run with all parameters
6. ✅ Display the service URL
7. ✅ Show testing and troubleshooting commands

---

## After Deployment

Once deployment is complete, you'll see:

```
╔════════════════════════════════════════════════════════════╗
║         ✅ DEPLOYMENT SUCCESSFUL!                         ║
╚════════════════════════════════════════════════════════════╝

Getting your service URL...

https://youtube-mcp-server-340920787097.us-central1.run.app
```

### Test Your Service

```bash
# Health check
curl https://youtube-mcp-server-340920787097.us-central1.run.app/health

# Readiness check
curl https://youtube-mcp-server-340920787097.us-central1.run.app/ready
```

### View Logs

```bash
gcloud run logs read youtube-mcp-server --region us-central1 --limit 50
```

---

## Troubleshooting

### "gcloud: command not found"
Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install

### "Permission denied" when pushing Docker image
Run: `gcloud auth configure-docker`

### Script won't execute (Linux/Mac)
Make it executable: `chmod +x deploy-cloudrun.sh`

### Validation errors
- **API Key**: Must be 20+ characters
- **Channel ID**: Must start with "UC" followed by alphanumeric characters
- **Memory**: Must be 256Mi, 512Mi, 1Gi, 2Gi, or 4Gi
- **CPU**: Must be 1, 2, 4, or 8
- **Timeout**: Must be 1-3600 seconds

---

## Manual Deployment (Without Script)

If you prefer manual deployment, see [DEPLOYMENT.md](DEPLOYMENT.md)

---

## FAQ

**Q: Can I change settings after deployment?**  
A: Yes! Run the script again with different settings, or use:
```bash
gcloud run deploy youtube-mcp-server \
  --region us-central1 \
  --set-env-vars YOUTUBE_API_KEY=new_key,CHANNEL_ID=new_id
```

**Q: How much will this cost?**  
A: Free tier covers 2M requests/month. Most usage stays within free limits ($0).

**Q: How do I delete the service?**  
A: 
```bash
gcloud run services delete youtube-mcp-server --region us-central1
```

**Q: Can I use a different region?**  
A: Yes, the script lets you choose from 5 regions.

---

Happy deploying! 🚀
