#!/usr/bin/env python3
"""Cleaner command-line interface for pentool."""

from __future__ import annotations

import argparse
import logging
import os
import sys
from pathlib import Path
from typing import Callable, Optional, Sequence

from pentool.commands import (
    DiscoverOptions,
    FingerprintOptions,
    ScanOptions,
    WebMapOptions,
)
from pentool.commands.fingerprint import run_fingerprint
from pentool.commands.recon import run_recon
from pentool.commands.scan import run_scan
from pentool.commands.update_data import run_update_data
from pentool.commands.webmap import run_webmap
from pentool.docker_runner import DockerRunner

LOG = logging.getLogger("pentool")

TOOLKIT_NAME = "pentool"
DEFAULT_IMAGE = os.environ.get("PENTEST_TOOLKIT_IMAGE", "pentool:latest")
DEFAULT_CACHE_TTL = int(os.environ.get("PENTEST_TOOLKIT_CACHE_TTL", "14400"))


# -------------------------
# Command handler helpers
# -------------------------
def _make_runner(args: argparse.Namespace) -> DockerRunner:
    return DockerRunner(args.image, args.no_cache, args.cache_ttl)


def handle_update(args: argparse.Namespace) -> int:
    runner = _make_runner(args)
    run_dir = run_update_data(runner)
    print(run_dir)
    return 0


def handle_recon(args: argparse.Namespace) -> int:
    runner = _make_runner(args)

    # positional target wins, but must not mix with flags
    positional = getattr(args, "target", None)
    cidr = args.cidr
    host = args.host
    if positional:
        if cidr or host or args.targets:
            raise RuntimeError(
                "Provide recon targets via positional argument or flags, not both"
            )
        if "/" in positional:
            cidr = positional
        else:
            host = positional

    opts = DiscoverOptions(
        cidr=cidr,
        host=host,
        targets=Path(args.targets) if args.targets else None,
        top_ports=args.top_ports,
        rate=args.rate,
        refresh=args.refresh,
    )
    summary = run_recon(opts, runner)
    print(summary)
    return 0


def handle_fingerprint(args: argparse.Namespace) -> int:
    runner = _make_runner(args)
    opts = FingerprintOptions(
        input_path=Path(args.input) if args.input else None,
        targets=Path(args.targets) if args.targets else None,
        hosts=tuple(args.hosts or ()),
        enable_http=args.http,
        threads=args.threads,
        refresh=args.refresh,
    )
    summary = run_fingerprint(opts, runner)
    print(summary)
    return 0


def handle_webmap(args: argparse.Namespace) -> int:
    runner = _make_runner(args)
    opts = WebMapOptions(
        url=args.url,
        depth=args.depth,
        wordlist=Path(args.wordlist) if args.wordlist else None,
        rate=args.rate,
        refresh=args.refresh,
    )
    summary = run_webmap(opts, runner)
    print(summary)
    return 0


def handle_scan(args: argparse.Namespace) -> int:
    runner = _make_runner(args)
    opts = ScanOptions(url=args.url, profile=args.profile, refresh=args.refresh)
    summary = run_scan(opts, runner)
    print(summary)
    return 0


# -------------------------
# Argparse wiring
# -------------------------
def _load_usage() -> str:
    """Load epilog text from file."""
    usage_path = Path(__file__).parent / "resources", "USAGE.txt"
    if usage_path.exists():
        return usage_path.read_text(encoding="utf-8")
    return ""


class _HelpfulArgumentParser(argparse.ArgumentParser):
    """Argument parser that always shows epilog on errors."""

    def error(self, message: str) -> None:
        """Override error to always show epilog with help."""
        # print_help() already includes epilog, so just use it
        self.print_help(file=sys.stderr)
        self.exit(2, f"{self.prog}: error: {message}\n")


