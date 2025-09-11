#!/usr/bin/env pwsh

Push-Location "$PSScriptRoot/_utils"
npm install
Pop-Location

Push-Location "$PSScriptRoot/assets"
npm install
Pop-Location
