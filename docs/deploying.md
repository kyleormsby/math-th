# Deploying Math Trailhead

## How it works

`.github/workflows/pretext-cli.yml` runs on every push to `main` (and on pull
requests, and on demand). It builds the book inside the `oscarlevin/pretext-full`
container, stages the output with `pretext deploy --stage-only`, and hands the
result to GitHub Pages as a deployment artifact.

Note what this does *not* do: it never commits built HTML to the repository and
never touches a `gh-pages` branch. `output/` and `generated-assets/` stay
gitignored. The repository holds source only.

Expect a build to take several minutes — the WeBWorK representations for 475
problems are regenerated from scratch on every run, since `generated-assets/` is
not cached between runs.

## One-time setup

These are the settings that have to exist on the repository itself. They are not
in any file, which is why a fresh clone or a transferred repository will appear
to be configured and still publish nothing.

1. **Settings → Pages → Source: GitHub Actions.**
   Not "Deploy from a branch" — this workflow uses the artifact-based path.

2. **Settings → Secrets and variables → Actions → Variables → New repository
   variable:** name `PTX_ENABLE_DEPLOY_GHPAGES`, value `yes`.
   The `deploy-ghpages` job is gated on this. Without it the build runs green
   and publishes nothing, which is a confusing failure mode.

3. Confirm the repository's default branch is `main`. The deploy job only runs
   on the default branch.

After a successful run the site is at `https://<owner>.github.io/<repo>/`.

## Verifying

Trigger the workflow by hand from the Actions tab (**PreTeXt-CLI Actions** →
Run workflow) rather than waiting for a content push. Then check:

- The `build` job produced a `deploy` artifact.
- The `deploy-ghpages` job actually ran; if it was skipped, the repository
  variable in step 2 is missing or the branch is not the default.
- On the live site, open any section and confirm the WeBWorK problems render
  and accept answers. If problems appear as static previews instead, the
  `<webwork>` settings in `publication/publication.ptx` are the place to look.

## If the repository moves or is renamed

The public URL is `https://<owner>.github.io/<repo>/`, so both parts change.
Two things need updating afterward:

- `<baseurl href="..."/>` in `publication/publication.ptx`.
- The live-site link in `README.md`.

The repository settings in the one-time setup section do **not** survive a
transfer — redo them on the new owner's copy.

Prefer GitHub's **Transfer ownership** (Settings → Danger Zone) over forking:
it preserves history, issues, and stars, and GitHub leaves a redirect from the
old URL. The current owner has to initiate it, so it is worth doing before the
student authors' accounts go quiet.

## Moving to Reed hosting later

A PreTeXt HTML build is plain static files with relative links; the PreTeXt
Guide is explicit that no special server configuration or privileges are
needed. So a Reed-hosted version is a copy operation:

```bash
pretext build --deploys
pretext deploy --stage-only    # output lands in output/stage/
rsync -av --delete output/stage/ user@server:/path/to/webroot/
```

The same three commands can go in a CI job with a deploy key if you want Reed
hosting to update automatically the way Pages does. Set `<baseurl>` to the
Reed URL when you make the switch.

Worth doing at the same time: register a stable URL you control, so the book
can move hosts again later without breaking every link anyone has shared.

## Related

- `docs/webwork-server-setup.md` — what Reed's WeBWorK server needs in order to
  serve these problems, and why we would want that.
