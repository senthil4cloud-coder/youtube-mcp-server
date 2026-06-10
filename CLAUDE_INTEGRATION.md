# Integrating YouTube MCP Server with Claude

This guide shows how to connect your deployed YouTube MCP server to Claude as a custom MCP connector.

## Prerequisites

- ✅ YouTube MCP server deployed to Cloud Run
- ✅ Service URL: `https://youtube-mcp-server-340920787097.us-central1.run.app`
- Claude desktop, web, or Code version with MCP support

---

## Option 1: Claude Desktop / Claude Web (Recommended)

### Step 1: Get Your Service Configuration

Your MCP server configuration:

```json
{
  "name": "youtube-analytics",
  "url": "https://youtube-mcp-server-340920787097.us-central1.run.app/mcp"
}
```

### Step 2: Add to Claude Settings

#### On Mac:
1. Open Terminal
2. Edit Claude's MCP configuration:
   ```bash
   nano ~/.claude/mcp-config.json
   ```
   
3. Add your server (create file if it doesn't exist):
   ```json
   {
     "mcp_servers": {
       "youtube": {
         "type": "http",
         "url": "https://youtube-mcp-server-340920787097.us-central1.run.app/mcp",
         "name": "YouTube Analytics MCP"
       }
     }
   }
   ```

4. Save (Ctrl+O, Enter, Ctrl+X)
5. Restart Claude

#### On Windows:
1. Open PowerShell
2. Navigate to Claude config:
   ```powershell
   cd $env:APPDATA\Claude
   ```
   
3. Create or edit `mcp-config.json`:
   ```powershell
   notepad mcp-config.json
   ```

4. Add configuration:
   ```json
   {
     "mcp_servers": {
       "youtube": {
         "type": "http",
         "url": "https://youtube-mcp-server-340920787097.us-central1.run.app/mcp",
         "name": "YouTube Analytics MCP"
       }
     }
   }
   ```

5. Save and restart Claude

#### On Linux:
```bash
mkdir -p ~/.claude
nano ~/.claude/mcp-config.json
```

Add the same configuration as Mac/Windows above.

---

## Option 2: Claude Code (Local Integration)

If you have Claude Code installed locally, you can integrate with stdio transport:

### Step 1: Start Local Server

```powershell
# In your project directory
python youtube_mcp_server.py
```

### Step 2: Configure Claude Code

Claude Code can auto-discover local MCP servers. The stdio server should be available once running.

---

## Option 3: Manual HTTP Configuration

If Claude doesn't auto-detect, manually configure:

### Create Configuration File

Create `youtube-mcp-server-config.json`:

```json
{
  "type": "http",
  "name": "YouTube Analytics",
  "endpoint": "https://youtube-mcp-server-340920787097.us-central1.run.app",
  "mcp_endpoint": "https://youtube-mcp-server-340920787097.us-central1.run.app/mcp",
  "health_check": "https://youtube-mcp-server-340920787097.us-central1.run.app/health",
  "tools": [
    {
      "name": "get_channel_stats",
      "description": "Get channel subscribers, total views, video count"
    },
    {
      "name": "get_latest_videos",
      "description": "Fetch latest uploaded videos from channel"
    },
    {
      "name": "get_video_stats",
      "description": "Get views, likes, comments for specific video"
    },
    {
      "name": "search_videos",
      "description": "Search YouTube videos by keyword"
    },
    {
      "name": "get_playlist_videos",
      "description": "Get all videos from a playlist"
    }
  ]
}
```

---

## Testing the Integration

### Step 1: Verify Service is Accessible

```powershell
# Test health endpoint
curl https://youtube-mcp-server-340920787097.us-central1.run.app/health

# Test MCP endpoint
curl https://youtube-mcp-server-340920787097.us-central1.run.app/mcp
```

### Step 2: Test in Claude

In Claude conversation, ask:
```
Show me my YouTube channel statistics for UC_uqN7g9WoTcx6mKJugydAQ
```

Or:
```
Get my latest 5 videos
```

Claude should use the YouTube MCP tools to fetch the data.

---

## Example Prompts to Try

Once integrated, you can ask Claude:

### Channel Analytics
```
What are my YouTube channel statistics?
```

### Video Analytics
```
Get the views, likes, and comments for this video: dQw4w9WgXcQ
```

### Latest Content
```
Show me my 10 latest videos and their statistics
```

### Search
```
Search for "python tutorial" on YouTube and show me the results
```

### Playlist Analysis
```
Get all videos from my playlist: PLxxxxxxxxxxxxxx
```

---

## Troubleshooting

### "MCP server not found"
1. Verify service URL is correct
2. Check service is running: 
   ```cmd
   curl https://youtube-mcp-server-340920787097.us-central1.run.app/health
   ```
3. Restart Claude
4. Check Claude's MCP configuration file syntax

### "Connection refused"
- Ensure Cloud Run service is deployed and running
- Verify URL doesn't have typos
- Check firewall/network access

### "Tools not available"
1. Restart Claude completely
2. Check MCP config is valid JSON
3. Verify `/ready` endpoint shows 5 tools:
   ```cmd
   curl https://youtube-mcp-server-340920787097.us-central1.run.app/ready
   ```

### "Authentication errors"
- Verify `YOUTUBE_API_KEY` is correct in Cloud Run environment
- Verify `CHANNEL_ID` is correct
- Check YouTube API is enabled in GCP

---

## Advanced: Custom Integration Script

Create a script to manage the MCP server connection:

### PowerShell Script (manage-mcp.ps1)

```powershell
param(
    [string]$Action = "status",
    [string]$ConfigPath = "$env:APPDATA\Claude\mcp-config.json"
)

$serviceUrl = "https://youtube-mcp-server-340920787097.us-central1.run.app"

switch ($Action) {
    "health" {
        Write-Host "Checking MCP server health..." -ForegroundColor Green
        $health = Invoke-RestMethod -Uri "$serviceUrl/health"
        Write-Host "Status: $($health.status)" -ForegroundColor Green
    }
    
    "tools" {
        Write-Host "Listing available tools..." -ForegroundColor Green
        $ready = Invoke-RestMethod -Uri "$serviceUrl/ready"
        Write-Host "Tools registered: $($ready.tools_registered)" -ForegroundColor Green
    }
    
    "install" {
        Write-Host "Installing MCP server configuration..." -ForegroundColor Green
        $config = @{
            mcp_servers = @{
                youtube = @{
                    type = "http"
                    url = "$serviceUrl/mcp"
                    name = "YouTube Analytics MCP"
                }
            }
        }
        $config | ConvertTo-Json | Out-File $ConfigPath
        Write-Host "Installed at: $ConfigPath" -ForegroundColor Green
    }
    
    "status" {
        Write-Host "YouTube MCP Server Status" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        Write-Host "URL: $serviceUrl" -ForegroundColor White
        
        try {
            $health = Invoke-RestMethod -Uri "$serviceUrl/health"
            Write-Host "Health: $($health.status)" -ForegroundColor Green
        } catch {
            Write-Host "Health: Unreachable" -ForegroundColor Red
        }
        
        try {
            $ready = Invoke-RestMethod -Uri "$serviceUrl/ready"
            Write-Host "Tools: $($ready.tools_registered)/5" -ForegroundColor Green
        } catch {
            Write-Host "Tools: Unavailable" -ForegroundColor Red
        }
    }
}
```

Usage:
```powershell
# Check status
.\manage-mcp.ps1 -Action status

# Check health
.\manage-mcp.ps1 -Action health

# List tools
.\manage-mcp.ps1 -Action tools

# Install configuration
.\manage-mcp.ps1 -Action install
```

---

## Configuration Verification

### Check MCP Config is Valid

```bash
# On Mac/Linux
cat ~/.claude/mcp-config.json | jq .

# On Windows PowerShell
Get-Content $env:APPDATA\Claude\mcp-config.json | ConvertFrom-Json
```

### Expected Response
```json
{
  "mcp_servers": {
    "youtube": {
      "type": "http",
      "url": "https://youtube-mcp-server-340920787097.us-central1.run.app/mcp",
      "name": "YouTube Analytics MCP"
    }
  }
}
```

---

## Security Notes

✅ **Your API Key is secure:**
- Stored in Cloud Run environment variables
- Not exposed in code or configuration
- Only used server-side
- Never shared with Claude

✅ **HTTPS encryption:**
- All communication encrypted
- Google Cloud Run provides SSL/TLS

---

## Next Steps

1. ✅ Configure MCP in Claude using steps above
2. ✅ Test with health check command
3. ✅ Try example prompts
4. ✅ Use in your Claude workflows

---

## Support

If you encounter issues:
1. Check Cloud Run logs: `gcloud run logs read youtube-mcp-server --region us-central1`
2. Verify service URL is accessible
3. Check MCP configuration syntax
4. Restart Claude application

---

**Your YouTube MCP Server is ready to power Claude!** 🚀
