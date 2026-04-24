# Contributing

The various `terraform-*-hvd` modules are public and open to community contributors.

When contributing to this repository, please first discuss the change you wish
to make via issue, email, or any other method with the owners of this repository before making a change.

Do note that this project has a code of conduct; please be sure to follow it
in all of your project interactions.

## Pull request process

1. Ensure any install or build artifacts are removed before the end of
   the layer when doing a build
1. Update the README.md, any relevant `./docs/`entry or `./examples` with details of changes to the
   interface, this includes running `terraform-docs` to update the `README.md`
1. Releases use versioning tags. The versioning scheme we use is (mostly) [SemVer](http://semver.org/)
1. You may merge the pull request in once you have the sign-off of two other
   project contributors, or if you do not have permission to do that, you can
   request the second reviewer to merge it for you and release.

## Issues

There is a basic issue template to post issues.

## Pull request

The repository includes a pull request template with basic requirements for testing and validation which we provide config for basic smoke test such as `terraform fmt`, `terraform validate` and `terraform-docs`

## Tooling

This repository uses [Task](https://taskfile.dev/) to manage development tasks.

### Requirements

The `release` task requires the following.

- Make sure you have Task installed before proceeding, <https://taskfile.dev/docs/installation>.
- This also relies on the GitHub cli `GH`, <https://cli.github.com/>, do not forget to authenticate `gh`
- The `markdown-url-converter.py` requires `python` in your `$PATH`.

## Available tasks

You can list all available tasks by running the following.

```bash
task
task default
task --list-all

## Testing

To run all tests, run `task test`.
This will run Terraform tests:
- `task test-terraform`: Runs formatting checks, initialization, and validation for all Terraform directories.

## Cleaning

To clean the environment, run `task clean`.
This includes `task clean-terraform` which removes Terraform directories and lock files.

## Documentation

To update Terraform documentation, run the following.

```bash
task terraform-docs
```

Note: This requires a `.terraform-docs.yml` configuration file. If you do not have one, you can generate it with `task generate-terraform-docs-config`.


## Creating a Release

To create a new release, once a feature branch as been merged from pull request.

```bash
MOD_RELEASE=X.Y.Z task release
```

Requirements:
- GitHub CLI (`gh`) must be installed
- Python must be in the PATH:
- `MOD_RELEASE` variable must be set to a valid semver tag (e.g., `1.2.3`), it can be set as an env var `export MOD_RELEASE`, in `env.local`, or passsed at the command line `MOD_RELEASE=x.x.x. task release`
- The new version must be greater than the current tag

The release process will do the following.
1. Create a release branch
1. Update documentation URLs
1. Create a tagged release
1. Generate release notes
1. Create a GitHub release
1. Update CHANGELOG
1. Create PR

```
 MOD_RELEASE=1.2.3 task release -vn
task: dynamic variable: "echo \"${PWD##*/}\"" result: "hvd-module-template"
task: dynamic variable: "git config --local remote.origin.url | cut -d':' -f2 | cut -d'/' -f1" result: "hashicorp"
task: dynamic variable: "git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo \"\"" result: ""
task: "release" started
task: [release] export MOD_REPO="hvd-module-template"
export MOD_RELEASE="1.2.3"
export REPO_OWNER="hashicorp"
echo "Releasing hashicorp/hvd-module-template version 1.2.3"

task: [release] git checkout -b release/rc-${MOD_RELEASE}
task: [release] python .github/scripts/markdown-url-converter/markdown-url-converter.py --repo="hashicorp/hvd-module-template" --release="1.2.3" --overwrite .

task: [release] git commit  --allow-empty -am "Release version ${MOD_RELEASE}"
task: [release] git tag -a ${MOD_RELEASE} -m "${MOD_RELEASE} release"
task: [release] git push origin --tags
task: [release] git revert HEAD --no-edit -n
task: [release] git commit -m "Revert release commit to retain tag in history"
task: [release] git push origin release/rc-${MOD_RELEASE}
task: [release] RELEASE_NOTES=$(gh release view 1.2.3 --repo hashicorp/hvd-module-template --json body --jq .body)
TEMP_FILE=$(mktemp)

echo "## v1.2.3" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "$RELEASE_NOTES" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
tail -n +1 CHANGELOG.md >> "$TEMP_FILE"
mv "$TEMP_FILE" CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: update CHANGELOG.md for v1.2.3"
git push origin release/rc-${MOD_RELEASE}

task: [release] git tag -af ${MOD_RELEASE} -m "${MOD_RELEASE} release"
task: [release] git push origin --tags -f
task: [release] # Wait for the updated tag to be visible on the remote before creating the release
for i in {1..10}; do
  if git ls-remote --tags origin | grep -q "refs/tags/${MOD_RELEASE}$"; then
    echo "Tag ${MOD_RELEASE} is now available on origin."
    break
  fi
  echo "Waiting for tag ${MOD_RELEASE} to propagate to origin (attempt ${i}/10)..."
  sleep 3
done
gh release create 1.2.3 \
--repo hashicorp/hvd-module-template \
--title "1.2.3" \
--generate-notes --notes-start-tag

task: [release] RELEASE_NOTES=$(gh release view 1.2.3 --repo hashicorp/hvd-module-template --json body --jq .body)
PR_BODY_FILE=$(mktemp)
echo "Release version 1.2.3" > "$PR_BODY_FILE"
echo "" >> "$PR_BODY_FILE"
echo "$RELEASE_NOTES" >> "$PR_BODY_FILE"
gh pr create \
--repo hashicorp/hvd-module-template \
--title "Release 1.2.3" \
--body-file "$PR_BODY_FILE" \
--base main \
--head release/rc-${MOD_RELEASE} || true

task: [release] git checkout main
task: "release" finished

```

> You can also set the `MOD_RELEASE` variable in a `.env.local` file for convenience.


## Code of conduct

### Our pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project
and our community a harassment-free experience for everyone, regardless of age,
body size, disability, ethnicity, gender identity and expression, level of
experience, nationality, personal appearance, race, religion, or sexual
identity and orientation.

### Our standards

Examples of behavior that contributes to creating a positive environment
include:

- Showing empathy towards other community members.
- Using welcoming and inclusive language.
- Being respectful of differing viewpoints and experiences.
- Gracefully accepting constructive criticism.
- Focusing on what is best for the community.

Examples of unacceptable behavior by participants include the following.

- Use of sexualized language or imagery and unwelcome sexual attention
  or advances.
- Insulting/derogatory comments, and personal or political attacks.
- Public or private harassment.
- Publishing others' private information, such as a physical or electronic
  address, without explicit permission.
- Other conduct which could reasonably be considered inappropriate in a
  professional setting.

### Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an
appointed representative at an online or offline event. Representation of a
project may be further defined and clarified by project maintainers.


### Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4, available at [http://contributor-covenant.org/version/1/4][version]

[homepage]: http://contributor-covenant.org
[version]: http://contributor-covenant.org/version/1/4/

