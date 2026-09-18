from playwright.sync_api import Page, expect


def test_user_can_publish_an_article(page: Page, web_url: str, unique_name: str):
    title = f"Browser article {unique_name}"
    page.goto(f"{web_url}/register")
    page.get_by_placeholder("Username").fill(unique_name)
    page.get_by_placeholder("Email").fill(f"{unique_name}@example.com")
    page.get_by_placeholder("Password").fill("safe-password-123")
    page.get_by_role("button", name="Sign up").click()

    page.get_by_role("link", name="New Article").click()
    page.get_by_placeholder("Article Title").fill(title)
    page.get_by_placeholder("What's this article about?").fill("Browser test")
    page.get_by_placeholder("Write your article (in markdown)").fill("Published by Playwright.")
    page.get_by_role("button", name="Publish Article").click()

    expect(page.get_by_role("heading", name=title)).to_be_visible()
