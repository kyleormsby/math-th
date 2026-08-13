# Serving these problems from Reed's WeBWorK

## Where things stand

`publication/publication.ptx` currently points at AIM's public PreTeXt WeBWorK
server:

```xml
<webwork server="https://webwork-ptx.aimath.org" />
```

This is the PreTeXt default. It is already configured, it requires nothing from
anyone at Reed, and it is the right choice for the prototype.

Two reasons to move off it eventually:

1. **No guarantees.** There is no published uptime commitment, rate limit, or
   acceptable-use policy for that server. Fine for a prototype; thin ground for
   a resource students are told to rely on.
2. **We need our own copies of the problems.** Every exercise here is a
   reference into the Open Problem Library (`Contrib/CCCS/PreCalculus/...`).
   Some of those problems have errors that were fixed on Reed's WeBWorK but not
   upstream, and a couple dozen more are commented out because they failed
   outright. Serving corrected copies means serving them from a course we
   control.

## What to ask Reed's WeBWorK administrator for

Rendering PreTeXt problems is a different mode of operation from running a
WeBWorK course, so it is worth being specific.

**Version:** webwork2 2.19 or later.

**CORS.** In `webwork2/conf/webwork2.mojolicious.yml`, uncomment the
`Access-Control-Allow-Origin: '*'` headers for these three paths:

- `/webwork2/render_rpc`
- `/webwork2_files`
- `/pg_files`

(`html2xml` is the legacy endpoint and can stay commented out; `render_rpc` is
the current one.) Also set `allow_unsecured_rpc: 1`, then restart webwork2.

**A guest course named `anonymous`.** Readers are anonymous by definition, so
this course is what renders problems for the public. Its credentials are
published in our source, so it has to be locked down: in Course Configuration
set all permissions to `admin` (or `nobody`) *except* "Allowed to login to the
course" and "Allowed to view course home page", both of which should be
`login_proctor`. Add a user `anonymous` with permission level `login_proctor`
and password `anonymous`.

**Hint and solution visibility.** In that course's `course.conf`:

```perl
$pg{specialPGEnvironmentVars}{ALWAYS_SHOW_HINT_PERMISSION_LEVEL} = 100;
$pg{specialPGEnvironmentVars}{ALWAYS_SHOW_SOLUTION_PERMISSION_LEVEL} = 100;
```

**Then, on our side,** change `@server` in `publication/publication.ptx` to the
Reed URL — protocol included, no trailing slash — and rebuild. If the guest
course uses credentials other than `anonymous`, set `@course`, `@user`, and
`@password` too.

Reference: the PreTeXt Guide, "Configuring a `webwork2` Server for PreTeXt" and
"Configuring a WeBWorK Course for PreTeXt".

## Hosting corrected copies of the problems

Once we are serving from Reed, fixing a problem means editing a `.pg` file
rather than working around an upstream bug. The shape of that change:

1. Put the corrected `.pg` files in this repository (a `problems/` directory),
   and reference them with a local path instead of an OPL path.
2. Upload them to the `anonymous` course's `templates/` directory on the Reed
   server, or arrange for the server to pull them from this repository.

If any problem uses PG macros generated from our own source — TikZ images via
`latex-image-preamble`, for instance — run `pretext -c pg-macros` and install
the result in the host course's `templates/macros/`.

## What this does not get us

Pointing at Reed's server changes *where problems come from*. It does not make
answers persist. Anonymous readers have no identity, so there is still no
record and no gradebook, on any static host.

Getting scores recorded is a separate decision with three known paths:

- **Host the book on Runestone Academy**, which stores answers and scores
  against student accounts and can push grades into Moodle over LTI.
- **Generate real WeBWorK sets** with `pretext -c all -f webwork-sets` and run
  them as an ordinary WeBWorK course with real logins.
- **LTI into Moodle** via either of the above.

Worth keeping separate from the hosting question: a good public practice
resource and a gradable assignment are different products, and this repository
can produce both from the same source.
