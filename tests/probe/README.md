This is a small test area for generating the entire range of possible
message corruption errors.  We do this by permuting every byte of the
encrypted block of input.onetime (whose plaintext is "Hello, world!"
without the quotes) through every possible value 0-255, and trying to
decrypt for each value at each position.

Because the input is base64-encoded, most most of these single-byte
corruptions cause the base64 error: "TypeError: Incorrect padding".
Of those that still result in valid base64, many are "expected fuzz
does not match message fuzz", because the plaintext is so short that
much of the encrypted block is head or tail fuzz.  In the encrypted
text range, most corruptions lead to a bunzip2 error "IOError: invalid
data stream", but a few lead to a "message digest mismatch" error.  A
few corruptions still lead to a successful decryption.

See probe.sh for more.
