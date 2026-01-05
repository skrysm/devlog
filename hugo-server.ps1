#!/usr/bin/env pwsh
param(
    [switch] $BindAll,

    [switch] $NoIndexCreation
)

if (-Not $NoIndexCreation) {
    & "$PSScriptRoot/create-search-index.ps1" -OnlyIfStale
}

if ($BindAll) {
    & hugo server --buildDrafts --renderToMemory --bind 0.0.0.0
}
else {
    & hugo server --buildDrafts --renderToMemory
}
