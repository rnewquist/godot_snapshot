#!/usr/bin/env python3
"""
godot_test.py
Universal CLI Orchestrator & Synchronization Engine for Godot 4.x Projects.
Supports:
  1. Synchronizing GDTest framework across registered projects ('sync')
     - Modes: --copy (default), --link (symlink + .git/info/exclude), --unlink, --git (submodule update)
     - Runner Fixer: --fix-runners (injects 3-frame graceful shutdown protocol)
     - Dry run and force flags: --dry-run, --force
  2. Installing the GDTest framework into any Godot project ('install')
  3. Generating new unit, integration, or visual audit test suites ('generate')
  4. Running all tests or filtering by individual test, suite, or tier/type ('run')
  5. Inspecting scene snapshots and logs
"""

import argparse
import json
import os
import re
import shutil
import socket
import struct
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

FRAMEWORK_ROOT = Path(__file__).resolve().parent.parent
WORKSPACE_ROOT = FRAMEWORK_ROOT.parent
ADDON_SOURCE = WORKSPACE_ROOT / "addons" / "gdtest"

# ANSI Terminal Color Formatting
COLOR_RESET = "\033[0m"
COLOR_BOLD = "\033[1m"
COLOR_RED = "\033[31m"
COLOR_GREEN = "\033[32m"
COLOR_YELLOW = "\033[33m"
COLOR_BLUE = "\033[34m"
COLOR_MAGENTA = "\033[35m"
COLOR_CYAN = "\033[36m"


def find_godot_binary() -> str:
    """Locate the Godot 4 binary."""
    if "GODOT_BIN" in os.environ and Path(os.environ["GODOT_BIN"]).exists():
        return os.environ["GODOT_BIN"]
    
    mac_paths = [
        "/Applications/Godot.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot.app/Contents/MacOS/Godot"),
    ]
    for p in mac_paths:
        if Path(p).exists():
            return p
            
    which_godot = shutil.which("godot") or shutil.which("godot4")
    if which_godot:
        return which_godot
        
    raise FileNotFoundError("Godot 4 binary not found. Set GODOT_BIN environment variable.")


# ==============================================================================
# PROJECT REGISTRY & PATH RESOLUTION ENGINE
# ==============================================================================

class ProjectRegistry:
    """Manages project configurations and flexible path resolution."""

    DEFAULT_PROJECTS = {
        "material3": {
            "path": "/Users/rnewquist/Documents/Godot/material3",
            "fallbacks": [
                "~/Documents/Godot/material3",
                "$HOME/Documents/Godot/material3",
                "../material3",
                "./material3"
            ],
            "runners": [
                "tests/gdtest_runner.gd",
                "tests/test_runner.gd",
                "tests/integration/test_showcase_scene_loading.gd"
            ],
            "description": "Material 3 Design System UI Component Library for Godot 4"
        },
        "guildmaster": {
            "path": "/Users/rnewquist/Documents/Godot/GuildMaster",
            "fallbacks": [
                "/Users/rnewquist/Documents/Godot/GuildMaster",
                "~/Documents/Godot/GuildMaster",
                "$HOME/Documents/Godot/GuildMaster",
                "../GuildMaster",
                "./GuildMaster"
            ],
            "runners": [
                "run_gdtest.gd"
            ],
            "description": "GuildMaster RPG Game Project"
        },
        "showcase_mega": {
            "path": "showcase_mega",
            "fallbacks": [
                "./showcase_mega",
                "$HOME/Documents/Skill Creation/showcase_mega"
            ],
            "runners": [
                "test_runner_scene.gd"
            ],
            "description": "Showcase Mega Godot 4 Integration Project"
        },
        "showcase_2d": {
            "path": "showcase_2d",
            "fallbacks": [
                "./showcase_2d",
                "$HOME/Documents/Skill Creation/showcase_2d"
            ],
            "description": "Showcase 2D Godot 4 Project"
        },
        "showcase_3d": {
            "path": "showcase_3d",
            "fallbacks": [
                "./showcase_3d",
                "$HOME/Documents/Skill Creation/showcase_3d"
            ],
            "description": "Showcase 3D Godot 4 Project"
        },
        "demo_2d": {
            "path": "demo_2d",
            "fallbacks": [
                "./demo_2d",
                "$HOME/Documents/Skill Creation/demo_2d"
            ],
            "description": "Demo 2D Godot 4 Project"
        },
        "demo_3d": {
            "path": "demo_3d",
            "fallbacks": [
                "./demo_3d",
                "$HOME/Documents/Skill Creation/demo_3d"
            ],
            "description": "Demo 3D Godot 4 Project"
        }
    }

    def __init__(self, workspace_root: Optional[Path] = None, registry_file: Optional[str] = None):
        self.workspace_root = workspace_root or WORKSPACE_ROOT
        self.registry_file = registry_file or ".gdtest_projects.json"
        self.raw_data: Dict[str, Any] = {}
        self.canonical_source_str: str = "addons/gdtest"
        self.projects_dict: Dict[str, Dict[str, Any]] = {}
        self.load()

    def load(self) -> None:
        """Loads configuration from .gdtest_projects.json or falls back to built-ins."""
        candidate_paths = [
            self.workspace_root / self.registry_file,
            Path.cwd() / self.registry_file,
            Path.home() / self.registry_file
        ]
        
        found_file = None
        for p in candidate_paths:
            if p.exists() and p.is_file():
                found_file = p
                break
                
        if found_file:
            try:
                with open(found_file, "r", encoding="utf-8") as f:
                    self.raw_data = json.load(f)
                self.canonical_source_str = self.raw_data.get("canonical_source", "addons/gdtest")
                self.projects_dict = self.raw_data.get("projects", {})
            except Exception as e:
                print(f"{COLOR_YELLOW}⚠️  Warning: Failed to parse {found_file}: {e}. Using defaults.{COLOR_RESET}")
                self.projects_dict = self.DEFAULT_PROJECTS
        else:
            self.projects_dict = self.DEFAULT_PROJECTS

    def resolve_raw_path(self, raw_path: str, fallbacks: Optional[List[str]] = None) -> Path:
        """Resolves path supporting ~, $ENV_VARS, and relative fallbacks."""
        def _expand(p_str: str) -> Path:
            expanded = os.path.expanduser(os.path.expandvars(p_str.strip()))
            p = Path(expanded)
            if not p.is_absolute():
                p = (self.workspace_root / p).resolve()
            return p

        primary = _expand(raw_path)
        if primary.exists():
            return primary
            
        if fallbacks:
            for fb in fallbacks:
                fb_path = _expand(fb)
                if fb_path.exists():
                    return fb_path
                    
        return primary

    def get_canonical_source(self) -> Path:
        """Resolves the canonical GDTest addon directory."""
        canonical_fallbacks = self.raw_data.get("canonical_source_fallbacks", [
            "./addons/gdtest",
            "addons/gdtest"
        ])
        resolved = self.resolve_raw_path(self.canonical_source_str, canonical_fallbacks)
        if not resolved.exists():
            return ADDON_SOURCE.resolve()
        return resolved.resolve()

    def get_project_info(self, identifier: str) -> Optional[Tuple[str, Path, Dict[str, Any]]]:
        """Looks up project by name or filesystem path."""
        id_lower = identifier.lower().strip()
        for name, config in self.projects_dict.items():
            if name.lower() == id_lower:
                raw_path = config if isinstance(config, str) else config.get("path", name)
                fallbacks = [] if isinstance(config, str) else config.get("fallbacks", [])
                resolved_path = self.resolve_raw_path(raw_path, fallbacks)
                cfg_dict = {"path": str(resolved_path)} if isinstance(config, str) else config
                return (name, resolved_path, cfg_dict)

        direct_path = self.resolve_raw_path(identifier)
        if direct_path.exists():
            return (direct_path.name, direct_path, {"path": str(direct_path)})

        return None

    def get_all_projects(self) -> List[Tuple[str, Path, Dict[str, Any]]]:
        """Returns all registered projects resolved to filesystem paths."""
        results = []
        for name, config in self.projects_dict.items():
            raw_path = config if isinstance(config, str) else config.get("path", name)
            fallbacks = [] if isinstance(config, str) else config.get("fallbacks", [])
            resolved_path = self.resolve_raw_path(raw_path, fallbacks)
            cfg_dict = {"path": str(resolved_path)} if isinstance(config, str) else config
            results.append((name, resolved_path, cfg_dict))
        return results


