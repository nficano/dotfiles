"""Docker execution utilities."""

from __future__ import annotations

import datetime as dt
import logging
import os
import random
import shlex
import shutil
import subprocess
from dataclasses import dataclass
from datetime import timezone as tz
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple
from urllib.parse import quote

from .constants import dockerfile_content, dockerignore_content
from .utils import CacheKey, append_log, slugify

logger = logging.getLogger("pentool")


# ──────────────────────────────────────────────────────────────────────────────
# Data models
# ──────────────────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class RunnerPaths:
    """Container paths for Docker runner operations."""

    root: Path
    runs: Path
    cache: Path
    data: Path
    docker_context: Path


@dataclass
class file_lock:
    """File-based lock context manager."""

    path: Path

    def __enter__(self) -> None:
        """Acquire file lock."""
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.fd = os.open(self.path, os.O_CREAT | os.O_RDWR)
        try:
            import fcntl
        except ImportError as exc:  # pragma: no cover
            raise RuntimeError(
                "pentool requires POSIX locking support"
            ) from exc
        fcntl.flock(self.fd, fcntl.LOCK_EX)

    def __exit__(self, exc_type, exc, traceback) -> None:  # type: ignore[override]
        """Release file lock."""
        import fcntl

        fcntl.flock(self.fd, fcntl.LOCK_UN)
        os.close(self.fd)


# ──────────────────────────────────────────────────────────────────────────────
# Docker runner class
# ──────────────────────────────────────────────────────────────────────────────


