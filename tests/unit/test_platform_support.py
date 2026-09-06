"""The declared platforms, the Molecule matrix and the support policy agree.

meta/platform_support.yml is the source of truth. These tests fail when a
supported release leaves full vendor support, when meta/main.yml drifts from
the policy, or when a supported release is not exercised by a Molecule
scenario. Extended phases (Ubuntu ESM, Debian LTS, EL Maintenance Support) do
not count as supported.
"""

from __future__ import annotations

import datetime
import os
import pathlib
import re
import warnings

import pytest
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]
POLICY = ROOT / "meta" / "platform_support.yml"
META = ROOT / "meta" / "main.yml"
MOLECULE = sorted((ROOT / "molecule").glob("*/molecule.yml"))


def _load(path: pathlib.Path) -> dict:
    return yaml.safe_load(path.read_text())


@pytest.fixture(scope="module")
def distributions() -> list[dict]:
    return _load(POLICY)["distributions"]


@pytest.fixture(scope="module")
def supported(distributions: list[dict]) -> list[dict]:
    return [d for d in distributions if d["supported"]]


@pytest.fixture(scope="module")
def molecule_images() -> set[str]:
    images = set()
    for path in MOLECULE:
        for platform in _load(path).get("platforms") or []:
            images.add(platform["image"].split("@", 1)[0])
    return images


def test_the_corpus_is_not_empty(distributions: list[dict]) -> None:
    """A moved directory must fail loudly, not pass on zero inputs."""
    assert MOLECULE, "no molecule.yml files found; the layout changed"
    assert distributions, "the support policy is empty"


def test_every_policy_support_date_is_valid(distributions: list[dict]) -> None:
    invalid = []
    for distribution in distributions:
        try:
            datetime.date.fromisoformat(distribution["full_support_ends"])
        except (KeyError, TypeError, ValueError):
            invalid.append(
                f"{distribution.get('meta_name')} {distribution.get('meta_version')}"
            )
    assert not invalid, f"invalid or missing full-support dates: {invalid}"


def _reference_date() -> datetime.date:
    """UTC today, overridable so the check is reproducible on any checkout."""
    override = os.environ.get("PLATFORM_SUPPORT_DATE")
    if override:
        if os.environ.get("CI"):
            raise AssertionError("PLATFORM_SUPPORT_DATE cannot override the support gate in CI")
        warnings.warn(
            f"PLATFORM_SUPPORT_DATE={override} overrides the end-of-life check; "
            "this is for reproducing an old checkout, not for silencing CI",
            stacklevel=2,
        )
        return datetime.date.fromisoformat(override)
    return datetime.datetime.now(datetime.timezone.utc).date()


def test_every_supported_release_still_has_full_vendor_support(
    supported: list[dict],
) -> None:
    """Extended phases do not count: ESM, Debian LTS and EL Maintenance are out."""
    today = _reference_date()
    lapsed = [
        f"{d['meta_name']} {d['meta_version']} (full support ended {d['full_support_ends']})"
        for d in supported
        if datetime.date.fromisoformat(d["full_support_ends"]) <= today
    ]
    assert not lapsed, (
        f"these are supported here but no longer fully supported upstream: {lapsed}"
    )


def test_meta_declares_exactly_the_supported_releases(supported: list[dict]) -> None:
    declared = {
        (platform["name"], str(version))
        for platform in _load(META)["galaxy_info"]["platforms"]
        for version in platform["versions"]
    }
    expected = {(d["meta_name"], str(d["meta_version"])) for d in supported}
    assert declared == expected


def test_meta_declares_the_documented_ansible_floor() -> None:
    requirements = (ROOT / "requirements.txt").read_text()
    match = re.search(r"^ansible-core>=(\d+\.\d+)", requirements, re.MULTILINE)
    assert match, "requirements.txt does not declare an ansible-core lower bound"
    assert _load(META)["galaxy_info"]["min_ansible_version"] == match.group(1)


def test_molecule_runs_only_supported_images(
    distributions: list[dict], molecule_images: set[str]
) -> None:
    allowed = {d["image"] for d in distributions if d["supported"]}
    known = {d["image"]: d for d in distributions}
    offenders = {
        f"{image} ({known[image]['meta_name']} {known[image]['meta_version']})"
        if image in known
        else f"{image} (absent from the policy)"
        for image in molecule_images - allowed
    }
    assert not offenders, f"Molecule runs unsupported images: {sorted(offenders)}"


def test_every_supported_release_is_exercised(
    supported: list[dict], molecule_images: set[str]
) -> None:
    missing = [
        f"{d['meta_name']} {d['meta_version']} ({d['image']})"
        for d in supported
        if d["image"] not in molecule_images
    ]
    assert not missing, f"supported releases with no Molecule coverage: {missing}"


def test_molecule_images_are_pinned_by_digest() -> None:
    unpinned = [
        f"{path.parent.name}: {platform['image']}"
        for path in MOLECULE
        for platform in _load(path).get("platforms") or []
        if "@sha256:" not in platform["image"]
    ]
    assert not unpinned, f"Molecule images not pinned by digest: {unpinned}"


def test_the_date_override_is_not_baked_into_ci() -> None:
    """The override must not become a permanent way to silence the gate."""
    candidates = [
        *sorted((ROOT / ".github").rglob("*.yml")),
        *sorted((ROOT / ".github").rglob("*.yaml")),
        *[ROOT / name for name in
          ("tox.ini", "Makefile", ".env", "pytest.ini", "setup.cfg", "pyproject.toml",
           "docker-compose.yml", "docker-compose.test.yml", "Dockerfile")],
    ]
    users = sorted({
        str(p.relative_to(ROOT)) for p in candidates
        if p.is_file() and "PLATFORM_SUPPORT_DATE" in p.read_text(encoding="utf-8")
    })
    assert not users, f"PLATFORM_SUPPORT_DATE is set in-tree, disabling the gate: {users}"


def test_the_date_override_is_honoured(monkeypatch) -> None:
    monkeypatch.delenv("CI", raising=False)
    monkeypatch.setenv("PLATFORM_SUPPORT_DATE", "2000-01-01")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        assert _reference_date() == datetime.date(2000, 1, 1)


def test_the_date_override_is_refused_in_ci(monkeypatch) -> None:
    monkeypatch.setenv("PLATFORM_SUPPORT_DATE", "2000-01-01")
    monkeypatch.setenv("CI", "true")
    with pytest.raises(AssertionError, match="cannot override"):
        _reference_date()


def test_reference_date_uses_utc_today_without_an_override(monkeypatch) -> None:
    monkeypatch.delenv("PLATFORM_SUPPORT_DATE", raising=False)
    monkeypatch.delenv("CI", raising=False)
    assert _reference_date() == datetime.datetime.now(datetime.timezone.utc).date()
