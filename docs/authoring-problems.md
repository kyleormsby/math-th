# Writing our own problems

## The short answer

Self-authored problems do **not** go on Reed's WeBWorK server. They live in this
repository, and the reader's browser hands the problem to the server at the
moment it needs rendering. Reed's server is still needed — as a renderer and
answer checker — but it never holds a copy of the problem.

Uploading is only required for the other kind of problem: the ones we reference
by path, which is every problem in the book today.

## Two mechanisms, and which one applies

PreTeXt calls these two "origins".

**`webwork2` — a reference.** `<webwork source="Library/.../foo.pg"/>` names a
`.pg` file that must already exist on the server, under the host course's
`templates/` directory. At render time PreTeXt sends the server a
`sourceFilePath` and the server opens the file itself. All 475 exercises here
work this way, pointing into the Open Problem Library. **A problem referenced
this way has to be on the server.**

**`generated` — the source travels with the book.** A problem written into our
own source is compiled to a `.pg` file during `pretext generate webwork`, and
that file is published with the site under `generated/webwork/pg/`. When a
reader activates the exercise, their browser fetches the `.pg` from *our* site
and posts its text to WeBWorK as `rawProblemSource`. The server renders it and
checks answers against text it was handed a moment earlier. **It never needs a
copy.**

If you want to confirm this rather than take it on faith, the two places to
look in the PreTeXt sources are the comment at the top of `xsl/extract-pg.xsl`,
which defines the two origins, and `js/pretext-webwork/2.19/pretext-webwork.js`,
where the branch reads:

```js
if (ww_origin == 'generated') {
    const rawProblemSource = await fetch(generatedPG + ww_problemSource).then((r) => r.text());
    formData.set("rawProblemSource", rawProblemSource);
}
else if (ww_origin == 'webwork2') formData.set("sourceFilePath", ww_sourceFilePath);
```

## Three ways to author a `generated` problem

All three produce origin `generated`, so all three skip the server upload.

1. **In PreTeXt markup.** `<webwork>` with `<statement>`, `<var>`, optional
   `<pg-code>`, `<hint>`, `<solution>`. No PGML required for simple questions;
   PreTeXt loads the common macro libraries for you based on what you use.
2. **Raw PG inline**, as the text content of `<webwork>`. Whitespace inside is
   preserved into the `.pg`, and PG cares about whitespace.
3. **Raw PG in its own file**, pulled in as text:

   ```xml
   <webwork>
     <xi:include parse="text" href="../../problems/limits-01.pg"/>
   </webwork>
   ```

   The `href` is relative to the file doing the including, and that file's root
   element needs `xmlns:xi="http://www.w3.org/2001/XInclude"` — the worksheet
   files here do not have it yet.

**Recommendation: option 3.** Real `.pg` files are what a WeBWorK author
already knows how to write and debug, they diff cleanly, they can be opened in
WeBWorK's own editor when something misbehaves, and they stay portable if the
book ever moves off PreTeXt. Option 1 is the better choice only if you would
rather not learn PGML at all.

## What does have to be on Reed's server

- **A host course.** Every render request carries a `courseID`, `user` and
  `passwd`, including requests whose problem source we supply. The guest
  `anonymous` course in `webwork-server-setup.md` is still required.
- **CORS headers**, so a browser on `kyleormsby.github.io` is allowed to embed
  a response from `webwork.its.reed.edu`. Also in `webwork-server-setup.md`.
- **A PG macro library, only if we need one.** Problems that use macros
  generated from our own source — TikZ images drawing on
  `docinfo/latex-image-preamble`, for instance — need a library file built and
  installed first:

  ```bash
  pretext devscript -c pg-macros -d build/pg-macros source/main.ptx
  ```

  Upload the result to the host course's `templates/macros/`. Plain algebra and
  trigonometry problems will not need this.
- **Corrected copies of OPL problems**, if we go that route. Those are the
  `webwork2` mechanism and they do get uploaded to `templates/`.

## Where Reed's server stands (checked 2026-08-17)

`https://webwork.its.reed.edu/` is publicly reachable and reports **webwork2
2.20 / PG 2.20**, comfortably past the 2.19 minimum PreTeXt requires. It lists
three courses — `LTITest`, `LTITest2`, `MATH-001` — so the `anonymous` guest
course does not exist yet.

CORS could not be checked from here. Verify with:

```bash
curl -sI -X OPTIONS -H "Origin: https://kyleormsby.github.io" \
  https://webwork.its.reed.edu/webwork2/render_rpc | grep -i access-control
```

An `Access-Control-Allow-Origin` header in the response means it is configured.
Nothing means it is not, and problems will fail to render from the book with a
console error rather than a visible one.

## Recommended workflow

**Do not wait for Reed.** Authored problems render on whatever server the
publication file points at, and that is currently AIM's. You can write and test
problems today and switch servers later; nothing about the problems changes.

### 1. Prove the loop with one problem

Make `problems/` at the repository root and write one deliberately simple `.pg`
file. Add it to a worksheet with `xi:include` as above — remembering the `xi`
namespace declaration on that worksheet's root element — then:

```bash
pretext generate webwork -t course
pretext build course
pretext view course
```

Work the problem in the browser: submit a right answer, submit a wrong one, hit
"randomize". Confirm `generated-assets/webwork/pg/` now contains your `.pg`.

Getting this end-to-end on one trivial problem is worth more than getting five
interesting problems half-written.

### 2. Settle the conventions

Once one works, decide the boring things before there are thirty: one problem
per file, a naming scheme that says which worksheet a problem belongs to, and
a `seed` attribute where you want a specific randomization pinned.

### 3. Move to Reed

Ask the WeBWorK administrator for the guest course and the CORS headers, using
`webwork-server-setup.md` — it is written to be forwarded. Then change one line
in `publication/publication.ptx`:

```xml
<webwork server="https://webwork.its.reed.edu" />
```

Protocol included, no trailing slash. Rebuild and re-test the same problem.
If the guest course uses credentials other than `anonymous`, set `@course`,
`@user` and `@password` too.

### 4. Only then, corrected OPL copies

Serving our own fixes for the two dozen commented-out problems means uploading
`.pg` files to the host course's `templates/`, which is the `webwork2`
mechanism and depends on step 3. Keep those files in this repository too, so
what is on the server can be rebuilt from what is in git.

## Things worth knowing

**The build talks to the server.** `pretext generate webwork` contacts it once
per problem to build the static representations, so the GitHub Actions runner
has to reach it. Reed's server is public today; if it ever moves behind the
campus firewall, CI breaks and the fix is to commit `generated-assets/` rather
than regenerating on every run.

**Answers still are not recorded.** Authoring our own problems changes nothing
about this. Anonymous readers have no identity, and no static host can give
them one. See the last section of `webwork-server-setup.md`.

**Exercises in worksheets render dynamically** here, per the `<webwork>` block
in the publication file, so an authored problem will be interactive in the same
way the OPL ones are.