# ==============================================================================
# RUNNER FIXER ENGINE (3-FRAME GRACEFUL SHUTDOWN PROTOCOL)
# ==============================================================================

def fix_runner_code(content: str) -> Tuple[str, bool, str]:
    """
    Inspects GDScript test runner code, detects inheritance (SceneTree vs Node),
    injects 3-frame graceful shutdown protocol, and replaces raw quit calls.
    Returns (modified_content, was_modified, base_type).
    """
    original = content
    is_scene_tree = bool(re.search(r'extends\s+SceneTree', content))
    is_node = bool(re.search(r'extends\s+Node', content))
    
    if not is_scene_tree and not is_node:
        if re.search(r'(?<!get_tree\(\)\.)\bquit\(', content):
            is_scene_tree = True
            base_type = "SceneTree (inferred)"
        else:
            is_node = True
            base_type = "Node (inferred)"
    elif is_scene_tree:
        base_type = "SceneTree"
    else:
        base_type = "Node"

    if is_scene_tree:
        standard_func = (
            "func _graceful_exit(exit_code: int) -> void:\n"
            "\tfor _i in range(3):\n"
            "\t\tawait process_frame\n"
            "\t\tawait physics_frame\n"
            "\tawait process_frame\n"
            "\tquit(exit_code)\n"
        )
    else:
        standard_func = (
            "func _graceful_exit(exit_code: int) -> void:\n"
            "\tif get_tree():\n"
            "\t\tfor _i in range(3):\n"
            "\t\t\tawait get_tree().process_frame\n"
            "\t\t\tawait get_tree().physics_frame\n"
            "\t\tawait get_tree().process_frame\n"
            "\t\tget_tree().quit(exit_code)\n"
        )

    # 1. Update existing _graceful_exit definition if outdated
    has_graceful = bool(re.search(r'func\s+_graceful_exit\s*\(', content))
    if has_graceful:
        pattern = r'func\s+_graceful_exit\s*\([^)]*\)\s*(?:->\s*void)?\s*:\n(?:(?:\t|[ ]{4})[^\n]*\n)+'
        if re.search(pattern, content):
            content = re.sub(pattern, standard_func, content)

    # 2. Replace naked quit(...) or get_tree().quit(...) outside _graceful_exit
    lines = content.splitlines(keepends=True)
    new_lines = []
    in_graceful_def = False
    
    for line in lines:
        stripped = line.strip()
        if re.match(r'func\s+(_graceful_exit|_graceful_shutdown)\s*\(', stripped):
            in_graceful_def = True
            new_lines.append(line)
            continue
        elif in_graceful_def:
            if stripped.startswith("func ") or (stripped and not line.startswith("\t") and not line.startswith("    ")):
                in_graceful_def = False
            else:
                new_lines.append(line)
                continue

        if is_scene_tree:
            mod_line = re.sub(r'(?<!await\s)(?<!_graceful_exit\()(?<!\.)\bquit\(([^)]*)\)', r'await _graceful_exit(\1)', line)
            mod_line = re.sub(r'await\s+await\s+_graceful_exit', r'await _graceful_exit', mod_line)
            new_lines.append(mod_line)
        else:
            mod_line = re.sub(r'(?<!await\s)(?<!_graceful_exit\()get_tree\(\)\.quit\(([^)]*)\)', r'await _graceful_exit(\1)', line)
            mod_line = re.sub(r'await\s+await\s+_graceful_exit', r'await _graceful_exit', mod_line)
            new_lines.append(mod_line)

    content = "".join(new_lines)

    # 3. Inject _graceful_exit if not present
    if not re.search(r'func\s+_graceful_exit\s*\(', content):
        match_init = re.search(r'func\s+_init\s*\([^)]*\)\s*(?:->\s*\w+)?\s*:\n(?:(?:\t|[ ]{4})[^\n]*\n|\s*\n)*', content)
        if match_init:
            idx = match_init.end()
            content = content[:idx] + "\n" + standard_func + "\n" + content[idx:]
        else:
            match_func = re.search(r'^(?:static\s+)?func\s+', content, re.MULTILINE)
            if match_func:
                idx = match_func.start()
                content = content[:idx] + standard_func + "\n" + content[idx:]
            else:
                content = content + "\n\n" + standard_func

    modified = (content != original)
    return content, modified, base_type


