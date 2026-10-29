import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
API = "https://updates.actionclip.app/api/releases/latest"


class UpdateActionClipCaskTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        scripts = self.root / ".github/scripts"
        scripts.mkdir(parents=True)
        self.script = scripts / "update-actionclip-cask.sh"
        shutil.copy2(ROOT / ".github/scripts/update-actionclip-cask.sh", self.script)
        (self.root / "Casks").mkdir()
        self.cask = self.root / "Casks/actionclip.rb"
        self.dmg = self.root / "fixture.dmg"
        self.dmg.write_bytes(b"verified installer fixture")
        self.sha = hashlib.sha256(self.dmg.read_bytes()).hexdigest()
        self.metadata = self.root / "release.json"
        self.requests = self.root / "requests.txt"
        self.url = "https://updates.actionclip.app/releases/2.3.4-649/ActionClip-2.3.4-649.dmg"
        self.release = {
            "channel": "stable",
            "latest": {
                "status": "published",
                "version": "2.3.4",
                "build": 649,
                "assets": [{"kind": "dmg", "url": self.url, "sha256": self.sha}],
            },
        }
        # Match the production cask's CSV version and interpolated immutable URL.
        self.original = re.sub(
            r'^  version "[^"]+"$', '  version "2.3.4,648"',
            (ROOT / "Casks/actionclip.rb").read_text(), flags=re.MULTILINE,
        )
        self.original = re.sub(
            r'^  sha256 "[0-9a-f]+"$', f'  sha256 "{"0" * 64}"',
            self.original, flags=re.MULTILINE,
        )
        self.cask.write_text(self.original)
        commands = self.root / "bin"
        commands.mkdir()
        curl = commands / "curl"
        curl.write_text("""#!/usr/bin/env python3
import os
from pathlib import Path
import shutil
import sys
args = sys.argv[1:]
url = next(value for value in args if value.startswith('https://'))
with open(os.environ['TEST_REQUESTS'], 'a') as log:
    log.write(url + '\\n')
if url == 'https://updates.actionclip.app/api/releases/latest':
    source = os.environ['TEST_METADATA']
elif url == os.environ['TEST_DMG_URL']:
    source = os.environ['TEST_DMG']
else:
    sys.exit('Unexpected download: ' + url)
shutil.copyfile(source, args[args.index('--output') + 1])
""")
        curl.chmod(0o755)
        self.environment = {
            **os.environ,
            "PATH": str(commands) + os.pathsep + os.environ["PATH"],
            "TEST_REQUESTS": str(self.requests),
            "TEST_METADATA": str(self.metadata),
            "TEST_DMG_URL": self.url,
            "TEST_DMG": str(self.dmg),
        }

    def run_updater(self):
        self.metadata.write_text(json.dumps(self.release))
        return subprocess.run(
            ["bash", str(self.script)], env=self.environment,
            capture_output=True, text=True, check=False,
        )

    def assert_rejected(self, expected_error):
        before = self.cask.read_bytes()
        result = self.run_updater()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(expected_error, result.stderr)
        self.assertEqual(self.cask.read_bytes(), before)
        self.assertEqual(self.requests.read_text().splitlines(), [API])

    def test_current_release_is_unchanged_without_downloading_installer(self):
        self.cask.write_text(self.original.replace('version "2.3.4,648"', 'version "2.3.4,649"')
                             .replace("0" * 64, self.sha))
        before = self.cask.read_bytes()
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already current", result.stdout)
        self.assertEqual(self.cask.read_bytes(), before)
        self.assertEqual(self.requests.read_text().splitlines(), [API])

    def test_new_build_of_same_version_updates_csv_version_and_checksum(self):
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        content = self.cask.read_text()
        self.assertIn('version "2.3.4,649"', content)
        self.assertIn(f'sha256 "{self.sha}"', content)
        self.assertIn('#{version.csv.first}-#{version.csv.second}', content)
        self.assertEqual(self.requests.read_text().splitlines(), [API, self.url])

    def test_new_app_version_updates_csv_version(self):
        self.release["latest"].update(version="2.3.5", build=651)
        url = "https://updates.actionclip.app/releases/2.3.5-651/ActionClip-2.3.5-651.dmg"
        self.release["latest"]["assets"][0]["url"] = url
        self.environment["TEST_DMG_URL"] = url
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('version "2.3.5,651"', self.cask.read_text())

    def test_current_version_build_cannot_change_checksum(self):
        self.cask.write_text(self.original.replace('version "2.3.4,648"', 'version "2.3.4,649"'))
        self.assert_rejected("Refusing to update a reused version URL")

    def test_legacy_unqualified_url_is_rejected(self):
        self.release["latest"]["assets"][0]["url"] = (
            "https://updates.actionclip.app/releases/2.3.4/ActionClip-2.3.4.dmg"
        )
        self.assert_rejected("Unexpected DMG URL")

    def test_wrong_build_in_url_is_rejected(self):
        self.release["latest"]["assets"][0]["url"] = self.url.replace("649", "648")
        self.assert_rejected("Unexpected DMG URL")

    def test_other_download_host_is_rejected(self):
        self.release["latest"]["assets"][0]["url"] = self.url.replace("updates.actionclip.app", "example.com")
        self.assert_rejected("Unexpected DMG URL")

    def test_non_stable_channel_is_rejected(self):
        self.release["channel"] = "beta"
        self.assert_rejected("Expected the stable channel")

    def test_unpublished_release_is_rejected(self):
        self.release["latest"]["status"] = "staged"
        self.assert_rejected("Latest stable release is not published")

    def test_download_checksum_mismatch_preserves_cask(self):
        before = self.cask.read_bytes()
        self.dmg.write_bytes(b"corrupted installer")
        result = self.run_updater()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Downloaded DMG checksum does not match", result.stderr)
        self.assertEqual(self.cask.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
