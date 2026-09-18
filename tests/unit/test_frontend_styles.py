from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_conduit_styles_are_bundled_locally():
    root_source = (ROOT / "frontend/app/root.tsx").read_text()
    app_css = (ROOT / "frontend/app/app.css").read_text()
    conduit_css = ROOT / "frontend/app/conduit.css"

    assert "demo.productionready.io/main.css" not in root_source
    assert '@import "./conduit.css";' in app_css
    assert conduit_css.exists()

    styles = conduit_css.read_text()
    for selector in (".navbar", ".form-control", ".article-page", ".btn-primary"):
        assert selector in styles
