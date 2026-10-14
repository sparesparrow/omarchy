echo "Invite existing installs to try Studio"

# First-run already completed for existing accounts, so they would never
# receive the invitation. The hook decides whether to notify.
omarchy-hook-install post-update "$OMARCHY_PATH/install/user/first-run/setup-studio.hook"
