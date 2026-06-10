# Deploying to Google Cloud Run

This guide walks you through deploying your YouTube MCP Server to Google Cloud Run with free/low-cost hosting.

## Prerequisites

1. **Google Cloud Account** - [Create free account](https://cloud.google.com/free) ($300 free credits)
2. **Google Cloud SDK** - [Install gcloud CLI](https://cloud.google.com/sdk/docs/install)
3. **Docker** - [Install Docker](https://www.docker.com/products/docker-desktop)
4. **YouTube API Key** - [Get from Google Cloud Console](https://console.cloud.google.com/)

## Step-by-Step Deployment

### 1. Set Up Google Cloud Project

```bash
# Initialize gcloud (if first time)
gcloud init

# Create a new project (or use existing)
gcloud projects create youtube-mcp-server --name="YouTube MCP Server"

# Set default project
gcloud config set project youtube-mcp-server

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 2. Prepare Environment Variables

You need to set your YouTube API credentials in Cloud Run as environment variables.

**Option A: Using Cloud Console (Easiest)**
- Deploy first (steps below), then update variables in Cloud Console
- Navigate to Cloud Run → Your Service → Edit → Variables

**Option B: Using gcloud CLI**
Keep your credentials ready for step 5.

### 3. Build Docker Image

```bash
# Build the Docker image
docker build -t youtube-mcp-server .

# Test locally (optional but recommended)
docker run -p 8080:8080 \
  -e YOUTUBE_API_KEY=your_api_key \
  -e CHANNEL_ID=your_channel_id \
  youtube-mcp-server
```

### 4. Push to Google Container Registry

```bash
# Configure Docker for GCP
gcloud auth configure-docker

# Tag your image
docker tag youtube-mcp-server gcr.io/youtube-mcp-server/youtube-mcp-server:latest

# Push to GCR
docker push gcr.io/youtube-mcp-server/youtube-mcp-server:latest
```

### 5. Deploy to Cloud Run

```bash
gcloud run deploy youtube-mcp-server \
  --image gcr.io/youtube-mcp-server/youtube-mcp-server:latest \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 3600 \
  --set-env-vars YOUTUBE_API_KEY=your_api_key,CHANNEL_ID=your_channel_id \
  --allow-unauthenticated
```

**Parameters Explained:**
- `--platform managed` - Use Cloud Run (fully managed)
- `--region us-central1` - Choose closest region (us-west1, europe-west1, etc.)
- `--memory 512Mi` - Memory allocation (512MB free tier friendly)
- `--cpu 1` - CPU allocation (1 CPU default)
- `--timeout 3600` - Request timeout (1 hour)
- `--allow-unauthenticated` - Allow public access (remove for private service)

### 6. Verify Deployment

```bash
# Get service URL
gcloud run services describe youtube-mcp-server --region us-central1

# Test health endpoint
curl https://your-service-url.run.app/health

# Test MCP endpoint
curl https://your-service-url.run.app/ready
```

## Updating Credentials After Deployment

If you deployed without credentials:

### Via Cloud Console (Easiest)
1. Go to [Cloud Run Console](https://console.cloud.google.com/run)
2. Click on your service
3. Click "Edit & Deploy New Revision"
4. Add environment variables under "Runtime settings"
5. Set:
   - `YOUTUBE_API_KEY` = your API key
   - `CHANNEL_ID` = your channel ID
6. Deploy

### Via gcloud CLI
```bash
gcloud run deploy youtube-mcp-server \
  --region us-central1 \
  --set-env-vars YOUTUBE_API_KEY=your_key,CHANNEL_ID=your_id \
  --image gcr.io/youtube-mcp-server/youtube-mcp-server:latest
```

## Cost Estimation

**Free Tier (Always Free):**
- 2,000,000 requests per month
- 360,000 GB-seconds per month
- **Your cost: $0**

**Example Usage:**
- 100 requests/day = 3,000/month (well within free tier)
- 1,000 requests/day = 30,000/month (still free)
- Average 30 seconds per request = 25,000 GB-seconds/month (free)

**If you exceed free tier:**
- Additional requests: ~$0.40 per 1M requests
- Additional compute: ~$0.0000250 per GB-second

## Monitoring

### View Logs
```bash
gcloud run logs read youtube-mcp-server --region us-central1 --limit 50
```

### Set Up Alerts (Optional)
1. Go to [Cloud Run Console](https://console.cloud.google.com/run)
2. Click service → Metrics
3. Set up alerts for errors or high latency

## Connecting Claude

Once deployed, get your service URL:

```bash
gcloud run services describe youtube-mcp-server --region us-central1 --format='value(status.url)'
```

You can now connect Claude to your service using the endpoint:
- **SSE Endpoint:** `https://your-service-url.run.app/mcp`
- **Health Check:** `https://your-service-url.run.app/health`

## Scaling

Cloud Run automatically scales:
- **Scales to zero** when no requests (no cost)
- **Auto-scales up** when requests increase
- **Max 1000 concurrent requests** per service

## Redeploy (After Code Changes)

```bash
# Rebuild image
docker build -t youtube-mcp-server .

# Push to registry
docker tag youtube-mcp-server gcr.io/youtube-mcp-server/youtube-mcp-server:latest
docker push gcr.io/youtube-mcp-server/youtube-mcp-server:latest

# Deploy new version
gcloud run deploy youtube-mcp-server \
  --image gcr.io/youtube-mcp-server/youtube-mcp-server:latest \
  --region us-central1
```

## Troubleshooting

### "Permission denied" when pushing
```bash
gcloud auth configure-docker
```

### "Service not found" errors
- Ensure API is enabled: `gcloud services enable run.googleapis.com`
- Check project ID: `gcloud config list`

### "CPU should be 1, 2, 4, or 8"
Use valid CPU values: `--cpu 1` or `--cpu 2`

### 502 / Bad Gateway errors
- Check logs: `gcloud run logs read youtube-mcp-server`
- Ensure environment variables are set
- Check API key validity

### Service times out
- Increase timeout: `--timeout 3600`
- Check YouTube API rate limits

## Delete Service (If Needed)

```bash
gcloud run services delete youtube-mcp-server --region us-central1
```

## Next Steps

1. ✅ Verify deployment works
2. ✅ Connect to Claude
3. ✅ Monitor logs periodically
4. ✅ Update code when needed

Happy deploying! 🚀
