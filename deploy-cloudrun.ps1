# Interactive Google Cloud Run Deployment Script
# YouTube MCP Server Deployment Helper

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   YouTube MCP Server - Google Cloud Run Deployment         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Function to get user input with validation
function Get-ValidatedInput {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [scriptblock]$Validation = $null
    )

    while ($true) {
        if ($Default) {
            Write-Host "$Prompt [$Default]: " -ForegroundColor Yellow -NoNewline
        } else {
            Write-Host "$Prompt : " -ForegroundColor Yellow -NoNewline
        }

        $input = Read-Host
        $input = if ([string]::IsNullOrWhiteSpace($input)) { $Default } else { $input }

        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "  ❌ This field is required" -ForegroundColor Red
            continue
        }

        if ($Validation) {
            $result = & $Validation $input
            if ($result -ne $true) {
                Write-Host "  ❌ $result" -ForegroundColor Red
                continue
            }
        }

        return $input
    }
}

# Gather configuration
Write-Host "Please provide the following information:" -ForegroundColor Green
Write-Host ""

# YouTube API Key
$apiKey = Get-ValidatedInput `
    -Prompt "YouTube API Key" `
    -Validation {
        param($val)
        if ($val.Length -lt 20) {
            return "API Key should be longer (typically 39 characters)"
        }
        return $true
    }

# Channel ID
$channelId = Get-ValidatedInput `
    -Prompt "YouTube Channel ID (e.g., UC_xxxxx)" `
    -Validation {
        param($val)
        if (-not ($val -match "^UC[a-zA-Z0-9_-]+$")) {
            return "Channel ID should start with 'UC' followed by alphanumeric characters"
        }
        return $true
    }

# GCP Project
$project = Get-ValidatedInput `
    -Prompt "GCP Project ID" `
    -Default "emerging-tech-nation"

# Service Name
$serviceName = Get-ValidatedInput `
    -Prompt "Cloud Run Service Name" `
    -Default "youtube-mcp-server"

# Region
Write-Host ""
Write-Host "Available regions:" -ForegroundColor Cyan
Write-Host "  1. us-central1 (N. California) - Default, low latency"
Write-Host "  2. us-west1 (Oregon)"
Write-Host "  3. europe-west1 (Belgium)"
Write-Host "  4. asia-northeast1 (Tokyo)"
Write-Host "  5. australia-southeast1 (Sydney)"

$regionChoice = Get-ValidatedInput `
    -Prompt "Select region (1-5)" `
    -Default "1" `
    -Validation {
        param($val)
        if ($val -notin @("1", "2", "3", "4", "5")) {
            return "Please select 1-5"
        }
        return $true
    }

$regionMap = @{
    "1" = "us-central1"
    "2" = "us-west1"
    "3" = "europe-west1"
    "4" = "asia-northeast1"
    "5" = "australia-southeast1"
}
$region = $regionMap[$regionChoice]

# Memory
$memory = Get-ValidatedInput `
    -Prompt "Memory allocation (e.g., 512Mi, 1Gi, 2Gi)" `
    -Default "512Mi" `
    -Validation {
        param($val)
        if ($val -notmatch "^(256Mi|512Mi|1Gi|2Gi|4Gi)$") {
            return "Must be one of: 256Mi, 512Mi, 1Gi, 2Gi, 4Gi"
        }
        return $true
    }

# CPU
$cpu = Get-ValidatedInput `
    -Prompt "CPU allocation (1, 2, 4, or 8)" `
    -Default "1" `
    -Validation {
        param($val)
        if ($val -notin @("1", "2", "4", "8")) {
            return "Must be 1, 2, 4, or 8"
        }
        return $true
    }

# Timeout
$timeout = Get-ValidatedInput `
    -Prompt "Request timeout in seconds (max 3600)" `
    -Default "3600" `
    -Validation {
        param($val)
        if ($val -notmatch "^\d+$" -or [int]$val -gt 3600) {
            return "Must be a number between 1 and 3600"
        }
        return $true
    }

# Allow unauthenticated
Write-Host ""
Write-Host "Allow unauthenticated requests? (y/n): " -ForegroundColor Yellow -NoNewline
$allowPublic = (Read-Host).ToLower() -eq "y"

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    DEPLOYMENT SUMMARY                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Service Name:      $serviceName" -ForegroundColor White
Write-Host "  GCP Project:       $project" -ForegroundColor White
Write-Host "  Region:            $region" -ForegroundColor White
Write-Host "  Memory:            $memory" -ForegroundColor White
Write-Host "  CPU:               $cpu" -ForegroundColor White
Write-Host "  Timeout:           $timeout seconds" -ForegroundColor White
Write-Host "  Public Access:     $(if ($allowPublic) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "  Image:             gcr.io/$project/$serviceName:latest" -ForegroundColor White
Write-Host ""
Write-Host "  API Key will be set as environment variable" -ForegroundColor Cyan
Write-Host "  Channel ID will be set as environment variable" -ForegroundColor Cyan
Write-Host ""

# Confirm deployment
Write-Host "Proceed with deployment? (y/n): " -ForegroundColor Yellow -NoNewline
$confirm = (Read-Host).ToLower() -eq "y"

if (-not $confirm) {
    Write-Host ""
    Write-Host "Deployment cancelled." -ForegroundColor Red
    exit 0
}

# Build deployment command
Write-Host ""
Write-Host "Building deployment command..." -ForegroundColor Green

$deployCmd = @(
    "gcloud run deploy $serviceName",
    "--image gcr.io/$project/$serviceName:latest",
    "--platform managed",
    "--region $region",
    "--memory $memory",
    "--cpu $cpu",
    "--timeout $timeout",
    "--set-env-vars YOUTUBE_API_KEY=$apiKey,CHANNEL_ID=$channelId"
)

if ($allowPublic) {
    $deployCmd += "--allow-unauthenticated"
}

$deployCmd += "--project $project"

Write-Host ""
Write-Host "Running deployment..." -ForegroundColor Green
Write-Host ""

# Execute deployment
$fullCmd = $deployCmd -join " `"
Invoke-Expression $fullCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         ✅ DEPLOYMENT SUCCESSFUL!                         ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Getting your service URL..." -ForegroundColor Yellow
    Write-Host ""

    gcloud run services describe $serviceName --region $region --project $project --format='value(status.url)'

    Write-Host ""
    Write-Host "Test your service:" -ForegroundColor Cyan
    Write-Host "  curl https://<your-service-url>/health" -ForegroundColor White
    Write-Host ""
    Write-Host "View logs:" -ForegroundColor Cyan
    Write-Host "  gcloud run logs read $serviceName --region $region --project $project --limit 50" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed. Check the error above." -ForegroundColor Red
    exit 1
}
