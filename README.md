# Math Trailhead

A self-paced precalculus and college algebra review built in
[PreTeXt](https://pretextbook.org), with every exercise a live
[WeBWorK](https://webwork.maa.org) problem.

**Live site:** https://kyleormsby.github.io/math-th/

## Status

Working prototype. 475 WeBWorK exercises across five chapters (Functions,
Exponents and Logarithms, Trigonometry, Polynomials and Rational Functions,
Algebra), imported from the
[Moodle course](https://moodle.reed.edu/course/view.php?id=6466).

Known gaps, carried over from the import:

- Roughly two dozen problems threw errors (most often a missing `statement`
  tag) and are commented out in place.
- Some problems have rendering issues that were fixed on Reed's WeBWorK but
  not in the Open Problem Library version referenced here, e.g. using `x`
  rather than `['x']` for LaTeX. Inline comments mark the cases that were
  noticed; there are probably more.
- The syllabus page is still template boilerplate.

Both classes of problem are the motivation for eventually hosting corrected
copies of the problems ourselves rather than referencing the OPL. See
`docs/webwork-server-setup.md`.

## How it is organized

Section introductions and the overall structure live in
[`source/main.ptx`](source/main.ptx). The individual pages within each
section are under [`source/activities`](source/activities).

Every exercise is a `<webwork source="Contrib/CCCS/..."/>` reference into the
Open Problem Library. No `.pg` files live in this repository; the problems
are rendered at read time by whichever WeBWorK server is named in
[`publication/publication.ptx`](publication/publication.ptx).

## Building locally

```bash
pretext build course   # build the HTML
pretext view course    # serve it and open a browser
```

The build needs network access to the WeBWorK server to generate problem
representations, and to Runestone's CDN for interactive components.

## Deploying

Pushing to `main` triggers `.github/workflows/pretext-cli.yml`, which builds
the book and publishes it to GitHub Pages. Nothing else is required; the
built HTML is deliberately not committed to the repository.

To publish without pushing a content change, run the **PreTeXt-CLI Actions**
workflow manually from the Actions tab.

See [`docs/deploying.md`](docs/deploying.md) for the one-time setup and for
notes on moving to Reed-hosted infrastructure.
