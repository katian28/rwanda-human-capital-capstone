# Capstone 2026–27 — Gwaneza Katia Nkurunziza

This repository is the record of your capstone project. It is private: only you and your supervisor can see it. You own everything in it.

## Pushing your work

**I recommend that you commit and push whenever you stop working** — every time you close the laptop. At a minimum, push once a week, even if the week was a thin one. The history of how your project developed is part of what is assessed, and it is also yours: it will write most of your final reflection for you.

## What lives here

- your work (code, or paper source, plus bibliography, figures, data);
- `PLAN.md` — your milestone plan. Write it by the end of week 2. We will compare progress against *your* plan, not a generic one;
- `PROGRESS.md` — before each meeting, add three lines: what you did, what's next, what's blocking you.

## What to keep out

Push your capstone work. If your project builds on something you already own or have
published, involves code or data belonging to someone else, or is covered by a
confidentiality arrangement, talk to me **before** you push it and we will agree what
belongs in this repository and what stays outside it. Because of the mirror described
under "Privacy and ownership" below, this is far easier to settle now than to undo later.

## What your supervisor sees

Your supervisor takes a daily snapshot of this repository and, before each meeting, looks at what changed since the last one and compares it with your `PROGRESS.md` note. Nobody counts commits. A week with one substantial push is not worse than a week with twenty small ones. What matters is that the work in the repo and the note you write agree.

## Getting set up

1. Accept the invitation email from GitHub.
2. Clone this repository to a folder on your computer, using whatever you already use for Git — the terminal, the Source Control panel in VS Code, your editor's built-in version control. If you don't already have a way, [GitHub Desktop](https://desktop.github.com/) is the simplest: install it, sign in, and you will only ever need two buttons, **Commit** and **Push**.
3. Follow the section below for how you work.

### If you already have a repository for this project

**Don't clone this one.** You would end up with two folders that both look like your
project, and it is easy to spend a week committing in the wrong one. Work in the
folder you already have.

First, check whether anything secret was ever committed in your project's history —
an API key, a password, a `.env` file — including in an old commit you later cleaned
up. Deleting a file does not remove it from the history. Once it is pushed here it
is preserved, so if there is anything, talk to me **before** you push rather than
after.

Then, in your existing project folder (copy this repository's URL from the green
**Code** button above):

```
git remote add capstone <URL of this repository>
git fetch capstone
git merge capstone/main --allow-unrelated-histories
```

That brings this repository's `README.md`, `PLAN.md` and `PROGRESS.md` into your
project. If you already have a `.gitignore` there will be a conflict — keep both
sets of lines.

Now pick one:

**Work here from now on.** Your old repository stays where it is as a backup.

```
git remote rename origin personal
git remote rename capstone origin
git push origin main
```

**Or keep pushing to your own repository as well.** One `git push` then goes to
both:

```
git push capstone main
git remote remove capstone
git remote set-url --add --push origin <URL of your own repository>
git remote set-url --add --push origin <URL of this repository>
```

Either way, run `git remote -v` afterwards and check it points where you expect.
If your work is not arriving in this repository, I cannot see it, and as far as
the record is concerned it did not happen.

## If you are building software

Work in the cloned folder as you normally would. Commit with a short message describing the change; push when you stop. Keep secrets (API keys, credentials) out of the repo — use a `.env` file listed in `.gitignore`.

## Privacy and ownership

The repository is private to you and your supervisor. Nothing here is shared with other students or made public. Monitoring the repository does not affect your ownership of your work.

Two things you should know about where copies of your work live. Your repository is on GitHub, like any private repository. Your supervisor also keeps a dated mirror of it on their own encrypted computer for the duration of the course, so that the history of your project is preserved even if the repository on GitHub is later changed or deleted; that mirror is deleted once final grades and the appeal period have passed. Before our meetings I use Claude, under my own account, to help me summarize what changed in your repository; the summary always links back to your files, and I read the files, not just the summary.

Everything your supervisor learns from this repository, you can see too: the summary you receive before each meeting is written from the same evidence as theirs.
