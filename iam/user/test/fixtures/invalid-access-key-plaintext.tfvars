# Must fail: create_access_key without pgp_key (and without the explicit
# allow_plaintext_credentials_in_state opt-out) would store the secret key
# in plaintext in state.
name              = "terratest-plan"
create_access_key = true
