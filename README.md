[![Build Status](https://travis-ci.org/emberjs/ember-dev.png?branch=master)](https://travis-ci.org/emberjs/ember-dev)
## Ember Dev

Ember Dev is a gem for developing Ember.js packages. The initial goal is
to share tooling between Ember Core and Ember Data. The second goal is
to provide tooling for developers seeking to develop packages for Ember.
(This is not intended to be a tool for developing Ember applications.)

### Use

Unfortunately, this project isn't yet in a state where we can recommend
public use. We're lacking a few important features such as generators
that are required for general ease of use. If you're interested in
helping improve this project, please let us know and we can give you
some direction of where help is needed.

### Thanks

A big thanks to [CrowdStrike](http://www.crowdstrike.com/) for
supporting the initial work necessary to extract this code from the
Ember repos. 

### Multi-Branch Testing

In order to automatically handle the merging needs for the three release
channels within Ember we need to have a way to easily merge the commits
that are destined for multiple branches (i.e. bugfixes) into those appropriate
branches.

`ember-dev` attempts to bridge that gap by reviewing each commit to see if it
has a special tag, and then attempts to use the flag to cherry-pick that
commit into the appropriate branch.

* Special Commit Messages
  * [BUGFIX beta] - This commit needs to be backported to the beta branch.
  * [BUGFIX release] - This commit needs to be backported to the beta and release branches.
  * [SECURITY] - This commit needs to be backported to the beta, release, and prior tagged release branch.


Standard Pull Request process:

1. Determine test targets. This entails listing the commits included in the PR, and
  checking to see if they have any of the special commit messages listed above.
2. All PR's will be tested against master first, then if it applies to other branches
  also we will perform the following:
  * Turn Travis's shallow repo into a full repo. (`git fetch --unshallow`)
  * Checkout the secondary branch (let's assume beta). (`git checkout beta`)
  * Cherry pick the specific commits in question. (`git cherry-pick <SHA>1)
  * Run full test suite against affected branch.
3. Repeat until all branches have been tested.

If at any stage in the above process there is a test failure, the remaining tests will not be run.
