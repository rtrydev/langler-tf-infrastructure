# prod

Composes the frontend, auth, API, and storage modules for `langler.rtrydev.com`. State uses native S3 lockfile locking and preserves the existing `root/terraform.tfstate` backend key.

Log in with the AWS CLI, set `LANGLER_AWS_ACCOUNT_ID` to the expected production account, and run `../../scripts/deploy.sh`. The script uses the active shared profile, runs all local checks, validates the active account, and creates and cleans up a private saved plan.
