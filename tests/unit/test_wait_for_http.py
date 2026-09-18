import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_wait_for_http_retries_until_status_200(tmp_path):
    attempts_file = tmp_path / "attempts"
    attempts_file.write_text("0")
    curl = tmp_path / "curl"
    curl.write_text(
        "#!/usr/bin/env bash\n"
        f"attempts_file={attempts_file!s}\n"
        'attempts=$(<"$attempts_file")\n'
        'attempts=$((attempts + 1))\n'
        'printf "%s" "$attempts" > "$attempts_file"\n'
        'if (( attempts < 3 )); then printf "503"; else printf "200"; fi\n'
    )
    curl.chmod(0o755)

    result = subprocess.run(
        [
            "bash",
            "-c",
            (
                "source scripts/lib/http.sh && "
                "wait_for_http http://127.0.0.1:8000/health test 5 0"
            ),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        env={"PATH": f"{tmp_path}:/usr/bin:/bin"},
    )

    assert result.returncode == 0, result.stderr
    assert attempts_file.read_text() == "3"
    assert "curl:" not in result.stderr