def fix_runner_file(file_path: Path, dry_run: bool = False) -> Dict[str, Any]:
    """Fixes a single runner file on disk with .bak backup."""
    if not file_path.exists():
        return {"path": file_path, "status": "not_found", "modified": False}

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        return {"path": file_path, "status": f"read_error: {e}", "modified": False}

    new_content, modified, base_type = fix_runner_code(content)
    
    if not modified:
        return {"path": file_path, "status": "already_compliant", "base_type": base_type, "modified": False}

    bak_path = file_path.with_name(file_path.name + ".bak")
    if not dry_run:
        bak_path.write_text(content, encoding="utf-8")
        file_path.write_text(new_content, encoding="utf-8")

    return {
        "path": file_path,
        "status": "updated" if not dry_run else "would_update",
        "base_type": base_type,
        "modified": True,
        "backup": bak_path if not dry_run else None,
        "dry_run": dry_run
    }


def fix_project_runners(project_path: Path, explicit_runners: Optional[List[str]] = None, dry_run: bool = False) -> List[Dict[str, Any]]:
    """Discovers and fixes all runner scripts in a project."""
    candidate_paths: List[Path] = []

    if explicit_runners:
        for rel in explicit_runners:
            p = project_path / rel
            if p.exists() and p not in candidate_paths:
                candidate_paths.append(p)

    # Search for additional runners in project (excluding addons/)
    for p in project_path.rglob("*.gd"):
        if "addons/gdtest" in str(p):
            continue
        filename = p.name.lower()
        if "runner" in filename or filename.startswith("run_"):
            if p not in candidate_paths:
                candidate_paths.append(p)
        elif p.parent.name == "tests" or p.parent.name == "integration" or p.parent.name == "audit":
            try:
                txt = p.read_text(encoding="utf-8")
                if "extends SceneTree" in txt and ("quit(" in txt or "_run" in txt):
                    if p not in candidate_paths:
                        candidate_paths.append(p)
            except Exception:
                pass

    results = []
    for p in candidate_paths:
        res = fix_runner_file(p, dry_run=dry_run)
        results.append(res)

    return results


# ==============================================================================
# GIT SAFETY & EXCLUDE HELPERS
# ==============================================================================

def check_git_dirty(project_path: Path, subpath: str = "addons/gdtest") -> Tuple[bool, str]:
    """Checks if subpath in git repo has uncommitted modifications."""
    git_dir = project_path / ".git"
    if not git_dir.exists() and not (project_path / ".gitmodules").exists():
        return False, ""
        
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain", subpath],
            cwd=project_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5
        )
        output = proc.stdout.strip()
        return (len(output) > 0), output
    except Exception:
        return False, ""


