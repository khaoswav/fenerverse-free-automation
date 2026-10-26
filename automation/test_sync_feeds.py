import importlib.util, unittest
from pathlib import Path

MOD_PATH = Path(__file__).with_name("sync_feeds.py")
spec = importlib.util.spec_from_file_location("sync_feeds", MOD_PATH)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

class FeedParserTests(unittest.TestCase):
    def test_html_is_cleaned_and_text_is_limited(self):
        self.assertEqual(sync.clean_text("<p>Fenerbahçe <b>kazandı</b></p> &amp; kutlama"), "Fenerbahçe kazandı & kutlama")

    def test_fener_feed_parses_and_classifies(self):
        xml = """<?xml version=\"1.0\"?><rss><channel><item><title>Fenerbahce basketbol takimi</title><description><![CDATA[<p>Yeni gelişme</p>]]></description><link>https://example.org/story</link><pubDate>Tue, 27 Oct 2026 00:00:00 GMT</pubDate></item></channel></rss>""".encode("utf-8")
        feed = {"name":"test", "default_sport":"genel", "must_mention_fenerbahce":False}
        rows = sync.parse_feed(xml, feed, 100)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["sport_slug"], "basketbol")
        self.assertEqual(rows[0]["canonical_url"], "https://example.org/story")

    def test_non_fener_article_is_filtered_from_general_feed(self):
        xml = """<rss><channel><item><title>Voleybol gündemi</title><description>Lig haberi</description><link>https://example.org/a</link></item></channel></rss>""".encode("utf-8")
        feed = {"name":"test", "default_sport":"voleybol", "must_mention_fenerbahce":True}
        self.assertEqual(sync.parse_feed(xml, feed), [])

if __name__ == "__main__": unittest.main()
