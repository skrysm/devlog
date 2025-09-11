#!/usr/bin/env pwsh

Push-Location "$PSScriptRoot/_utils"
npm update --save
Pop-Location

Push-Location "$PSScriptRoot/assets"
npm update --save
Pop-Location
