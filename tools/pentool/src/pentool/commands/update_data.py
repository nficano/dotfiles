"""Dataset refresh command."""

from __future__ import annotations

from pathlib import Path
from typing import List, Optional, Sequence, Tuple

from pentool.docker_runner import DockerRunner
from pentool.utils import append_log, utc_timestamp

# ──────────────────────────────────────────────────────────────────────────────
# Task definitions
# ──────────────────────────────────────────────────────────────────────────────


def _task_definitions(
    run_dir: Path, run_rel: str
) -> List[Tuple[str, Sequence[str], bool, Optional[Path]]]:
    """Generate task definitions for dataset updates."""
    base_host = run_dir
    return [
        (
            "Updating nmap script database",
            ["nmap", "--script-updatedb"],
            True,
            None,
        ),
        ("Updating Nikto signatures", ["nikto", "--update"], True, None),
        ("Updating sqlmap catalog", ["sqlmap", "--update"], True, None),
        (
            "Recording amass source inventory",
            ["amass", "enum", "-list"],
            True,
            base_host / "amass-sources.txt",
        ),
        ("Verifying httpx binary freshness", ["httpx", "-version"], True, None),
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Task execution
# ──────────────────────────────────────────────────────────────────────────────


def _normalize_output(output: str) -> str:
    """Ensure output ends with newline."""
    return output if output.endswith("\n") else f"{output}\n"


def _append_task_log(log_path: Path, message: str) -> None:
    """Append task start message to log."""
    append_log(log_path, f"[{utc_timestamp()}] {message}\n")


def _append_output_log(log_path: Path, output: str) -> None:
    """Append command output to log."""
    normalized = _normalize_output(output)
    append_log(log_path, normalized)


def _append_error_log(
    log_path: Path, command: Sequence[str], return_code: int
) -> None:
    """Append error message to log."""
    command_str = " ".join(command)
    append_log(
        log_path,
        f"[{utc_timestamp()}] command {command_str} exited with code {return_code}\n",
    )


def _write_output_to_sink(sink: Path, output: str) -> None:
    """Write command output to sink file."""
    sink.parent.mkdir(parents=True, exist_ok=True)
    sink.write_text(output, encoding="utf-8")


def _execute_task(
    runner: DockerRunner,
    log_path: Path,
    env: dict,
    message: str,
    command: Sequence[str],
    allow_failure: bool,
    sink: Optional[Path],
) -> None:
    """Execute a single update task."""
    _append_task_log(log_path, message)
    return_code, output = runner.run_collect(
        command, env, allow_failure=allow_failure
    )

    if output:
        _append_output_log(log_path, output)

    if return_code != 0 and allow_failure:
        _append_error_log(log_path, command, return_code)

    if sink is not None:
        _write_output_to_sink(sink, output)


def _run_update_tasks(
    runner: DockerRunner, run_dir: Path, run_rel: str
) -> None:
    """Execute all update tasks."""
    log_path = run_dir / "update-log.txt"
    env = {"RUN_DIR": f"/work/{run_rel}"}

    for message, command, allow_failure, sink in _task_definitions(
        run_dir, run_rel
    ):
        _execute_task(
            runner, log_path, env, message, command, allow_failure, sink
        )


def _update_last_update_timestamp(runner: DockerRunner) -> None:
    """Write current timestamp to last-update file."""
    last_update = runner.paths.data / "last-update.txt"
    last_update.write_text(f"{utc_timestamp()}\n", encoding="utf-8")


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────


def run_update_data(runner: DockerRunner) -> Path:
    """Run dataset update tasks."""
    runner.ensure_image()
    run_dir = runner.new_run_dir("update", "datasets")
    run_rel = runner.relative_posix(run_dir)

    _run_update_tasks(runner, run_dir, run_rel)
    _update_last_update_timestamp(runner)

    return run_dir
