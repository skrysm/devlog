#!/usr/bin/env pwsh
#
# Creates the search index for running Hugo's dev server (i.e. local writing/development).
#
# Called automatically from hugo-server.ps1.
#

param(
    [switch] $OnlyIfStale
)

$rootDir = [IO.Path]::GetFullPath("$PSScriptRoot")
Write-Host "Using Hugo files from: $rootDir"

$pageFindDir = "$rootDir/static/pagefind"
$metadataPath = "$pageFindDir/index-metadata.json"

#
# Check if index should be recreated.
#
function Get-CurrentCommit([string] $RepoPath) {
    $commit = & git -C $RepoPath rev-parse HEAD
    if (-not $?) {
        Write-Error "Could not determine current Git commit."
    }

    return $commit.Trim()
}

$currentCommit = Get-CurrentCommit $rootDir

if ($OnlyIfStale) {
    if (Test-Path $metadataPath) {
        $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
        $lastCommit = $metadata.commit
        $lastCreated = Get-Date $metadata.created
        $oneMonthAgo = (Get-Date).AddMonths(-1)

        if ($lastCommit -eq $currentCommit -and $lastCreated -ge $oneMonthAgo) {
            Write-Host "Existing search index is current for commit $currentCommit (created $($lastCreated.ToString('u'))); skipping recreation."
            return
        }

        Write-Host 'Search index is stale (different commit or older than one month); recreating.'
    } else {
        Write-Host 'No existing index metadata found; recreating search index.'
    }
}

#
# (Re-)Create index
#
if (Test-Path $pageFindDir) {
    Remove-Item $pageFindDir -Recurse -Force
}

$tempOutputDir = [IO.Path]::GetFullPath("$env:TEMP/hugo-temp/$([Guid]::NewGuid())")

hugo --gc --cleanDestinationDir --source $rootDir --destination $tempOutputDir -D
if (-Not $?) {
    Write-Error 'hugo publish failed'
}

Push-Location "$PSScriptRoot/themes/devlog-theme/_utils"
# See: https://pagefind.app/docs/running-pagefind/
npx pagefind --site $tempOutputDir.Replace('\', '/') --output-path $pageFindDir.Replace('\', '/')
Pop-Location

Remove-Item $tempOutputDir -Recurse -Force

#
# Store index metadata
#
$indexMetadata = @{
    commit = $currentCommit
    created = (Get-Date).ToString('o')
}
$indexMetadata | ConvertTo-Json | Set-Content -Path $metadataPath -Encoding UTF8
