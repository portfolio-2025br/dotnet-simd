#!/bin/bash -e

# ################################################################################
#  Copyright (c) 2025  Claudio André <portfolio-2025br at claudioandre.slmail.me>
#              ___                _      ___       _
#             (  _`\             ( )_  /'___)     (_ )  _
#             | |_) )  _    _ __ | ,_)| (__   _    | | (_)   _
#             | ,__/'/'_`\ ( '__)| |  | ,__)/'_`\  | | | | /'_`\
#             | |   ( (_) )| |   | |_ | |  ( (_) ) | | | |( (_) )
#             (_)   `\___/'(_)   `\__)(_)  `\___/'(___)(_)`\___/'
#
# This program comes with ABSOLUTELY NO WARRANTY; express or implied.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, as expressed in version 2, seen at
# https://www.gnu.org/licenses/gpl-2.0.html
###############################################################################
# Script to control the automatic merge process
# More info at https://github.com/portfolio-2025br/dotnet-simd

APPROVALS=0
MY_MESSAGE=""
STATUS=0

if [[ "$REQUEST" != "bot: MERGE"* ]]; then
	echo "There is no need for a merge! Nothing to do."
	exit 0
fi

if [[ "$REQUEST" == "bot: MERGE skip" || "$REQUEST" == "bot: MERGE trial" ]]; then
	echo "I'm not validating the PR data in this workflow."
	echo "All GitHub rules still apply."
	MY_MESSAGE="I'm not validating the PR data in this workflow.\n"
	SKIP="true"
fi

if [[ "$REQUEST" == "bot: MERGE trial" ]]; then
	echo "Trial mode: I'm pretending to create a merge."
	MY_MESSAGE+="No changes will be submitted to GitHub."
	TRIAL="true"
fi
REVIEWS_STATUS="$(gh pr view "$PR_URL" --json reviewDecision --jq '.reviewDecision')"
MERGE_STATUS="$(gh pr view "$PR_URL" --json mergeStateStatus --jq '.mergeStateStatus')"
test "$REVIEWS_STATUS" == "APPROVED" && APPROVALS=1
test "$MERGE_STATUS" == "CLEAN" && STATUS=1

echo "**********************************************************************"
echo -e "Approved: $REVIEWS_STATUS"
echo -e "Mergeable: $MERGE_STATUS"
echo -e "$MY_MESSAGE"
echo "**********************************************************************"
echo "reviewDecision: $(gh pr view "$PR_URL" --json reviewDecision)"
echo "mergeStateStatus: $(gh pr view "$PR_URL" --json mergeStateStatus)"
echo "**********************************************************************"

if [[ "$REQUEST" == "bot: MERGE status" || "$SKIP" == "true" ]]; then
	test "$REVIEWS_STATUS" == "APPROVED" && MARK_1="✔"

	if [[ "$MERGE_STATUS" == "CLEAN" ]]; then
		MARK_2="✔"
	else
		MARK_2="❌"
	fi
	gh pr comment "$PR_URL" --body "
	🤖: status
	- reviewDecision: $REVIEWS_STATUS $MARK_1
	- mergeStateStatus: $MERGE_STATUS $MARK_2
	"

	if [[ "$REQUEST" == "bot: MERGE status" ]]; then
		exit 0
	fi
fi
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
DEST_BRANCH="$BRANCH"

if [[ "$GITHUB_EVENT_NAME" == "pull_request_review" ]]; then
	echo "In a code review I can't see the status of the PR, so ignore it."
	STATUS=1
fi

if [[ ("$APPROVALS" -ge 1 && "$STATUS" -ge 1) || "$SKIP" == 'true' ]]; then
	if [[ "$OWNER" != "portfolio-2025br" ]]; then
		echo "The PR comes from a fork."
		DEST_BRANCH="$OWNER-$BRANCH"
		git checkout -b "$DEST_BRANCH" main
		git pull "https://github.com/$OWNER/$REPO.git" "$BRANCH"
	else
		git checkout "$DEST_BRANCH"
	fi
	echo "Merging the PR."
	RESULT="$(
		git merge-base --is-ancestor origin/main "$DEST_BRANCH"
		echo $?
	)"

	if [[ $RESULT -ne 0 ]]; then
		echo "**********************************************************************"
		echo "Diverging branches can't be fast-forwarded:"
		echo "- please, rebase."
		echo "**********************************************************************"
		exit 1
	fi
	git checkout main
	git merge --ff-only "$DEST_BRANCH" || exit 1

	if [[ "$TRIAL" != 'true' ]]; then
		git push origin main
	else
		echo "No new data has been submitted to be saved on GitHub."
	fi
	git log -1
else
	echo "PR is not ready for merging! Nothing to do."
	exit 1
fi