class DockerRunner:
    """Manages Docker container execution for pen testing tools."""

    def __init__(self, image: str, no_cache: bool, cache_ttl: int) -> None:
        """Initialize Docker runner with configuration."""
        self.image = image
        self.no_cache = no_cache
        self.cache_ttl = cache_ttl
        self.paths = self._init_paths()
        self.docker_opts = self._load_docker_opts()
        self.extra_volumes = self._load_extra_volumes()
        self.proxy_env = self._load_decodo_proxy_env()
        if shutil.which("docker") is None:
            raise RuntimeError("Docker executable not found in PATH")
        self._ensure_docker_daemon()
        self._image_ready = False

    # ──────────────────────────────────────────────────────────────────────────────
    # Path initialization
    # ──────────────────────────────────────────────────────────────────────────────

    def _init_paths(self) -> RunnerPaths:
        """Initialize and create all required paths."""
        cache_base = (
            Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
            / "dotfiles"
        )
        root = cache_base / "pentool"
        paths = RunnerPaths(
            root=root,
            runs=root / "runs",
            cache=root / "cache",
            data=root / "datasets",
            docker_context=root / "docker",
        )
        self._create_paths(paths)
        return paths

    def _create_paths(self, paths: RunnerPaths) -> None:
        """Create all required directory paths."""
        for path in (paths.runs, paths.cache, paths.data, paths.docker_context):
            path.mkdir(parents=True, exist_ok=True)
        for namespace in ("discover", "fingerprint", "webmap", "scan"):
            (paths.cache / namespace).mkdir(parents=True, exist_ok=True)

    # ──────────────────────────────────────────────────────────────────────────────
    # Configuration loading
    # ──────────────────────────────────────────────────────────────────────────────

    def _load_docker_opts(self) -> List[str]:
        """Load Docker options from environment or use defaults."""
        env_opts = os.environ.get("PENTEST_TOOLKIT_DOCKER_OPTS")
        if env_opts:
            return shlex.split(env_opts)
        return ["--network=host", "--cap-add=NET_RAW", "--cap-add=NET_ADMIN"]

    def _load_extra_volumes(self) -> List[str]:
        """Load extra Docker volumes from environment."""
        extra = os.environ.get("PENTEST_TOOLKIT_DOCKER_VOLUMES")
        volumes: List[str] = []
        if not extra:
            return volumes
        for line in extra.splitlines():
            line = line.strip()
            if line:
                volumes.extend(["-v", line])
        return volumes

    def _parse_decodo_int_env(self, name: str, default: int) -> int:
        """Parse integer environment variable with validation."""
        value = os.environ.get(name)
        if value in (None, ""):
            return default
        try:
            return int(value)
        except ValueError:
            logger.warning(
                "Invalid %s value %r; ignoring Decodo proxy", name, value
            )
            raise

    def _validate_decodo_port_range(
        self, start_port: int, range_size: int
    ) -> bool:
        """Validate Decodo port range configuration."""
        if start_port <= 0:
            logger.warning(
                "DECODO_PORT_RANGE_START must be > 0; ignoring Decodo proxy"
            )
            return False
        if range_size <= 0:
            logger.warning(
                "DECODO_PORT_RANGE_SIZE must be > 0; defaulting to 1"
            )
            return False
        return True

    def _get_decodo_port_index(self, range_size: int) -> Optional[int]:
        """Get Decodo port index from environment or return None."""
        port_index_env = os.environ.get("DECODO_PORT_INDEX")
        if port_index_env in (None, ""):
            return None
        try:
            index = int(port_index_env)
        except ValueError:
            logger.warning(
                "Invalid DECODO_PORT_INDEX %r; selecting random port",
                port_index_env,
            )
            return None
        if index < 0 or index >= range_size:
            logger.warning(
                "DECODO_PORT_INDEX %s out of range 0..%s; selecting random port",
                port_index_env,
                range_size - 1,
            )
            return None
        return index

    def _calculate_decodo_port(self, start_port: int, range_size: int) -> int:
        """Calculate Decodo proxy port from configuration."""
        if range_size == 1:
            return start_port
        index = self._get_decodo_port_index(range_size)
        if index is not None:
            return start_port + index
        return random.SystemRandom().randrange(
            start_port, start_port + range_size
        )

    def _build_decodo_proxy_url(
        self, gateway: str, user: str, password: str, port: int
    ) -> str:
        """Build Decodo proxy URL with authentication."""
        auth = f"{quote(user, safe='')}:{quote(password, safe='')}"
        return f"http://{auth}@{gateway}:{port}"

    def _build_decodo_proxy_env(self, proxy_url: str) -> Dict[str, str]:
        """Build environment variables for Decodo proxy."""
        return {
            "HTTP_PROXY": proxy_url,
            "HTTPS_PROXY": proxy_url,
            "ALL_PROXY": proxy_url,
            "http_proxy": proxy_url,
            "https_proxy": proxy_url,
            "all_proxy": proxy_url,
        }

    def _load_decodo_proxy_env(self) -> Dict[str, str]:
        """Load Decodo proxy configuration from environment."""
        gateway = os.environ.get("DECODO_GATEWAY_URL")
        user = os.environ.get("DECODO_AUTH_USER")
        password = os.environ.get("DECODO_AUTH_PASS")
        if not gateway or not user or not password:
            return {}

        try:
            start_port = self._parse_decodo_int_env(
                "DECODO_PORT_RANGE_START", 0
            )
            range_size = self._parse_decodo_int_env("DECODO_PORT_RANGE_SIZE", 1)
        except ValueError:
            return {}

        if not self._validate_decodo_port_range(start_port, range_size):
            if range_size <= 0:
                range_size = 1
            else:
                return {}

        port = self._calculate_decodo_port(start_port, range_size)
        proxy_url = self._build_decodo_proxy_url(gateway, user, password, port)
        logger.debug("Using Decodo proxy endpoint %s:%s", gateway, port)
        return self._build_decodo_proxy_env(proxy_url)

    # ──────────────────────────────────────────────────────────────────────────────
    # Docker daemon and image management
    # ──────────────────────────────────────────────────────────────────────────────

    def _ensure_docker_daemon(self) -> None:
        """Verify Docker daemon is accessible."""
        try:
            subprocess.run(
                ["docker", "info"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            logger.warning("Docker daemon not reachable: %s", exc)

    def _check_image_exists(self) -> bool:
        """Check if Docker image exists."""
        result = subprocess.run(
            ["docker", "image", "inspect", self.image],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return result.returncode == 0

    def ensure_image(self) -> None:
        """Ensure Docker image exists, building if necessary."""
        if self._image_ready:
            return
        if not self._check_image_exists():
            self.build_image()
        else:
            logger.debug("Container image %s present", self.image)
        self._image_ready = True

    def _write_docker_context_files(self) -> None:
        """Write Dockerfile and .dockerignore to context directory."""
        dockerfile = self.paths.docker_context / "Dockerfile"
        dockerignore = self.paths.docker_context / ".dockerignore"
        dockerfile.write_text(dockerfile_content())
        dockerignore.write_text(dockerignore_content())

    def build_image(self) -> None:
        """Build Docker image from context."""
        logger.info("Building container image %s", self.image)
        self._write_docker_context_files()
        lock_path = self.paths.root / ".build.lock"
        with self.file_lock(lock_path):
            try:
                subprocess.run(
                    [
                        "docker",
                        "build",
                        "-t",
                        self.image,
                        str(self.paths.docker_context),
                    ],
                    check=True,
                )
            except subprocess.CalledProcessError as exc:
                raise RuntimeError(
                    f"Failed to build docker image {self.image}: {exc}"
                ) from exc
        logger.info("Image %s ready", self.image)

    # ──────────────────────────────────────────────────────────────────────────────
    # Command building
    # ──────────────────────────────────────────────────────────────────────────────

    def _build_base_env_vars(
        self, extra_env: Optional[Dict[str, str]]
    ) -> Dict[str, str]:
        """Build base environment variables for container."""
        env_vars = {
            "HOME": "/datasets/tool-home",
            "TOOLKIT_DATA_HOME": "/datasets",
        }
        if extra_env:
            env_vars.update(
                {k: v for k, v in extra_env.items() if v is not None}
            )
        if self.proxy_env:
            env_vars.update(
                {k: v for k, v in self.proxy_env.items() if k not in env_vars}
            )
        return env_vars

    def _env_vars_to_args(self, env_vars: Dict[str, str]) -> List[str]:
        """Convert environment variables dictionary to Docker -e arguments."""
        env_args: List[str] = []
        for key, value in env_vars.items():
            env_args.extend(["-e", f"{key}={value}"])
        return env_args

    def _base_command(
        self, extra_env: Optional[Dict[str, str]] = None
    ) -> List[str]:
        """Build base Docker run command."""
        env_vars = self._build_base_env_vars(extra_env)
        env_args = self._env_vars_to_args(env_vars)

        cmd: List[str] = [
            "docker",
            "run",
            "--rm",
            "-v",
            f"{self.paths.root}:/work",
            "-v",
            f"{self.paths.data}:/datasets",
        ]
        cmd.extend(self.docker_opts)
        cmd.extend(self.extra_volumes)
        cmd.extend(env_args)
        cmd.append(self.image)
        return cmd

    # ──────────────────────────────────────────────────────────────────────────────
    # Container execution
    # ──────────────────────────────────────────────────────────────────────────────

    def _run_with_output(
        self, cmd: List[str], check: bool, timeout: Optional[float]
    ) -> subprocess.CompletedProcess:
        """Run Docker command with output capture."""
        return subprocess.run(
            cmd,
            check=check,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
        )

    def _run_without_output(
        self, cmd: List[str], check: bool, timeout: Optional[float]
    ) -> subprocess.CompletedProcess:
        """Run Docker command without output capture."""
        return subprocess.run(cmd, check=check, timeout=timeout)

    def run(
        self,
        args: Sequence[str],
        extra_env: Optional[Dict[str, str]] = None,
        *,
        check: bool = True,
        capture_output: bool = False,
        timeout: Optional[float] = None,
    ) -> subprocess.CompletedProcess:
        """Run command in Docker container."""
        cmd = self._base_command(extra_env)
        cmd.extend(args)
        logger.debug("Running container command: %s", shlex.join(cmd))
        try:
            if capture_output:
                result = self._run_with_output(cmd, check, timeout)
            else:
                result = self._run_without_output(cmd, check, timeout)
        except subprocess.CalledProcessError as exc:
            raise RuntimeError(f"Container execution failed: {exc}") from exc
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f"Container command timed out: {exc}") from exc
        return result

    def run_collect(
        self,
        args: Sequence[str],
        extra_env: Optional[Dict[str, str]] = None,
        *,
        allow_failure: bool = False,
        timeout: Optional[float] = None,
    ) -> Tuple[int, str]:
        """Run command and collect output."""
        result = self.run(
            args,
            extra_env,
            check=not allow_failure,
            capture_output=True,
            timeout=timeout,
        )
        output = result.stdout or ""
        return result.returncode, output

    # ──────────────────────────────────────────────────────────────────────────────
    # Run directory management
    # ──────────────────────────────────────────────────────────────────────────────

    def new_run_dir(self, prefix: str, label: str) -> Path:
        """Create new run directory with timestamp prefix."""
        ts = dt.datetime.now(tz.utc).strftime("%Y%m%d-%H%M%S")
        slug = slugify(label)
        path = self.paths.runs / f"{ts}-{prefix}-{slug}"
        path.mkdir(parents=True, exist_ok=False)
        return path

    def relative_posix(self, path: Path) -> str:
        """Convert path to relative POSIX path string."""
        return path.relative_to(self.paths.root).as_posix()

    # ──────────────────────────────────────────────────────────────────────────────
    # Cache management
    # ──────────────────────────────────────────────────────────────────────────────

    def _is_cache_expired(self, meta_path: Path) -> bool:
        """Check if cache entry has expired."""
        if self.cache_ttl <= 0:
            return False
        age = dt.datetime.now(tz.utc).timestamp() - meta_path.stat().st_mtime
        return age > self.cache_ttl

    def cache_lookup(self, key: CacheKey) -> Optional[Path]:
        """Look up cached run directory."""
        if self.no_cache:
            return None
        digest = key.render()
        meta = self.paths.cache / key.namespace / f"{digest}.meta"
        if not meta.exists():
            return None
        if self._is_cache_expired(meta):
            return None
        target = Path(meta.read_text().strip())
        if target.is_dir():
            return target
        return None

    def _update_cache_symlink(
        self, base: Path, label: str, run_dir: Path
    ) -> None:
        """Update latest symlink for cache namespace."""
        slug = slugify(label)
        latest = base / f"latest-{slug}"
        if latest.exists() or latest.is_symlink():
            latest.unlink()
        latest.symlink_to(run_dir)

    def cache_store(self, key: CacheKey, run_dir: Path, label: str) -> None:
        """Store run directory in cache."""
        digest = key.render()
        base = self.paths.cache / key.namespace
        base.mkdir(parents=True, exist_ok=True)
        meta = base / f"{digest}.meta"
        meta.write_text(str(run_dir))
        meta.touch()
        self._update_cache_symlink(base, label, run_dir)

    # ──────────────────────────────────────────────────────────────────────────────
    # Utility methods
    # ──────────────────────────────────────────────────────────────────────────────

    def append_run_log(
        self, run_dir: Path, filename: str, message: str
    ) -> None:
        """Append message to run log file."""
        append_log(run_dir / filename, message)

    file_lock = file_lock
