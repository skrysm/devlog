# Upgrading Dependencies

1. Upgrade nodejs on your dev machine
1. Upgrade npm on your dev machine (<https://docs.npmjs.com/try-the-latest-stable-version-of-npm>):
   `npm install -g npm@latest`
1. Create git branch:
   `git switch -c feature/upgrade-dependencies`
1. Run:
   `themes/devlog-theme/npm-update.ps1`

   (or `npm-init.ps1` on a fresh clone)
1. Update `HUGO_VERSION` variable in `.github/workflows/build-and-deploy.yaml`
1. Push branch to GitHub
1. Create pull request
1. After all checks have passed, go into the Summary of the "Build & Deploy" action and download the `diffable-output...` artifact
1. Download the `diffable-output...` artifact from the latest action run on the `main` branch
   * If there is none (because the run is too old), manually trigger a run
1. Compare the contents of the two `diffable-output...` zip files with a diff tool
1. If ok, merge the pull request