def build_parser() -> argparse.ArgumentParser:
    usage = _load_usage()
    parser = _HelpfulArgumentParser(
        prog=TOOLKIT_NAME,
        description=usage,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        usage=usage,
    )

    # global flags
    parser.add_argument(
        "--verbose", action="store_true", help="Enable verbose logging"
    )
    parser.add_argument(
        "--no-cache", action="store_true", help="Bypass cached results"
    )
    parser.add_argument(
        "--image", default=DEFAULT_IMAGE, help="Docker image to use/build"
    )
    parser.add_argument(
        "--cache-ttl",
        type=int,
        default=DEFAULT_CACHE_TTL,
        help="Cache TTL in seconds (0 disables expiry)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # update
    upd = subparsers.add_parser(
        "update", help="Refresh vulnerability and service datasets"
    )
    upd.set_defaults(func=handle_update)

    # recon
    recon = subparsers.add_parser("recon", help="Fast host/port recon")
    recon.add_argument("--cidr")
    recon.add_argument("--host")
    recon.add_argument("--targets", help="Targets file (one per line)")
    recon.add_argument("--top-ports", type=int, default=100)
    recon.add_argument(
        "--rate",
        type=int,
        default=int(os.environ.get("PENTEST_TOOLKIT_DISCOVER_RATE", "15000")),
    )
    recon.add_argument(
        "--refresh", action="store_true", help="Force re-run and ignore cache"
    )
    recon.add_argument(
        "target",
        nargs="?",
        help="CIDR or host positional shorthand (instead of --cidr/--host)",
    )
    recon.set_defaults(func=handle_recon)

    # fingerprint
    fingerprint = subparsers.add_parser(
        "fingerprint", help="Service fingerprinting and banners"
    )
    fingerprint.add_argument("--input", help="Recon JSON file")
    fingerprint.add_argument("--targets", help="Targets file (host[:port])")
    fingerprint.add_argument(
        "--http", action="store_true", help="Enable HTTP probing via httpx"
    )
    fingerprint.add_argument(
        "--threads",
        type=int,
        default=int(os.environ.get("PENTEST_TOOLKIT_HTTP_THREADS", "50")),
    )
    fingerprint.add_argument("--refresh", action="store_true")
    fingerprint.add_argument(
        "hosts", nargs="*", help="Host[:port] positional targets"
    )
    fingerprint.set_defaults(func=handle_fingerprint, hosts=[])

    # webmap
    webmap = subparsers.add_parser(
        "webmap", help="Automated web surface mapping"
    )
    webmap.add_argument("--url", required=True)
    webmap.add_argument("--depth", type=int, default=2)
    webmap.add_argument("--wordlist", help="Optional directory/file wordlist")
    webmap.add_argument(
        "--rate",
        type=int,
        default=int(os.environ.get("PENTEST_TOOLKIT_WEB_RATE", "50")),
    )
    webmap.add_argument("--refresh", action="store_true")
    webmap.set_defaults(func=handle_webmap)

    # scan
    scan = subparsers.add_parser("scan", help="Lightweight vulnerability scan")
    scan.add_argument("--url", required=True)
    scan.add_argument(
        "--profile", choices=["quick", "extended"], default="quick"
    )
    scan.add_argument("--refresh", action="store_true")
    scan.set_defaults(func=handle_scan)

    return parser


# -------------------------
# Entrypoint
# -------------------------
def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()

    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        # Re-raise SystemExit to preserve exit codes, but epilog is already shown
        # by our custom error handler
        raise

    # Check if no subcommand was provided (this shouldn't happen with required=True,
    # but handle it gracefully)
    if not hasattr(args, "func"):
        parser.error("no subcommand provided")

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
    )

    if args.cache_ttl < 0:
        parser.error("--cache-ttl must be >= 0")

    try:
        # call the handler bound to the subparser
        func: Callable[[argparse.Namespace], int] = getattr(args, "func")
        return func(args)
    except RuntimeError as exc:
        LOG.error("%s", exc)
        return 1
    except KeyboardInterrupt:
        LOG.error("Interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())
