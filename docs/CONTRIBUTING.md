# Contribution Guideline

This guide describes how to work with branches, commits and pull requests.

Both for contributors and reviewers, well-established conventions for structure,
naming and formatting will save time and hassle caused by improperly created branches,
commits or pull requests that have to be rejected and re-submitted.

-   [Branch name convention](#branch-name-convention)
-   [Commit message convention](#commit-message-convention)
-   [Pull Request convention](#pull-request-convention)

## Branch name convention

1. Use prefix to define branch type
2. Use issue ticket number to link it with issue tracker system
3. Define scope of affected part of project
4. Define short description of changes
5. Use dash to separate words
6. Use small letters

**1. Prefix**

Use prefix _release_ for preparation of a new production release,
and _hotfix_ for critical production fix.

Skip other type, such as _bugfix_ and _feature_, to make branch name shorter.

Separate prefix and next word with slash.

**2. Issue ticket number**

We use Jira for our issue tracking, so including the number makes it easier to look up in the system and allow to keep branch names unique.

Including that number also makes it searchable when trying to find that issue inside repository when trying to submit a pull request.

**3. Define scope of affected part of project**

Scope helps to quickly understand which part of the project is affected.
Example of scope might be _platform_, _dashboard_, _simulator_, _editor_ or _timeline_. See more allowed scopes in commit message convention.
If you're having a hard time to define scope, you might be having
general-purpose branch. Strive for one-purpose branch.

Skip scope if changes are done across many places.

**4. Define short description of changes**

Add few short and descriptive words to describe context or reason.
Words _bug_ or _feat_ can be used to tell to which part of workflow the branch belongs.

**5. Use dash to separate words**

A branch name cannot have space, so use dashed-multi-words for branch name.

**6. Use small letters**

Simple rule is to use small letters everywhere to optimize readability.

### Format

```
(<type>/)<ticket-number>(-<scope>)-subject
```

### Examples

```
release/FNA-9272-20.1.1
hotfix/FNA-1234-editor-scripting-bug
FNA-1234-simulator-feat
FNA-1234-timeline-hover-bug
FNA-1234-admin-user-management-feat
FNA-1234-auth-bug
FNA-1234-dashboard-mapping-panel-bug
```

## Commit message convention

A commit message consists of a header, an optional body and an optional footer, separated by a blank line.
Any line of the commit message cannot be longer than 100 characters!
This allows the message to be easier to read on the web interface as well as in various tools.

### Message header

The message header is a single line that contains short description of the change.
It contains a ticket number, an optional type, an optional scope and a subject.

**Ticket number**

Jira ticket number to easy follow the issue.

**Allowed type**

This describes the kind of change that this commit is providing:

-   **feat** (feature)
-   **fix** (bug fix)
-   **docs** (documentation)
-   **style** (changes that not affect the meaning of the code (spaces, formatting, semi-colons)
-   **refactor** (changes that neither fixes a bug nor adds a feature)
-   **perf** (changes that improves performance)
-   **test** (adding missing tests or correcting existing tests)
-   **build** (change to build system or external dependencies)

**Allowed scope**

Scope defines affected part of the project:

-   **platform** (list of workspaces, dashboards, account setting)
-   **editor** (script editor, output, list of resources)
-   **admin** (scheduler, user management, workspace management)
-   **dashboard** (panels, views, timeline)
-   **simulator** (list of simulations, wizards, result)
-   **common** (ui-lib, utils-lib, http, models, navbar, auth, security)
-   **empty string** (might be used for changes that are done across many places)

**Subject text**

This is a very short description of the change.

-   use imperative, present tense: "change" not "changed" nor "changes"
-   begin subject with a small letter
-   no dot (.) at the end
-   should complete the sentence "If applied, this commit will _your subject line here_"

### Message body

Use the body to explain what and why vs. how. Body should help future maintainers to understand context and reason for change.
Includes motivation for the change and contrasts with previous behavior.

Just as in <subject>, try to use imperative, present tense: "change" not "changed" nor "changes".
But keep in mind, that use of the imperative is important only in the subject line.
You can relax this restriction when you’re writing the body.

### Message footer

Use the footer to put issue tracker references.

### Format

```
<ticket-number>: (<type>:<scope>) <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Example

```
FNA-1234: (fix:editor) correctly highlight script

Older IEs incorrectly highlight semi colon.
Add a special handler for older browsers.

Close FNA-1234
Partially mention in FNA-5678
```

## Pull Request convention

When development on a branch is completed and you are ready to propose your changes
to the main repository, follow next steps:

1. Be sure that your code is stable. Run command `ng build <app> --prod` if you are not sure.
2. Push your branch
3. In BitBucket, create a Pull Request to appropriate branch
4. Set your technical Leads as Reviewers
5. Make sure the branch is closed after merge
