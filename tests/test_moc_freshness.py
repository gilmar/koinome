"""MOC freshness must track content, not the calendar.

Regression: gen_mocs.py stamped `created`/`updated` with today's date on every
run and never read existing frontmatter back, so `gen_mocs.py --check` (and thus
`koinome check`) could only pass on the day a corpus was generated. Any corpus
more than one day old failed freshness even though its content was unchanged.
"""

from __future__ import annotations

import re

from tests.helpers import (
    gen_mocs,
    note_with_fm,
    run_conformance_check,
    scaffold_corpus,
    write_note,
)

OLD_DATE = "2020-01-01"


def _backdate_mocs(corpus, date=OLD_DATE):
    """Rewrite every MOC's created/updated to an old date, as a corpus that was
    generated in the past would carry on disk. Returns the files touched."""
    touched = []
    for moc in sorted((corpus / "80-moc").glob("*.md")):
        text = moc.read_text(encoding="utf-8")
        text = re.sub(r"^created: .+$", f"created: {date}", text, count=1, flags=re.M)
        text = re.sub(r"^updated: .+$", f"updated: {date}", text, count=1, flags=re.M)
        moc.write_text(text, encoding="utf-8")
        touched.append(moc)
    return touched


def test_moc_freshness_is_not_a_clock(tmp_path):
    corpus = tmp_path / "corpus"
    scaffold_corpus(corpus)
    write_note(
        corpus,
        "10-projects/alpha.md",
        note_with_fm(
            "Body with concrete nouns for retrieval.",
            title="Alpha note",
            summary="A concrete project note used to populate the projects map of content.",
            type="project-doc",
            status="active",
            domain="projects",
            created="2020-01-01",
            updated="2020-01-01",
        ),
    )
    assert gen_mocs(corpus).returncode == 0

    touched = _backdate_mocs(corpus)
    assert touched, "expected generated MOCs under 80-moc/"

    # A corpus generated in the past must still pass check today.
    result = run_conformance_check(corpus)
    assert result.returncode == 0, result.stdout + result.stderr

    # And the backdated dates must survive a real (non --check) regeneration:
    # created is preserved, and updated is not bumped when the body is unchanged.
    assert gen_mocs(corpus).returncode == 0
    for moc in touched:
        text = moc.read_text(encoding="utf-8")
        assert re.search(rf"^created: {OLD_DATE}$", text, re.M), text
        assert re.search(rf"^updated: {OLD_DATE}$", text, re.M), text
