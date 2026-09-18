from conduit.core.utils.slug import (
    get_slug_unique_part,
    make_slug_from_title_and_code,
)


def test_title_and_code_make_a_slug():
    assert make_slug_from_title_and_code("Hello World", "123456") == "hello-world-123456"


def test_punctuation_and_capitals_are_normalized():
    assert make_slug_from_title_and_code("Hello, WORLD!!!", "abc123") == "hello-world-abc123"


def test_long_title_is_cut_before_the_code():
    slug = make_slug_from_title_and_code(
        "This Is A Very Long Article Title That Keeps Going", "abc123"
    )
    title_part = slug.removesuffix("-abc123")
    assert title_part == "this-is-a-very-long-article-titl"
    assert len(title_part) <= 32


def test_unique_part_is_the_last_segment():
    assert get_slug_unique_part("hello-world-123456") == "123456"
