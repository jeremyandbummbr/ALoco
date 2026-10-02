#!/usr/bin/env python3
"""Convert this Mac's pymobiledevice3 RPPairing record for ALOCO/idevice.

The input and output contain private device-pairing credentials. Keep both
outside source control and never upload them.
"""

import argparse
import os
import platform
import plistlib
import uuid
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="pymobiledevice3 remote-pairing plist")
    parser.add_argument("output", type=Path, help="private output plist for ALOCO")
    parser.add_argument(
        "--hostname",
        default=platform.node(),
        help="hostname used during pairing (defaults to this Mac's hostname)",
    )
    args = parser.parse_args()

    source = plistlib.loads(args.input.read_bytes())
    public_key = source["public_key"]
    private_key = source["private_key"]
    if not isinstance(public_key, bytes) or len(public_key) != 32:
        parser.error("input public_key must be 32 bytes")
    if not isinstance(private_key, bytes) or len(private_key) != 32:
        parser.error("input private_key must be 32 bytes")

    record = {
        "public_key": public_key,
        "private_key": private_key,
        "identifier": source.get("host_identifier")
        or str(uuid.uuid3(uuid.NAMESPACE_DNS, args.hostname)).upper(),
    }
    alt_irk = source.get("peer_alt_irk")
    if isinstance(alt_irk, bytes) and len(alt_irk) == 16:
        record["alt_irk"] = alt_irk

    args.output.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(args.output, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "wb") as output:
            plistlib.dump(record, output)
        os.chmod(args.output, 0o600)
    except BaseException:
        args.output.unlink(missing_ok=True)
        raise
    print(f"Wrote idevice-compatible RPPairing record to {args.output}")


if __name__ == "__main__":
    main()