def ensure_git_exclude(project_path: Path, pattern: str = "addons/gdtest", dry_run: bool = False) -> bool:
    """Ensures pattern is present in .git/info/exclude so symlinked addons don't pollute git."""
    git_dir = project_path / ".git"
    if not git_dir.exists():
        return False

    info_dir = git_dir / "info" if git_dir.is_dir() else None
    if not info_dir:
        try:
            res = subprocess.run(
                ["git", "rev-parse", "--git-path", "info/exclude"],
                cwd=project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            exclude_path = Path(res.stdout.strip())
            if not exclude_path.is_absolute():
                exclude_path = project_path / exclude_path
        except Exception:
            return False
    else:
        exclude_path = info_dir / "exclude"

    try:
        exclude_path.parent.mkdir(parents=True, exist_ok=True)
        current_content = exclude_path.read_text(encoding="utf-8") if exclude_path.exists() else ""
        lines = [l.strip() for l in current_content.splitlines()]
        
        normalized_pattern = pattern.rstrip("/")
        if normalized_pattern not in lines and f"{normalized_pattern}/" not in lines:
            if not dry_run:
                with open(exclude_path, "a", encoding="utf-8") as f:
                    if current_content and not current_content.endswith("\n"):
                        f.write("\n")
                    f.write(f"\n# GDTest canonical symlink exclusion\n{pattern}\n")
            return True
    except Exception as e:
        print(f"  {COLOR_YELLOW}⚠️  Could not update .git/info/exclude: {e}{COLOR_RESET}")
        
    return False


# ==============================================================================
# SYNCHRONIZATION ENGINE
# ==============================================================================

def sync_project(
    project_name: str,
    project_path: Path,
    canonical_source: Path,
    mode: str = "copy",
    fix_runners: bool = False,
    dry_run: bool = False,
    force: bool = False,
    config: Optional[Dict[str, Any]] = None
) -> bool:
    """Synchronizes GDTest framework to a single project."""
    print(f"\n{COLOR_CYAN}{COLOR_BOLD}▶ Syncing Project: {project_name}{COLOR_RESET} ({project_path})")
    
    if not project_path.exists():
        print(f"  {COLOR_RED}❌ Error: Project path does not exist: {project_path}{COLOR_RESET}")
        return False

    if not canonical_source.exists():
        print(f"  {COLOR_RED}❌ Error: Canonical GDTest source not found: {canonical_source}{COLOR_RESET}")
        return False

    target_addon = project_path / "addons" / "gdtest"
    target_addon_parent = target_addon.parent

    # 1. Dirty Git check (unless --force)
    if not force:
        is_dirty, dirty_output = check_git_dirty(project_path, "addons/gdtest")
        if is_dirty:
            print(f"  {COLOR_RED}❌ Uncommitted git changes detected in {target_addon}:{COLOR_RESET}")
            for line in dirty_output.splitlines()[:5]:
                print(f"    {line}")
            print(f"  {COLOR_YELLOW}Use --force to bypass this safety check or commit your changes.{COLOR_RESET}")
            return False

    # 2. Execute Sync Mode
    if mode == "link":
        print(f"  {COLOR_BLUE}🔗 Mode: Symbolic Link (Live Canonical Mirror){COLOR_RESET}")
        if target_addon.is_symlink():
            current_target = target_addon.resolve()
            if current_target == canonical_source.resolve():
                print(f"  {COLOR_GREEN}✓ Already symlinked to canonical source.{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would re-link {target_addon} -> {canonical_source}{COLOR_RESET}")
                else:
                    target_addon.unlink()
                    os.symlink(canonical_source.resolve(), target_addon, target_is_directory=True)
                    print(f"  {COLOR_GREEN}✓ Updated symlink -> {canonical_source}{COLOR_RESET}")
        else:
            if target_addon.exists():
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would replace concrete directory {target_addon} with symlink -> {canonical_source}{COLOR_RESET}")
                else:
                    shutil.rmtree(target_addon)
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    try:
                        os.symlink(canonical_source.resolve(), target_addon, target_is_directory=True)
                    except OSError:
                        subprocess.run(["cmd", "/c", "mklink", "/J", str(target_addon), str(canonical_source)], check=True)
                    print(f"  {COLOR_GREEN}✓ Replaced concrete directory with symlink -> {canonical_source}{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would create symlink {target_addon} -> {canonical_source}{COLOR_RESET}")
                else:
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    try:
                        os.symlink(canonical_source.resolve(), target_addon, target_is_directory=True)
                    except OSError:
                        subprocess.run(["cmd", "/c", "mklink", "/J", str(target_addon), str(canonical_source)], check=True)
                    print(f"  {COLOR_GREEN}✓ Created symlink -> {canonical_source}{COLOR_RESET}")

        # Ensure .git/info/exclude safety
        excluded = ensure_git_exclude(project_path, "addons/gdtest", dry_run=dry_run)
        if excluded:
            tag = "[DRY-RUN] Would add" if dry_run else "Added"
            print(f"  {COLOR_GREEN}✓ {tag} 'addons/gdtest' to .git/info/exclude for safety.{COLOR_RESET}")

    elif mode == "unlink":
        print(f"  {COLOR_BLUE}🔓 Mode: Unlink (Replace symlink with concrete files){COLOR_RESET}")
        if target_addon.is_symlink():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would remove symlink at {target_addon} and copy concrete canonical files.{COLOR_RESET}")
            else:
                target_addon.unlink()
                shutil.copytree(canonical_source, target_addon)
                print(f"  {COLOR_GREEN}✓ Removed symlink and wrote concrete canonical files.{COLOR_RESET}")
        else:
            if target_addon.exists():
                print(f"  {COLOR_GREEN}✓ addons/gdtest is already a concrete directory.{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would copy canonical files to {target_addon}{COLOR_RESET}")
                else:
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    shutil.copytree(canonical_source, target_addon)
                    print(f"  {COLOR_GREEN}✓ Copied canonical files to {target_addon}{COLOR_RESET}")

    elif mode == "git":
        print(f"  {COLOR_BLUE}📦 Mode: Git Submodule Update{COLOR_RESET}")
        if dry_run:
            print(f"  {COLOR_MAGENTA}[DRY-RUN] Would execute: git submodule update --init --remote --merge addons/gdtest in {project_path}{COLOR_RESET}")
        else:
            try:
                cmd = ["git", "submodule", "update", "--init", "--remote", "--merge", "addons/gdtest"]
                proc = subprocess.run(cmd, cwd=project_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if proc.returncode == 0:
                    print(f"  {COLOR_GREEN}✓ Submodule update succeeded.{COLOR_RESET}")
                    if proc.stdout.strip():
                        print(f"    {proc.stdout.strip()}")
                else:
                    cmd_fallback = ["git", "submodule", "update", "--init", "--recursive", "addons/gdtest"]
                    proc2 = subprocess.run(cmd_fallback, cwd=project_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if proc2.returncode == 0:
                        print(f"  {COLOR_GREEN}✓ Submodule update (--recursive) succeeded.{COLOR_RESET}")
                    else:
                        print(f"  {COLOR_RED}❌ Submodule update failed: {proc.stderr.strip()}{COLOR_RESET}")
            except Exception as e:
                print(f"  {COLOR_RED}❌ Submodule execution error: {e}{COLOR_RESET}")

    else: # Default: copy
        print(f"  {COLOR_BLUE}📁 Mode: Copy / Mirror (Concrete Files){COLOR_RESET}")
        if target_addon.is_symlink():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would remove symlink at {target_addon} and copy canonical files.{COLOR_RESET}")
            else:
                target_addon.unlink()
                shutil.copytree(canonical_source, target_addon)
                print(f"  {COLOR_GREEN}✓ Removed symlink and copied canonical files.{COLOR_RESET}")
        elif target_addon.exists():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would mirror canonical files from {canonical_source} to {target_addon}{COLOR_RESET}")
            else:
                shutil.copytree(canonical_source, target_addon, dirs_exist_ok=True)
                print(f"  {COLOR_GREEN}✓ Mirrored canonical files to {target_addon}{COLOR_RESET}")
        else:
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would copy canonical files to {target_addon}{COLOR_RESET}")
            else:
                target_addon_parent.mkdir(parents=True, exist_ok=True)
                shutil.copytree(canonical_source, target_addon)
                print(f"  {COLOR_GREEN}✓ Copied canonical files to {target_addon}{COLOR_RESET}")

    # 3. Runner Fixer Protocol
    if fix_runners:
        print(f"  {COLOR_CYAN}🛠️  Inspecting & Updating Test Runner Scripts...{COLOR_RESET}")
        explicit_runners = config.get("runners", []) if config else []
        fix_results = fix_project_runners(project_path, explicit_runners=explicit_runners, dry_run=dry_run)
        
        if not fix_results:
            print(f"    {COLOR_YELLOW}No test runner scripts discovered.{COLOR_RESET}")
        else:
            for r in fix_results:
                rel_path = r["path"].relative_to(project_path) if r["path"].is_relative_to(project_path) else r["path"]
                if r["modified"]:
                    if dry_run:
                        print(f"    {COLOR_MAGENTA}[DRY-RUN] Would inject 3-frame graceful exit into {rel_path} ({r.get('base_type')}){COLOR_RESET}")
                    else:
                        print(f"    {COLOR_GREEN}✓ Updated {rel_path} with 3-frame graceful exit ({r.get('base_type')}) [backup: {r['backup'].name}]{COLOR_RESET}")
                elif r["status"] == "already_compliant":
                    print(f"    {COLOR_GREEN}✓ {rel_path} is already compliant ({r.get('base_type')}){COLOR_RESET}")
                else:
                    print(f"    {COLOR_YELLOW}• {rel_path}: {r['status']}{COLOR_RESET}")

    return True


def run_sync_subcommand(args: argparse.Namespace) -> int:
    """CLI handler for the 'sync' subcommand."""
    registry = ProjectRegistry()
    canonical_source = registry.get_canonical_source()

    print(f"\n{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}🔄 GDTEST UNIVERSAL SYNCHRONIZATION ENGINE{COLOR_RESET}")
    print(f"  Canonical Source: {canonical_source}")
    if args.dry_run:
        print(f"  {COLOR_MAGENTA}Execution Mode:   DRY-RUN (Preview Only){COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")

    if args.link:
        mode = "link"
    elif args.unlink:
        mode = "unlink"
    elif args.git:
        mode = "git"
    else:
        mode = "copy"

    targets = []
    projects_input = getattr(args, "projects", [])
    if isinstance(projects_input, str):
        projects_input = [projects_input]
    elif not projects_input and getattr(args, "project", None):
        projects_input = [args.project]
        
    if args.all or not projects_input or "all" in [p.lower() for p in projects_input]:
        if not projects_input and not args.all:
            print(f"\n{COLOR_YELLOW}No project specified. Syncing ALL registered projects (--all)...{COLOR_RESET}")
        targets = registry.get_all_projects()
    else:
        for proj_id in projects_input:
            proj_lower = proj_id.lower()
            if proj_lower == "workspace":
                ws_names = ["showcase_mega", "showcase_2d", "showcase_3d", "demo_2d", "demo_3d"]
                for p_name, p_path, cfg in registry.get_all_projects():
                    if p_name in ws_names and (p_name, p_path, cfg) not in targets:
                        targets.append((p_name, p_path, cfg))
            elif proj_lower == "external":
                ext_names = ["material3", "guildmaster"]
                for p_name, p_path, cfg in registry.get_all_projects():
                    if p_name in ext_names and (p_name, p_path, cfg) not in targets:
                        targets.append((p_name, p_path, cfg))
            elif proj_lower in ["packages", "package"]:
                for p_name, p_path, cfg in registry.get_all_projects():
                    if p_name == "packages" and (p_name, p_path, cfg) not in targets:
                        targets.append((p_name, p_path, cfg))
            else:
                matched = registry.get_project_info(proj_id)
                if matched:
                    if matched not in targets:
                        targets.append(matched)
                else:
                    print(f"\n{COLOR_RED}❌ Error: Unknown project '{proj_id}'.{COLOR_RESET}")
                    print("\nAvailable registered projects in .gdtest_projects.json:")
                    for p_name, p_path, _ in registry.get_all_projects():
                        print(f"  • {COLOR_BOLD}{p_name}{COLOR_RESET}: {p_path}")
                    return 1

    success_count = 0
    fail_count = 0

    for name, path, cfg in targets:
        ok = sync_project(
            project_name=name,
            project_path=path,
            canonical_source=canonical_source,
            mode=mode,
            fix_runners=args.fix_runners,
            dry_run=args.dry_run,
            force=args.force,
            config=cfg
        )
        if ok:
            success_count += 1
        else:
            fail_count += 1

    print(f"\n{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")
    print(f"📊 Sync Complete: {COLOR_GREEN}{success_count} Succeeded{COLOR_RESET}, {COLOR_RED if fail_count > 0 else ''}{fail_count} Failed{COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}\n")

    return 0 if fail_count == 0 else 1


# ==============================================================================
# EXISTING FRAMEWORK CLI COMMANDS (INSTALL, GENERATE, RUN, AUDIT)
# ==============================================================================

def install_framework(target_project: str) -> None:
    """Install the GDTest framework addon and initialize directory structure."""
    registry = ProjectRegistry()
    canonical_source = registry.get_canonical_source()
    
    proj_path = Path(target_project).resolve()
    if not proj_path.exists():
        raise FileNotFoundError(f"Project directory not found: {proj_path}")
        
    # 1. Copy addon
    dest_addon = proj_path / "addons" / "gdtest"
    dest_addon.parent.mkdir(parents=True, exist_ok=True)
    if dest_addon.exists():
        shutil.rmtree(dest_addon)
    shutil.copytree(canonical_source, dest_addon)
    print(f"✅ Installed GDTest addon to: {dest_addon}")
    
    # 2. Ensure tests and artifacts directories exist
    tests_dir = proj_path / "tests"
    tests_dir.mkdir(parents=True, exist_ok=True)
    
    artifacts_dir = proj_path / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    (artifacts_dir / "checkpoints").mkdir(parents=True, exist_ok=True)
    
    # 3. Create starter test if tests/ is empty
    existing_tests = list(tests_dir.glob("test_*.gd"))
    if not existing_tests:
        sample_test_path = tests_dir / "test_example.gd"
        sample_code = """# test_example.gd
# Sample integration test suite
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Example_Project_Integration_Suite"
	test_type = "integration"

func test_engine_initialization() -> void:
	assert_true(Engine.get_frames_drawn() >= 0, "Engine frame count should be valid")
	assert_eq(typeof(Vector2.ZERO), TYPE_VECTOR2, "Vector2 type must be valid")

func test_physics_simulation() -> void:
	var space = PhysicsServer2D.space_create()
	assert_true(space.is_valid(), "PhysicsServer2D space RID must be valid")
	PhysicsServer2D.free_rid(space)
"""
        sample_test_path.write_text(sample_code, encoding="utf-8")
        print(f"✅ Created starter test: {sample_test_path}")

    print(f"🎉 Successfully initialized GDTest framework in '{proj_path.name}'.")


def generate_test(target_project: str, suite_name: str, test_type: str = "integration") -> Path:
    """Generate a clean boilerplate GDScript test suite tailored for Unit or Integration testing."""
    proj_path = Path(target_project).resolve()
    tests_dir = proj_path / "tests"
    tests_dir.mkdir(parents=True, exist_ok=True)
    
    slug = suite_name.lower().replace(" ", "_").replace("-", "_")
    if not slug.startswith("test_"):
        slug = f"test_{slug}"
    file_path = tests_dir / f"{slug}.gd"
    
    class_title = "".join(part.capitalize() for part in slug.split("_"))
    
    if test_type == "unit":
        code = f"""# {file_path.name}
# Pure Unit Test Suite: Fast deterministic testing of pure functions, math, data structures & signals
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "{class_title}_Suite"
	test_type = "unit"

func test_pure_logic_and_math() -> void:
	var v1 = Vector3(1, 2, 3)
	var v2 = Vector3(4, 5, 6)
	assert_eq(v1 + v2, Vector3(5, 7, 9), "Vector addition must be exact")
	assert_approx(v1.length(), 3.74165, 0.001, "Vector length must match formula")

func test_signal_spy_observation() -> void:
	var emitter = autofree(Node.new())
	emitter.add_user_signal("status_updated", [{{"name": "status", "type": TYPE_STRING}}])
	
	watch_signal(emitter, &"status_updated")
	assert_signal_not_emitted(emitter, &"status_updated")
	
	emitter.emit_signal("status_updated", "ready")
	assert_signal_emitted(emitter, &"status_updated")
	assert_signal_count(emitter, &"status_updated", 1)
"""
    else: # integration
        code = f"""# {file_path.name}
# Deterministic Integration Test Suite: Physics, Input Simulation & Multi-Node Coordination
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "{class_title}_Integration_Suite"
	test_type = "integration"

func test_simulated_input_and_physics() -> void:
	var body = autofree(RigidBody2D.new())
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	body.add_child(shape)
	add_child(body)
	body.position = Vector2(200, 100)
	
	var initial_y = body.position.y
	await step_physics_frames(10)
	assert_true(body.position.y >= initial_y, "RigidBody2D must descend or stay within physics bounds")
"""
    file_path.write_text(code, encoding="utf-8")
    print(f"✅ Generated {test_type.upper()} test suite: {file_path}")
    return file_path


def build_remote_debugger_close_packet() -> bytes:
    """
    Build the 3-element Godot 4 RemoteDebugger TCP wire packet:
      [String("embed:win_event"), Int(1), Array([Int(4)])]
    where:
      - "embed:win_event" dispatches to EmbeddedDebugger::_msg_win_event
      - 1 is Thread::MAIN_ID
      - 4 is DisplayServer.WINDOW_EVENT_CLOSE_REQUEST, which triggers
        Window::_event_callback -> root.close_requested -> SceneTree::_main_window_close
        -> SceneTree::quit(0) -> Main::cleanup() with exit code 0 and zero macOS crash dialogs.
    """
    msg_name = b"embed:win_event"
    pad = (4 - (len(msg_name) % 4)) % 4
    payload = struct.pack("<II", 28, 3)  # Variant::ARRAY (28), length 3
    payload += struct.pack("<II", 4, len(msg_name)) + msg_name + (b"\x00" * pad)
    payload += struct.pack("<Ii", 2, 1)  # Variant::INT (2), Thread::MAIN_ID = 1
    payload += struct.pack("<II", 28, 1)  # Variant::ARRAY (28), length 1
    payload += struct.pack("<Ii", 2, 4)  # Variant::INT (2), WINDOW_EVENT_CLOSE_REQUEST = 4
    return struct.pack("<I", len(payload)) + payload


class MacOSEmbeddedDebugSession:
    """
    Manages a local TCP listener for Godot 4's `--embedded --display-driver embedded`
    mode on macOS so GPU-accelerated Forward+/Metal rendering and Viewport screenshot
    captures run in a windowless CAContext/CAMetalLayer (UIElement process policy)
    without ever creating an NSWindow, stealing focus, switching macOS Full Screen
    Spaces, or triggering macOS 'Godot quit unexpectedly' dialogs.
    """

    def __init__(self) -> None:
        self.server: Optional[socket.socket] = None
        self.conn: Optional[socket.socket] = None
        self.port: int = 0
        self._accept_thread: Optional[threading.Thread] = None
        self._closed = threading.Event()

    def start(self) -> int:
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind(("127.0.0.1", 0))
        self.port = int(self.server.getsockname()[1])
        self.server.listen(1)
        self.server.settimeout(1.0)
        self._accept_thread = threading.Thread(target=self._accept_and_drain, daemon=True)
        self._accept_thread.start()
        return self.port

    def _accept_and_drain(self) -> None:
        if not self.server:
            return
        while not self._closed.is_set():
            try:
                conn, _ = self.server.accept()
                self.conn = conn
                break
            except socket.timeout:
                continue
            except OSError:
                return
        if self.conn:
            try:
                while not self._closed.is_set():
                    data = self.conn.recv(4096)
                    if not data:
                        break
            except OSError:
                pass

    def cli_args(self, resolution: str = "1280x720") -> List[str]:
        if not self.port:
            self.start()
        return [
            "--embedded",
            "--display-driver", "embedded",
            "--remote-debug", f"tcp://127.0.0.1:{self.port}",
            "--disable-crash-handler",
            "--audio-driver", "Dummy",
            "--resolution", resolution,
        ]

    def request_graceful_close(self, process: subprocess.Popen, grace_timeout: float = 5.0) -> int:
        """
        Send `embed:win_event` (`WINDOW_EVENT_CLOSE_REQUEST = 4`) over the RemoteDebugger
        socket so Godot executes `Main::cleanup()` and exits with code 0.
        """
        if process.poll() is not None:
            return int(process.returncode)
        if self.conn is not None:
            try:
                self.conn.sendall(build_remote_debugger_close_packet())
            except OSError:
                pass
        try:
            return int(process.wait(timeout=grace_timeout))
        except subprocess.TimeoutExpired:
            process.kill()
            return int(process.wait(timeout=2.0))

    def close(self) -> None:
        self._closed.set()
        if self.conn is not None:
            try:
                self.conn.close()
            except OSError:
                pass
            self.conn = None
        if self.server is not None:
            try:
                self.server.close()
            except OSError:
                pass
            self.server = None


def run_tests(
    target_project: str,
    suite_filter: str = "",
    test_filter: str = "",
    test_type: str = "",
    headless: bool = True,
    timeout_sec: int = 60,
    visible_window: bool = False,
) -> int:
    """Execute integration tests on the target Godot project."""
    godot_bin = find_godot_binary()
    registry = ProjectRegistry()
    matched = registry.get_project_info(target_project)
    proj_path = matched[1] if matched else Path(target_project).resolve()
    
    dest_addon = proj_path / "addons" / "gdtest"
    if not dest_addon.exists():
        print("GDTest addon not found in project. Auto-installing...")
        install_framework(str(proj_path))
        
    artifacts_dir = proj_path / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    engine_log = artifacts_dir / "engine.log"
    
    cmd = [
        godot_bin,
        "--path", str(proj_path),
    ]
    
    embedded_session: Optional[MacOSEmbeddedDebugSession] = None
    if headless:
        cmd.extend(["--headless", "--audio-driver", "Dummy"])
    elif sys.platform == "darwin" and not visible_window:
        embedded_session = MacOSEmbeddedDebugSession()
        cmd.extend(embedded_session.cli_args("1280x720"))
    else:
        cmd.extend(["--resolution", "1280x720"])

    cmd.append("res://addons/gdtest/core/test_runner_scene.tscn")
        
    user_args = []
    if suite_filter:
        user_args.append(f"--suite={suite_filter}")
    if test_filter:
        user_args.append(f"--test={test_filter}")
    if test_type:
        user_args.append(f"--type={test_type}")
        
    if user_args:
        cmd.append("--")
        cmd.extend(user_args)
        
    print(f"▶ Executing: {' '.join(cmd)}")
    start_time = time.time()
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        collected_lines = []
        for line in iter(process.stdout.readline, ''):
            if line:
                print(f"  {line.strip()}")
                collected_lines.append(line)
                
        exit_code = process.wait(timeout=timeout_sec)
        try:
            with open(engine_log, "w", encoding="utf-8") as f:
                f.writelines(collected_lines)
        except Exception:
            pass
    except subprocess.TimeoutExpired:
        if embedded_session is not None:
            embedded_session.request_graceful_close(process, grace_timeout=5.0)
        else:
            process.kill()
        print(f"❌ Test run timed out after {timeout_sec} seconds!")
        return 1
    finally:
        if embedded_session is not None:
            embedded_session.close()
        
    duration = time.time() - start_time
    print(f"\nExecution finished in {duration:.2f}s with exit code {exit_code}")
    return exit_code


def main():
    parser = argparse.ArgumentParser(description="Universal Godot Test & Synchronization CLI Orchestrator")
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    # sync command
    sync_parser = subparsers.add_parser("sync", help="Synchronize GDTest framework to registered projects")
    sync_parser.add_argument("projects", nargs="*", default=[], help="Target project identifier(s), presets ('workspace', 'external', 'packages', 'all'), or directory paths")
    sync_parser.add_argument("--all", action="store_true", help="Sync all registered projects")
    
    mode_group = sync_parser.add_mutually_exclusive_group()
    mode_group.add_argument("--copy", action="store_true", default=False, help="Fast file copy/mirror from canonical source (default)")
    mode_group.add_argument("--link", action="store_true", help="Cross-platform symbolic link with .git/info/exclude safety")
    mode_group.add_argument("--unlink", action="store_true", help="Replaces symlink with clean concrete file copy")
    mode_group.add_argument("--git", action="store_true", help="Executes git submodule update in target git repo")
    
    sync_parser.add_argument("--fix-runners", action="store_true", help="Inspect and update test runner scripts with the 3-frame graceful shutdown protocol")
    sync_parser.add_argument("--dry-run", action="store_true", help="Preview synchronization and runner updates without modifying disk")
    sync_parser.add_argument("--force", action="store_true", help="Bypass dirty git / uncommitted edits warnings")
    
    # install command
    install_parser = subparsers.add_parser("install", help="Install GDTest framework to a Godot project")
    install_parser.add_argument("project", help="Path to target Godot project directory")
    
    # generate command
    gen_parser = subparsers.add_parser("generate", help="Generate a new GDScript test suite")
    gen_parser.add_argument("project", help="Path to target Godot project directory")
    gen_parser.add_argument("suite", help="Name of the test suite (e.g. 'player_movement')")
    gen_parser.add_argument("--type", choices=["unit", "integration"], default="integration", help="Type of test suite")
    
    # run command
    run_parser = subparsers.add_parser("run", help="Run integration tests on a Godot project")
    run_parser.add_argument("project", help="Path to target Godot project directory")
    run_parser.add_argument("--suite", default="", help="Filter by test suite name")
    run_parser.add_argument("--test", default="", help="Filter by test method name")
    run_parser.add_argument("--type", "--tier", dest="test_type", default="", help="Filter by test type/tier ('unit', 'integration')")
    run_parser.add_argument("--windowed", "--embedded", dest="windowed", action="store_true", help="Run with GPU rendering (uses windowless Metal embedded mode on macOS to prevent Full Screen Space switches)")
    run_parser.add_argument("--visible-window", action="store_true", help="Force a visible OS window when running with --windowed")
    run_parser.add_argument("--timeout", type=int, default=60, help="Test timeout in seconds")
    
    args = parser.parse_args()
    
    if args.command == "sync":
        code = run_sync_subcommand(args)
        sys.exit(code)
    elif args.command == "install":
        install_framework(args.project)
        sys.exit(0)
    elif args.command == "generate":
        generate_test(args.project, args.suite, test_type=args.type)
        sys.exit(0)
    elif args.command == "run":
        code = run_tests(
            args.project,
            suite_filter=args.suite,
            test_filter=args.test,
            test_type=args.test_type,
            headless=(not args.windowed),
            timeout_sec=args.timeout,
            visible_window=args.visible_window,
        )
        sys.exit(code)


if __name__ == "__main__":
    main()
