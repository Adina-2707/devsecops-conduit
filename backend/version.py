import os

__status__ = True
__version__ = "0.3.1"
__message__ = "Conduit Realworld API"
__revision__ = os.getenv("APP_REVISION", "unknown")

response = {"success": __status__, "version": __version__, "message": __message__, "revision": __revision__}
